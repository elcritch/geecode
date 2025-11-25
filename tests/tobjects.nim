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

