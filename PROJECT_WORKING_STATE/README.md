# PROJECT_WORKING_STATE

This directory preserves the complete working state of each database implementation so that any future GPT/Kilo/Antigravity session can recover context without relying on chat history.

## Directory Layout

```
PROJECT_WORKING_STATE/
    README.md
    mysql/
        windows/
            README.md
            CURRENT_STATE.md
            ARCHITECTURE.md
            HANDOFFS/
            ERRORS/
            TESTS/
            DECISIONS/
    mssql/
        windows/
    mongodb/
        windows/
    postgresql/
        windows/
```

## Git Policy

`PROJECT_WORKING_STATE` should normally be committed to the corresponding development branch so context survives restarts, context loss, and handoffs.

Never store passwords, tokens, credentials, private keys, or sensitive connection strings in these files.
