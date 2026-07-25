# PROJECT_WORKING_STATE

This directory preserves the complete working state of every database implementation so that any future GPT/Kilo/Antigravity session can recover context without relying on chat history.

## Purpose

- Record what we were trying to do
- Capture what is already proven
- Document failures and root causes
- Track changes, commits, and tests
- Provide exact next actions

## Architecture

Each database gets its own isolated subtree under `PROJECT_WORKING_STATE/<database>/<os>/`. This prevents add/add conflicts when multiple databases are developed in parallel and merged into a shared integration branch.

```
PROJECT_WORKING_STATE/
    README.md               # This file: overall architecture and session protocol
    INDEX.md                # Master index of all database working-state locations

    mssql/
        windows/
            CURRENT_STATE.md
            ARCHITECTURE.md
            README.md
            HANDOFFS/
            ERRORS/
            TESTS/
            DECISIONS/

    mongodb/
        windows/
            CURRENT_STATE.md
            ARCHITECTURE.md
            README.md
            HANDOFFS/
            ERRORS/
            TESTS/
            DECISIONS/

    mysql/
        windows/
            ...
        ubuntu/
            ...

    postgresql/
        windows/
            ...
        ubuntu/
            ...
```

## Session Start Protocol

Every session must begin by reading, in order:

1. `PROJECT_WORKING_STATE/README.md`
2. `PROJECT_WORKING_STATE/INDEX.md`
3. The relevant database/OS subtree: `<database>/<os>/CURRENT_STATE.md`
4. Latest file in `<database>/<os>/HANDOFFS/`
5. Any `ERRORS/`, `TESTS/`, or `DECISIONS/` files referenced by `CURRENT_STATE.md`
6. `git status`
7. `git branch --show-current`
8. `git rev-parse HEAD`
9. Verify upstream with `git rev-parse --abbrev-ref --symbolic-full-name @{u}`

Only after these checks may development continue.

## Session End Protocol

At the end of every meaningful task/session within a specific database/OS context:

1. Update `<database>/<os>/CURRENT_STATE.md` with current truth.
2. Create exactly one new numbered `<database>/<os>/HANDOFFS/NNNNNN_YYYY-MM-DD_HHMM_short-description.md` snapshot.
3. If a new meaningful error was investigated, create `ERRORS/ERROR-NNNNNN_...md`.
4. If meaningful testing occurred, create `TESTS/TEST-NNNNNN_...md`.
5. If an architectural decision was made, create `DECISIONS/DECISION-NNNNNN_...md`.

## Naming Conventions

- Handoff files: `NNNNNN_YYYY-MM-DD_HHMM_short-description.md`
- Error files: `ERROR-NNNNNN_YYYY-MM-DD_HHMM_short-description.md`
- Test files: `TEST-NNNNNN_YYYY-MM-DD_HHMM_short-description.md`
- Decision files: `DECISION-NNNNNN_YYYY-MM-DD_HHMM_short-description.md`

Rules:
- Six-digit monotonically increasing sequence within each database/OS subtree
- Local date/time in 24-hour format
- Concise task description (kebab-case)
- Never overwrite old entries
- Never renumber historical entries
- Next session uses max existing sequence + 1 within the same subtree

## Git Policy

`PROJECT_WORKING_STATE` should normally be committed to the corresponding development branch so context survives restarts, context loss, and handoffs.

Never store passwords, tokens, credentials, private keys, or sensitive connection strings in these files.
