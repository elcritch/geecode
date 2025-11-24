import cligen
import os
import strformat
import strutils

const
  agentName = "Geecode Nim Agent"
  agentPurpose = "Lightweight CLI for summarizing the agent contract and sketching task plans."
  docPath = "AGENTS.md"

let capabilities = @[
  "Summarize the agent contract recorded in AGENTS.md",
  "Draft a lightweight execution plan for a provided task",
  "Stream the bundled AGENTS.md content for quick reference"
]

proc describe() =
  echo fmt"{agentName}: {agentPurpose}"
  echo "Capabilities:"
  for cap in capabilities:
    echo "- " & cap

proc plan(task: string; steps: int = 4) =
  let cleanTask = task.strip()
  if cleanTask.len == 0:
    echo "Provide a task description to plan against."
    return

  echo fmt"""Plan for "{cleanTask}":"""
  let skeleton = [
    fmt"""Clarify constraints and the success criteria for "{cleanTask}".""",
    "Inspect available context and pick the minimal inputs.",
    "Design and implement the smallest useful slice in src/geecode.nim.",
    "Verify the behavior, then capture decisions in AGENTS.md."
  ]

  for idx, step in skeleton:
    if idx >= steps:
      break
    echo fmt"{idx + 1}. {step}"

proc doc() =
  if fileExists(docPath):
    stdout.write(readFile(docPath))
  else:
    echo fmt"{docPath} not found; ensure it lives next to the binary."

when isMainModule:
  dispatchMulti(
    [describe],
    [plan],
    [doc]
  )
