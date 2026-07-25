# MSSQL Windows

This subtree preserves the complete working state of the MSSQL Windows implementation.

## Contents

- `CURRENT_STATE.md` — Current truth: branch, head, implementation state, known gaps, next actions
- `ARCHITECTURE.md` — Reference architecture adapted from PostgreSQL Windows
- `HANDOFFS/` — Numbered handoff snapshots
- `ERRORS/` — Error investigations
- `TESTS/` — Test results
- `DECISIONS/` — Architectural decisions

## Session Protocol

1. Read `CURRENT_STATE.md`
2. Read the latest `HANDOFFS/` entry
3. Check `git status`, `git branch --show-current`, `git rev-parse HEAD`
