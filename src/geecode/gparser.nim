
import std/[parseutils, sequtils, strformat, strutils]

type
  AddressKind* = enum
    akInteger, akDouble

  Address* = object
    case kind*: AddressKind
    of akInteger:
      id*: int
    of akDouble:
      floatVal*: float

  ChunkKind* = enum
    ckComment, ckCommand, ckWordAddress, ckPercent, ckWord

  Chunk* = object
    case kind*: ChunkKind
    of ckComment:
      leftDelim*: char
      rightDelim*: char
      commentText*: string
    of ckCommand:
      commandWord*: char
      id*: int
    of ckWordAddress:
      word*: char
      address*: float
    of ckPercent:
      discard
    of ckWord:
      singleWord*: char

  Block* = object
    hasLineNo*: bool
    lineNo*: int
    slashedOut*: bool
    chunks*: seq[Chunk]
    debugText*: string

  GCodeProgram* = object
    blocks*: seq[Block]

const
  doubleWords = {'X', 'Y', 'Z', 'A', 'B', 'C', 'U', 'V', 'W', 'I', 'J', 'K', 'F', 'R', 'Q',
                 'S', 'x', 'y', 'z', 'a', 'b', 'c', 'u', 'v', 'w', 'i', 'j', 'k', 'f', 'r',
                 's', 'q', 'E'}
  intWords = {'G', 'H', 'M', 'N', 'O', 'T', 'P', 'D', 'L', 'g', 'h', 'm', 'n', 'o', 't',
              'p', 'd', 'l'}

proc isNumChar(c: char): bool =
  c.isDigit or c == '.' or c == '-'

proc formatDouble(val: float): string =
  let id = int(val)
  if float(id) == val:
    return $id

  var repr = $val
  if repr.contains('.'):
    while repr.len > 0 and repr[repr.high] == '0':
      repr.setLen(repr.len - 1)
    if repr.len > 0 and repr[repr.high] == '.':
      repr.setLen(repr.len - 1)

  repr

proc `==`*(a, b: Address): bool =
  if a.kind != b.kind:
    return false
  case a.kind
  of akInteger:
    result = a.id == b.id
  of akDouble:
    result = a.floatVal == b.floatVal

proc `==`*(a, b: Chunk): bool =
  if a.kind != b.kind:
    return false
  case a.kind
  of ckComment:
    result = a.leftDelim == b.leftDelim and a.rightDelim == b.rightDelim and a.commentText == b.commentText
  of ckCommand:
    result = a.commandWord == b.commandWord and a.id == b.id
  of ckWordAddress:
    result = a.word == b.word and a.address == b.address
  of ckPercent:
    result = true
  of ckWord:
    result = a.singleWord == b.singleWord

proc `$`*(a: Address): string =
  case a.kind
  of akInteger:
    result = $a.id
  of akDouble:
    result = formatDouble(a.floatVal)

proc `$`*(c: Chunk): string =
  case c.kind
  of ckComment:
    result = $c.leftDelim & c.commentText & $c.rightDelim
  of ckCommand:
    result = $c.commandWord & $c.id
  of ckWordAddress:
    result = $c.word & c.address.formatDouble()
  of ckPercent:
    result = "%"
  of ckWord:
    result = $c.singleWord

proc `$`*(b: Block): string =
  var parts = newSeq[string]()
  if b.hasLineNo:
    parts.add("N" & $b.lineNo)
  for ch in b.chunks:
    parts.add($ch)
  if parts.len == 0:
    return ""
  result = parts.join(" ") & " "

proc `$`*(p: GCodeProgram): string =
  p.blocks.mapIt($it).join("\n")

proc chunkAt*(b: Block, idx: int): Chunk = b.chunks[idx]
proc size*(b: Block): int = b.chunks.len
proc isDeleted*(b: Block): bool = b.slashedOut
proc hasLineNumber*(b: Block): bool = b.hasLineNo
proc lineNumber*(b: Block): int =
  if not b.hasLineNo:
    raise newException(ValueError, "Block has no line number")
  b.lineNo

proc parseIntToken(token: string): int =
  var value: int
  let parsed = parseInt(token, value, 0)
  if parsed == 0:
    raise newException(ValueError, fmt"Invalid integer token '{token}'")
  value

proc parseFloatToken(token: string): float =
  var value: float
  let parsed = parseFloat(token, value, 0)
  if parsed == 0:
    raise newException(ValueError, fmt"Invalid float token '{token}'")
  value

proc parseAddress(word: char, tokens: seq[string], idx: var int): Address =
  if idx >= tokens.len:
    raise newException(ValueError, fmt"Missing address for word '{word}'")

  let token = tokens[idx]
  if word in doubleWords:
    result = Address(kind: akDouble, floatVal: parseFloatToken(token))
  elif word in intWords:
    result = Address(kind: akInteger, id: parseIntToken(token))
  else:
    raise newException(ValueError, fmt"Unsupported word '{word}'")
  inc idx

proc parseLineComment(tokens: seq[string], idx: var int): string =
  result = ""
  while idx < tokens.len:
    result.add tokens[idx]
    inc idx

proc parseChunk(tokens: seq[string], idx: var int): Chunk =
  let token = tokens[idx]
  inc idx

  if token.len > 0 and token[0] == '[':
    let text = token[1 ..< token.len - 1]
    return Chunk(kind: ckComment, leftDelim: '[', rightDelim: ']', commentText: text)
  elif token.len > 0 and token[0] == '(':
    let text = token[1 ..< token.len - 1]
    return Chunk(kind: ckComment, leftDelim: '(', rightDelim: ')', commentText: text)
  elif token == "%":
    return Chunk(kind: ckPercent)
  elif token == ";":
    let text = parseLineComment(tokens, idx)
    return Chunk(kind: ckComment, leftDelim: ';', rightDelim: ';', commentText: text)
  else:
    let nextToken = if idx < tokens.len: tokens[idx] else: ""
    if nextToken.len == 0 or not isNumChar(nextToken[0]):
      return Chunk(kind: ckWord, singleWord: token[0])
    let address = parseAddress(token[0], tokens, idx)
    case address.kind:
    of akInteger:
      return Chunk(kind: ckCommand, commandWord: token[0], id: address.id)
    of akDouble:
      return Chunk(kind: ckWordAddress, word: token[0], address: address.floatVal)

proc parseTokens(tokens: seq[string]): Block =
  if tokens.len == 0:
    return Block(hasLineNo: false, lineNo: -1, slashedOut: false, chunks: @[], debugText: "")

  var idx = 0
  var slashed = false
  if tokens[idx] == "/":
    slashed = true
    inc idx

  var hasLineNo = false
  var lineNo = -1
  if idx < tokens.len and tokens[idx] == "N":
    hasLineNo = true
    inc idx
    lineNo = parseIntToken(tokens[idx])
    inc idx

  var chunkList: seq[Chunk] = @[]
  while idx < tokens.len:
    chunkList.add parseChunk(tokens, idx)

  Block(hasLineNo: hasLineNo, lineNo: lineNo, slashedOut: slashed, chunks: chunkList, debugText: "")

proc parseCommentWithDelims(sc, ec: char, text: string, idx: var int): string =
  var depth = 0
  while idx < text.len:
    let c = text[idx]
    if c == sc:
      inc depth
    elif c == ec:
      dec depth
    result.add c
    inc idx
    if depth == 0:
      break

proc digitString(text: string, idx: var int): string =
  let start = idx
  while idx < text.len and isNumChar(text[idx]):
    inc idx
  text[start ..< idx]

proc lexToken(blockText: string, idx: var int): string =
  let c = blockText[idx]
  if isNumChar(c):
    return digitString(blockText, idx)

  case c
  of '(':
    return parseCommentWithDelims('(', ')', blockText, idx)
  of '[':
    return parseCommentWithDelims('[', ']', blockText, idx)
  of ')', ']':
    raise newException(ValueError, fmt"Unexpected closing delimiter '{c}'")
  else:
    inc idx
    return $c

proc ignoreWhitespace(text: string, idx: var int) =
  while idx < text.len and (text[idx].isSpaceAscii or text[idx] == '\r'):
    inc idx

proc lexBlock*(blockText: string): seq[string] =
  var idx = 0
  result = @[]

  ignoreWhitespace(blockText, idx)
  while idx < blockText.len:
    ignoreWhitespace(blockText, idx)
    if idx < blockText.len:
      result.add lexToken(blockText, idx)

proc parseGcode*(programText: string): GCodeProgram =
  var blocks: seq[Block] = @[]
  var lineStart = 0

  while lineStart < programText.len:
    var lineEnd = programText.find('\n', lineStart)
    if lineEnd == -1:
      lineEnd = programText.len

    let line = programText[lineStart ..< lineEnd]
    if line.len > 0:
      let tokens = lexBlock(line)
      blocks.add parseTokens(tokens)

    lineStart = lineEnd + 1

  GCodeProgram(blocks: blocks)

proc setDebugText*(b: var Block; text: string) =
  b.debugText = text

proc setDebugText*(b: var Block) =
  b.setDebugText($b)

proc parseGcodeSavingBlockText*(programText: string): GCodeProgram =
  var program = parseGcode(programText)
  for i in 0 ..< program.blocks.len:
    program.blocks[i].setDebugText()
  program

proc numBlocks*(p: GCodeProgram): int = p.blocks.len
proc getBlock*(p: GCodeProgram, idx: int): Block = p.blocks[idx]
