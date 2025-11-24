import std/unittest

import geecode

suite "gpr parser":
  test "one line program":
    let p = parseGcode("G0 X1.0 Y1.0")
    echo "P: ", p
    check p.numBlocks == 1
    check p.getBlock(0).size == 3

  test "two lines with delete and line numbers":
    let p = parseGcode("(*** Toolpath 1 ***)\n/M23 [ And so is this ]\nN103 G1 X1.0 F23.0")
    echo "P: ", p
    check p.numBlocks == 3
    check p.getBlock(1).isDeleted
    check p.getBlock(2).hasLineNumber
    check p.getBlock(2).lineNumber == 103

  test "semicolon comments become comment chunks":
    let p = parseGcode(";Generated with Cura\nG28 ;Home")
    check p.getBlock(0).chunks[0].kind == ckComment
    check p.getBlock(1).chunks[1].kind == ckComment
    check p.getBlock(1).chunks[1].commentText == "Home"

  test "isolated words and percent chunks":
    let p = parseGcode("G99 G82 R0.1 Z-0.1227 P F15.04")
    check p.getBlock(0).chunks[4].kind == ckWord
    let percentProg = parseGcode("%")
    check percentProg.getBlock(0).chunks[0].kind == ckPercent

  test "saving debug text uses printable form":
    let p = parseGcodeSavingBlockText("G0 X1.5 Y0.0 Z0.0")
    check p.getBlock(0).debugText.len > 0
