# INDEX

This file tracks every database working-state location in `PROJECT_WORKING_STATE`. Each entry points to the canonical `CURRENT_STATE.md` for that implementation.

| Database | OS | CURRENT_STATE.md | Status |
|---|---|---|---|
| MSSQL | windows | `PROJECT_WORKING_STATE/mssql/windows/CURRENT_STATE.md` | Active |
| MongoDB | windows | `PROJECT_WORKING_STATE/mongodb/windows/CURRENT_STATE.md` | Active |
| MySQL | windows | `PROJECT_WORKING_STATE/mysql/windows/CURRENT_STATE.md` | Planned |
| MySQL | ubuntu | `PROJECT_WORKING_STATE/mysql/ubuntu/CURRENT_STATE.md` | Planned |
| PostgreSQL | windows | `PROJECT_WORKING_STATE/postgresql/windows/CURRENT_STATE.md` | Planned |
| PostgreSQL | ubuntu | `PROJECT_WORKING_STATE/postgresql/ubuntu/CURRENT_STATE.md` | Planned |

## Adding a New Database

1. Create the subtree: `PROJECT_WORKING_STATE/<database>/<os>/`
2. Copy `README.md` from an existing subtree and customize for the database
3. Add the first `CURRENT_STATE.md`
4. Add the first numbered `HANDOFFS/` entry
5. Update this `INDEX.md` with the new row
