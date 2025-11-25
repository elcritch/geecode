import std/[os, unittest]

import geecode

suite "geecode builder":
  test "one line program":
    let p = paths:
      MoveTo(X: 1.0, Y: 1.0)
      LinearTo(X: 5.0, Y: 12.0, feedRate: 200.0)
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
                   "G1 X5 Y12 F200\n" &
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

  test "linear alias renders like line to":
    let linear = LinearTo(X: 2.0, Y: 3.0, Z: 4.0, feedRate: 150.0)
    check toGcode(linear) == "G1 X2 Y3 Z4 F150"

  test "round trip builder output through parser":
    let commands = paths:
      MoveTo(X: 1.0, Y: 2.0, Z: 3.0, feedRate: 150.0)

    let rendered = toGcode(commands)

    let parsed = parseGcode(rendered)
    check parsed.numBlocks == 1
    check parsed.getBlock(0).size == 5
    check parsed.getBlock(0).chunkAt(3).word == 'Z'
    check parsed.getBlock(0).chunkAt(4).word == 'F'
