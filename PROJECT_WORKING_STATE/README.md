# PROJECT_WORKING_STATE

This directory preserves the complete working state of the MySQL Windows implementation so that any future GPT/Kilo/Antigravity session can recover context without relying on chat history.

## Purpose

- Record what we were trying to do
- Capture what is already proven
- Document failures and root causes
- Track changes, commits, and tests
- Provide exact next actions

## Directory Layout

```
PROJECT_WORKING_STATE/
    README.md
    CURRENT_STATE.md
    ARCHITECTURE.md
    HANDOFFS/
        NNNNNN_YYYY-MM-DD_HHMM_short-description.md
    ERRORS/
        ERROR-NNNNNN_YYYY-MM-DD_HHMM_short-description.md
    TESTS/
        TEST-NNNNNN_YYYY-MM-DD_HHMM_short-description.md
    DECISIONS/
        DECISION-NNNNNN_YYYY-MM-DD_HHMM_short-description.md
```

## Session Start Protocol

Every session must begin by reading, in order:

1. `README.md`
2. `CURRENT_STATE.md`
3. Latest file in `HANDOFFS/`
4. Any `ERRORS/`, `TESTS/`, or `DECISIONS/` files referenced by `CURRENT_STATE.md`
5. `git status`
6. `git branch --show-current`
7. `git rev-parse HEAD`
8. Verify upstream with `git rev-parse --abbrev-ref --symbolic-full-name @{u}`

Only after these checks may development continue.

## Session End Protocol

At the end of every meaningful task/session:

1. Update `CURRENT_STATE.md` with current truth.
2. Create exactly one new numbered `HANDOFFS/NNNNNN_YYYY-MM-DD_HHMM_short-description.md` snapshot.
3. If a new meaningful error was investigated, create `ERRORS/ERROR-NNNNNN_...md`.
4. If meaningful testing occurred, create `TESTS/TEST-NNNNNN_...md`.
5. If an architectural decision was made, create `DECISIONS/DECISION-NNNNNN_...md`.

## Naming Conventions

- Handoff files: `NNNNNN_YYYY-MM-DD_HHMM_short-description.md`
- Error files: `ERROR-NNNNNN_YYYY-MM-DD_HHMM_short-description.md`
- Test files: `TEST-NNNNNN_YYYY-MM-DD_HHMM_short-description.md`
- Decision files: `DECISION-NNNNNN_YYYY-MM-DD_HHMM_short-description.md`

Rules:
- Six-digit monotonically increasing sequence
- Local date/time in 24-hour format
- Concise task description (kebab-case)
- Never overwrite old entries
- Never renumber historical entries
- Next session uses max existing sequence + 1

## Git Policy

`PROJECT_WORKING_STATE` should normally be committed to the corresponding development branch so context survives restarts, context loss, and handoffs.

Never store passwords, tokens, credentials, private keys, or sensitive connection strings in these files.
