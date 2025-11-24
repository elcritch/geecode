# Geecode Nim Agent

This repository ships a small Nim-based agent CLI. It keeps the agent contract in this document, exposes it through a CLI, and relies on `atlas` (not `nimble`) to manage dependencies.

## Components
- `src/geecode.nim`: CLI entrypoint exposing the agent behaviors.
- `geecode.nimble`: Project metadata and dependency list consumed by `atlas install`.
- `AGENTS.md`: Contract and usage guide read by the `doc` command.

## Responsibilities
- Summarize the agent contract for quick reference (`describe`).
- Draft a lightweight execution plan for a provided task (`plan`).
- Stream this document for downstream tools (`doc`).

## Using the Agent
1. Install dependencies with Atlas (no Nimble):
   - `atlas install`
2. Run tests with `nim test`

## Notes
- Dependencies are pinned via `geecode.nimble` and installed with `atlas`; avoid invoking `nimble` directly.
- Update dependency versions in `geecode.nimble` and rerun `atlas install` to refresh the checkout.
- The CLI focuses on clarity over automation; extend `src/geecode.nim` with new commands as needed.
