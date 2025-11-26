import std/[macros, math, strutils]

type
  GCode* = ref object of RootObj

  Settings* = ref object of GCode

  Command* = ref object of GCode
  XYCommand* = ref object of GCode
    X*: float = NaN
    Y*: float = NaN
    Z*: float = NaN
    E*: float = NaN
    feedRate*: float = NaN

  FastGoto* = ref object of XYCommand
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
  Dwell* = ref object of Command
    milliseconds*: float = NaN
    seconds*: float = NaN

  SetPosition* = ref object of XYCommand

  FeedRate* = ref object of Command
    rate*: float = NaN

  SpindleSpeed* = ref object of Command
    rpm*: float = NaN

  SelectTool* = ref object of Command
    toolNumber*: int

  ToolChange* = ref object of Command
    toolNumber*: int = -1

  ProgramStop* = ref object of Command
  OptionalStop* = ref object of Command
  ProgramEnd* = ref object of Command
  ProgramEndReset* = ref object of Command

  SpindleOnClockwise* = ref object of Command
  SpindleOnCounterclockwise* = ref object of Command
  SpindleOff* = ref object of Command

  CoolantMistOn* = ref object of Command
  CoolantFloodOn* = ref object of Command
  CoolantOff* = ref object of Command

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
  addWord(parts, 'E', motion.E)
  addWord(parts, 'F', motion.feedRate)

method toGcode*(cmd: GCode): string {.base.} =
    raise newException(ValueError, "Unsupported GCode command")

method toGcode*(cmd: FastGoto): string =
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
method toGcode*(cmd: Dwell): string =
    result.add "G4"
    result.addWord('P', cmd.milliseconds)
    result.addWord('S', cmd.seconds)
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
method toGcode*(cmd: SetPosition): string =
    result.add "G92"
    result.addMovement(cmd)
method toGcode*(cmd: AbsoluteMode): string =
    result.add "G90"
method toGcode*(cmd: RelativeMode): string =
    result.add "G91"
method toGcode*(cmd: FeedRate): string =
    if cmd.rate.isNaN:
        raise newException(ValueError, "Feed rate is required")
    result.add "F"
    result.add(formatFloat(cmd.rate))
method toGcode*(cmd: SpindleSpeed): string =
    if cmd.rpm.isNaN:
        raise newException(ValueError, "Spindle speed is required")
    result.add "S"
    result.add(formatFloat(cmd.rpm))
method toGcode*(cmd: SelectTool): string =
    result.add "T"
    result.add($cmd.toolNumber)
method toGcode*(cmd: ToolChange): string =
    result.add "M6"
    if cmd.toolNumber >= 0:
        result.add " T"
        result.add($cmd.toolNumber)
method toGcode*(cmd: ProgramStop): string =
    result.add "M0"
method toGcode*(cmd: OptionalStop): string =
    result.add "M1"
method toGcode*(cmd: ProgramEnd): string =
    result.add "M2"
method toGcode*(cmd: ProgramEndReset): string =
    result.add "M30"
method toGcode*(cmd: SpindleOnClockwise): string =
    result.add "M3"
method toGcode*(cmd: SpindleOnCounterclockwise): string =
    result.add "M4"
method toGcode*(cmd: SpindleOff): string =
    result.add "M5"
method toGcode*(cmd: CoolantMistOn): string =
    result.add "M7"
method toGcode*(cmd: CoolantFloodOn): string =
    result.add "M8"
method toGcode*(cmd: CoolantOff): string =
    result.add "M9"

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
