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

proc addWord(parts: var string, prefix: char, value: float) =
  if not value.isNaN:
    parts.add(" ")
    parts.add($prefix)
    parts.add(formatFloat(value))

proc addMovement(parts: var string, motion: XYCommand) =
  addWord(parts, 'X', motion.X)
  addWord(parts, 'Y', motion.Y)
  addWord(parts, 'Z', motion.Z)
  addWord(parts, 'F', motion.feedRate)

method toGcode*(cmd: GCode): string {.base.} =
    raise newException(ValueError, "Unsupported GCode command")

method toGcode*(cmd: MoveTo): string =
    result.add "G0"
    result.addMovement(cmd)
method toGcode*(cmd: LineTo): string =
    result.add "G1"
    result.addMovement(cmd)
method toGcode*(arc: CwArcTo): string =
    result.add "G2"
    result.addMovement(arc)
    result.addWord('I', arc.centerX)
    result.addWord('J', arc.centerJ)
method toGcode*(arc: CcwArcTo): string =
    result.add "G3"
    result.addMovement(arc)
    result.addWord('I', arc.centerX)
    result.addWord('J', arc.centerJ)
method toGcode*(cmd: UnitsInches): string =
    result.add "G20"
method toGcode*(cmd: UnitsMillimeters): string =
    result.add "G21"
method toGcode*(cmd: PlaneXY): string =
    result.add "G17"
method toGcode*(cmd: PlaneXZ): string =
    result.add "G18"
method toGcode*(cmd: PlaneYZ): string =
    result.add "G19"
method toGcode*(cmd: GotoHome): string =
    result.add "G28"
method toGcode*(cmd: AbsoluteMode): string =
    result.add "G90"
method toGcode*(cmd: RelativeMode): string =
    result.add "G91"

proc toGcode*(commands: openArray[GCode]): string =
  var lines: seq[string] = @[]
  for cmd in commands:
    lines.add(cmd.toGcode())
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
