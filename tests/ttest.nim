import std/[os, unittest]

import geecode

proc samplePath(name: string): string =
  parentDir(getAppDir()) / "tests/gcode_samples" / name

suite "geecode parser":
  test "one line program":
    let p = parseGcode("G0 X1.0 Y1.0")
    check p.numBlocks == 1
    check p.getBlock(0).size == 3

  test "two line program":
    let p = parseGcode("G0 X1.0 Y1.0\nG1 X0.0 Y0.0 Z1.2 F12.0")
    check p.numBlocks == 2

  test "correct first token comparisons":
    let p = parseGcode("G0 X1.0 Y1.0\nG1 X0.0 Y0.0 Z1.2 F12.0")

    let g1 = Chunk(kind: ckCommand, commandWord: 'G', id: 1)
    check p.getBlock(1).chunkAt(0) == g1
    check p.getBlock(0).chunkAt(0) != g1

    let f12 = Chunk(kind: ckWordAddress, word: 'F', address: 12.0)
    check p.getBlock(1).chunkAt(4) == f12
    check p.getBlock(1).chunkAt(3) != f12

  test "two lines with delete and line numbers":
    let p = parseGcode("(*** Toolpath 1 ***)\n/M23 [ And so is this ]\nN103 G1 X1.0 F23.0")
    check p.numBlocks == 3
    check p.getBlock(1).isDeleted
    check not p.getBlock(0).isDeleted
    check p.getBlock(2).hasLineNumber
    check p.getBlock(2).lineNumber == 103

  test "3rd block is labeled line 103":
    let p = parseGcode("(*** Toolpath 1 ***)\n G0 X0.0 Y0.0 Z0.0 \n N103 G1 X1.0 F23.0\nG1 Z-1.0 F10.0")
    check p.getBlock(2).hasLineNumber
    check p.getBlock(2).lineNumber == 103
    check not p.getBlock(3).hasLineNumber

  test "semicolon comments become comment chunks":
    let p = parseGcode(";Generated with Cura\nM190 S60\nM104 S200\nM109 S200\nG28 ;Home")
    check p.getBlock(0).chunks[0].kind == ckComment
    check p.getBlock(4).chunks[1].kind == ckComment
    check p.getBlock(4).chunks[1].commentText == "Home"

  test "different comments with same delimiters are not equal":
    let p = parseGcode("( This is a comment )\n M23 ( And so is this ) G54")
    check p.getBlock(0).chunkAt(0) != p.getBlock(1).chunkAt(1)

  test "same comments with same delimiters are equal":
    let p = parseGcode("( This is a comment G2 )\n M23 ( This is a comment G2 ) G54")
    check p.getBlock(0).chunkAt(0) == p.getBlock(1).chunkAt(1)

  test "same comments with different delimiters are not equal":
    let p = parseGcode("( This is a comment G2 )\n M23 [ This is a comment G2 ] G54")
    check p.getBlock(0).chunkAt(0) != p.getBlock(1).chunkAt(1)

  test "parse 3D printer E-block":
    let p = parseGcode(";Prime the extruder\nG92 E0")
    check p.numBlocks == 2

  test "isolated words and percent chunks":
    let p = parseGcode("G99 G82 R0.1 Z-0.1227 P F15.04")
    check p.getBlock(0).chunks[4].kind == ckWord
    let percentProg = parseGcode("%")
    check percentProg.getBlock(0).chunks[0].kind == ckPercent

  test "percent chunk equality with saved debug text":
    let p = parseGcodeSavingBlockText("%")
    let percentChunk = Chunk(kind: ckPercent)
    check p.getBlock(0).chunkAt(0) == percentChunk

  test "lex block with isolated P word":
    let program = "/%G99 G82 R0.1 Z-0.1227 P F15.04"
    let lexedLine = lexBlock(program)
    check lexedLine.len == 13

  test "saving debug text uses printable form":
    let p = parseGcodeSavingBlockText("(*** Toolpath 2 ***)\n G0 X1.5 Y0.0 Z0.0 \n N103 G1 X1.0 F23.0\nG1 Z-1.0 F10.0")
    check p.numBlocks == 4
    check p.getBlock(0).debugText == "(*** Toolpath 2 ***) "
    check p.getBlock(1).debugText == "G0 X1.5 Y0 Z0 "

  test "parse blank line":
    let p = parseGcode("G99 G82 R0.1 Z-0.1227 P F15.04\n   ")
    check p.numBlocks == 2

  test "parse CAMASTER style feedrate controls":
    let p = parseGcode("F10 XY [SET FEEDRATE FOR X AND Y]")
    check p.numBlocks == 1
    check p.getBlock(0).size == 4

  test "full sample parsing":
    let mazak = parseGcode(readFile(samplePath("mazak_sample.EIA")))
    check mazak.getBlock(28).size == 3

    let linux = parseGcode(readFile(samplePath("linuxcnc_sample.ngc")))
    check linux.getBlock(30341).size == 5

    let camaster = parseGcode(readFile(samplePath("camaster_sample.tap")))
    check camaster.getBlock(42).size == 4

    let haas = parseGcode(readFile(samplePath("HAAS_sample.NCF")))
    check haas.getBlock(42).size == 1

    let cura = parseGcode(readFile(samplePath("cura_3D_printer.gcode")))
    check cura.getBlock(233).chunks[2].word == 'Y'
    check cura.getBlock(1929).chunks[0].commentText == "TYPE:WALL-INNER"
