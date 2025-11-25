import std/[macros, math, strutils]

type
  GCode* = ref object of RootObj

  Settings* = ref object of GCode

  Command* = ref object of GCode
  XYCommand* = ref object of GCode
    X*: float = NaN
    Y*: float = NaN
    Z*: float = NaN
    feedRate*: float = NaN

  MoveTo* = ref object of XYCommand
  LineTo* = ref object of XYCommand
  LinearTo* = LineTo

  ArcCommand* = ref object of XYCommand
    centerX*: float = NaN
    centerJ*: float = NaN

  CwArcTo* = ref object of ArcCommand
  CcwArcTo* = ref object of ArcCommand

  UnitsInches* = ref object of Settings
  UnitsMillimeters* = ref object of Settings

  PlaneXY* = ref object of Settings
  PlaneXZ* = ref object of Settings
  PlaneYZ* = ref object of Settings

  AbsoluteMode* = ref object of Settings
  RelativeMode* = ref object of Settings

  GotoHome* = ref object of Command

proc formatFloat(value: float): string =
  let intVal = int(value)
  if float(intVal) == value:
    return $intVal

  var repr = $value
  if repr.contains('.'):
    while repr.len > 0 and repr[repr.high] == '0':
      repr.setLen(repr.len - 1)
    if repr.len > 0 and repr[repr.high] == '.':
      repr.setLen(repr.len - 1)
  repr

proc addWord(parts: var seq[string], prefix: char, value: float) =
  if not value.isNaN:
    parts.add($prefix & formatFloat(value))

proc addMovement(parts: var seq[string], motion: XYCommand) =
  addWord(parts, 'X', motion.X)
  addWord(parts, 'Y', motion.Y)
  addWord(parts, 'Z', motion.Z)
  addWord(parts, 'F', motion.feedRate)

proc toGcode*(cmd: GCode): string =
  var parts: seq[string] = @[]
  if cmd of MoveTo:
    parts.add "G0"
    addMovement(parts, MoveTo(cmd))
  elif cmd of LineTo:
    parts.add "G1"
    addMovement(parts, LineTo(cmd))
  elif cmd of CwArcTo:
    let arc = CwArcTo(cmd)
    parts.add "G2"
    addMovement(parts, arc)
    addWord(parts, 'I', arc.centerX)
    addWord(parts, 'J', arc.centerJ)
  elif cmd of CcwArcTo:
    let arc = CcwArcTo(cmd)
    parts.add "G3"
    addMovement(parts, arc)
    addWord(parts, 'I', arc.centerX)
    addWord(parts, 'J', arc.centerJ)
  elif cmd of UnitsInches:
    parts.add "G20"
  elif cmd of UnitsMillimeters:
    parts.add "G21"
  elif cmd of PlaneXY:
    parts.add "G17"
  elif cmd of PlaneXZ:
    parts.add "G18"
  elif cmd of PlaneYZ:
    parts.add "G19"
  elif cmd of GotoHome:
    parts.add "G28"
  elif cmd of AbsoluteMode:
    parts.add "G90"
  elif cmd of RelativeMode:
    parts.add "G91"
  else:
    raise newException(ValueError, "Unsupported GCode command")
  parts.join(" ")

proc toGcode*(commands: openArray[GCode]): string =
  var lines: seq[string] = @[]
  for cmd in commands:
    lines.add toGcode(cmd)
  lines.join("\n")

macro paths*(body: untyped): untyped =
  var stmts: seq[NimNode] = @[]
  if body.kind == nnkStmtList:
    for stmt in body:
      stmts.add stmt
  else:
    stmts.add body

  let programSym = genSym(nskVar, "program")
  result = newStmtList()
  result.add quote do:
    var `programSym`: seq[GCode] = @[]
  for stmt in stmts:
    result.add quote do:
      `programSym`.add `stmt`
  result.add quote do:
    `programSym`
