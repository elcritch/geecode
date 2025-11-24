# Geecode

## Overview
Geecode is a Nim library for parsing G-code programs into a structured representation. It tokenizes each line into chunks (word/address pairs, isolated words, percent markers, and comments), tracks deleted lines prefixed with `/`, preserves line numbers when present, and exposes helpers to compare chunks and blocks for equality. `parseGcode` returns a `GCodeProgram` with easy access to blocks and chunk counts, while `parseGcodeSavingBlockText` also stores printable debug text for each parsed line.

## Key Types and Procs
- `Address`, `Chunk`, `Block`, and `GCodeProgram` model G-code tokens, line metadata, and program structure.
- `lexBlock` tokenizes a raw line; `parseGcode` and `parseGcodeSavingBlockText` build full programs from source text.
- Convenience procs like `chunkAt`, `size`, `numBlocks`, and `getBlock` simplify inspection in tests and consumers.

## Programming
1. Install dependencies with Atlas only (`atlas install`). **Never** use Nimble for anything.
2. Run tests with `nim test`.
