# Geecode

Geecode is a Nim library for parsing G-code programs into a structured representation suited for CNC and 3D printing workflows. It tokenizes each line into words, addresses, percent markers, and comments while preserving metadata like deleted lines and line numbers.

## Features
- Parses G-code into `GCodeProgram`, `Block`, `Chunk`, and `Address` objects for inspection or transformation
- Supports word/address pairs, isolated words, percent markers, and multiple comment styles (`()`, `[]`, `;`)
- Tracks deleted lines prefixed with `/` and optional `N` line numbers without dropping later tokens
- Provides equality helpers for comparing addresses, chunks, and blocks in tests
- `parseGcodeSavingBlockText` also records printable debug text for each parsed line

## Installation
Use Atlas for dependency setup:

```sh
atlas install
```

**Never** use Nimble for this project.

## Usage
A minimal example showing parsing and inspection:

```nim
import geecode

let program = parseGcode("N10 G1 X1.0 Y2.0 ; move")
let block = program.getBlock(0)

echo program.numBlocks       # 1
echo block.chunkAt(0)        # G1
echo block.chunkAt(2)        # Y2.0

let withDebug = parseGcodeSavingBlockText("G0 X0 Y0")
echo withDebug.getBlock(0).debugText  # "G0 X0 Y0 "
```

## Tests
Run the test suite with:

```sh
nim test
```

## Attribution
Geecode is derived from [dillonhuff/gpr](https://github.com/dillonhuff/gpr) and continues under the same MIT license.

## License
MIT. See `LICENSE` for details.
