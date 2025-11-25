
import geecode/apis
import geecode/gparser

export gparser, apis

type
  GCode* = ref object of RootObj

  Settings* = ref object of GCode

  Command* = ref object of GCode
  XYCommand* = ref object of GCode
    X*: float
    Y*: float
    feedRate*: float = NaN

  MoveTo* = ref object of XYCommand
  LineTo* = ref object of XYCommand

  ArcCommand* = ref object of XYCommand
    centerX*: float
    centerY*: float

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

