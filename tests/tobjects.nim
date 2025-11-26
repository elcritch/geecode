import std/[os, unittest]

import geecode

suite "geecode builder":
  test "one line program":
    let p = paths:
      FastGoto(X: 1.0, Y: 1.0)
      LinearTo(X: 5.0, Y: 12.0, E: 0.5, feedRate: 200.0)
      CwArcTo(X: 10.0, Y: 7.0, centerX: 0, centerJ: -5, feedRate: 12.0)
      CcwArcTo(X: 10.0, Y: 7.0, centerX: 0, centerJ: -5, feedRate: 12.0)
      UnitsInches()
      UnitsMillimeters()
      PlaneXY()
      PlaneXZ()
      PlaneYZ()
      GotoHome()
      AbsoluteMode()
      RelativeMode()

    check p.len == 12

    let rendered = toGcode(p)
    let expected = "G0 X1 Y1\n" &
                   "G1 X5 Y12 E0.5 F200\n" &
                   "G2 X10 Y7 F12 I0 J-5\n" &
                   "G3 X10 Y7 F12 I0 J-5\n" &
                   "G20\n" &
                   "G21\n" &
                   "G17\n" &
                   "G18\n" &
                   "G19\n" &
                   "G28\n" &
                   "G90\n" &
                   "G91"
    check rendered == expected

  test "optional axes stay omitted":
    check toGcode(LineTo(X: 2.5)) == "G1 X2.5"
    check toGcode(LineTo(Z: -3.25)) == "G1 Z-3.25"
    check toGcode(LineTo(E: 3.0)) == "G1 E3"

  test "linear alias renders like line to":
    let linear = LinearTo(X: 2.0, Y: 3.0, Z: 4.0, feedRate: 150.0)
    check toGcode(linear) == "G1 X2 Y3 Z4 F150"

  test "common commands render to gcode strings":
    check toGcode(Dwell(milliseconds: 250)) == "G4 P250"
    check toGcode(SetPosition(X: 0.0, Y: 0.0, Z: 1.5, E: 2.25)) == "G92 X0 Y0 Z1.5 E2.25"
    check toGcode(FeedRate(rate: 1200)) == "F1200"
    check toGcode(SpindleSpeed(rpm: 9000)) == "S9000"
    check toGcode(SelectTool(toolNumber: 3)) == "T3"
    check toGcode(ToolChange(toolNumber: 4)) == "M6 T4"
    check toGcode(ToolChange()) == "M6"
    check toGcode(ProgramStop()) == "M0"
    check toGcode(OptionalStop()) == "M1"
    check toGcode(ProgramEnd()) == "M2"
    check toGcode(ProgramEndReset()) == "M30"
    check toGcode(SpindleOnClockwise()) == "M3"
    check toGcode(SpindleOnCounterclockwise()) == "M4"
    check toGcode(SpindleOff()) == "M5"
    check toGcode(CoolantMistOn()) == "M7"
    check toGcode(CoolantFloodOn()) == "M8"
    check toGcode(CoolantOff()) == "M9"
    expect ValueError:
      discard toGcode(FeedRate())
    expect ValueError:
      discard toGcode(SpindleSpeed())

  test "round trip builder output through parser":
    let commands = paths:
      FastGoto(X: 1.0, Y: 2.0, Z: 3.0, feedRate: 150.0)

    let rendered = toGcode(commands)

    let parsed = parseGcode(rendered)
    check parsed.numBlocks == 1
    check parsed.getBlock(0).size == 5
    check parsed.getBlock(0).chunkAt(3).word == 'Z'
    check parsed.getBlock(0).chunkAt(4).word == 'F'
