# Core Script Ownership Report

Generated from static repository analysis of:

- `scripts/data_loader.py`
- `scripts/data_loader_mongodb.py`
- `scripts/run_liquibase.py`

No source, pipeline, Terraform, Liquibase, or config files were modified.

## Static Reference Summary

Static scan pattern:

`data_loader.py`, `data_loader_mongodb.py`, `run_liquibase.py`, `data_loader`, `run_liquibase`

Result: no active in-repository caller was found outside generated refactor reports.

Important caveat: this does not prove the files are unused by external Jenkins job configuration, manually triggered jobs, scheduler definitions, or local operator runbooks. Treat delete decisions as conditional until external job inventory is checked.

## Ownership Decision Matrix

| File | Actively Referenced? | Pipelines That Call It | Databases Used | Can Become Common Utility? | Recommended Ownership | Delete Candidate? |
| --- | --- | --- | --- | --- | --- | --- |
| `scripts/data_loader.py` | No static repository reference found. | None found in Jenkins, Batch, Bash, PowerShell, or Terraform references. | Intended for MySQL, MSSQL, and PostgreSQL. No MongoDB support. | Partially. File parsing, history writing, path handling, and move/archive logic could become common. DB connection, SQL quoting, table introspection, DDL, and insert behavior are database-specific and should not remain in common as-is. | Do not move as-is to `common`. If retained, split into `scripts/python/common/` reusable file/history utilities plus database-owned loaders under `scripts/python/mysql/load/`, `scripts/python/mssql/load/`, and `scripts/python/postgresql/load/`. | Yes, conditional DELETE CANDIDATE if external Jenkins/job audit confirms no usage, because no static caller exists and database-owned loaders already exist. |
| `scripts/data_loader_mongodb.py` | No static repository reference found. | None found in Jenkins, Batch, Bash, PowerShell, or Terraform references. | MongoDB only. | Partially. CSV/JSON reading, history writing, and file movement can share common helpers. MongoDB connection, collection naming, and insert behavior must remain MongoDB-owned. | `scripts/python/mongodb/load/` if retained. Extract only generic file/history helpers to `scripts/python/common/`. | Yes, conditional DELETE CANDIDATE if external Jenkins/job audit confirms no usage and `scripts/python/mongodb/load_data.py` / `load_all.py` cover the active load path. |
| `scripts/run_liquibase.py` | No static repository reference found. | None found in Jenkins, Batch, Bash, PowerShell, or Terraform references. | Intended for MySQL, MSSQL, and PostgreSQL, but current execution path defaults to MySQL config and calls `execute_liquibase(..., 'mysql', ...)`. MongoDB should not use Liquibase. | Not as-is. A common Liquibase command wrapper could exist, but database URL construction, driver selection, changelog location, and credential mapping must be database-owned or config-driven. Current file hardcodes MySQL fallback behavior and MySQL driver assumptions. | If retained, split into database-owned setup runners under `scripts/python/mysql/setup/`, `scripts/python/mssql/setup/`, and `scripts/python/postgresql/setup/`, with a small common command-execution helper only if truly reusable. | Yes, conditional DELETE CANDIDATE if external Jenkins/job audit confirms no usage, because active pipelines appear to use database-owned Batch/Bash Liquibase runners instead. |

## File-Level Findings

### `scripts/data_loader.py`

Current behavior:

- Generic relational loader for CSV/JSON files under `incoming/{db_type}`.
- Supports `mysql`, `postgresql`, and `mssql` branches.
- Creates tables dynamically, adds missing columns, inserts rows, writes load history, and moves failed files.
- Reads root or OS-specific config paths inconsistently, including `config/mysql.conf`, `config/postgres.conf`, `config/ubuntu/postgres.conf`, and `config/ubuntu/mssql.conf`.

Ownership assessment:

- This is not a safe `common` script as-is because it contains database-specific connection logic, SQL quoting rules, metadata queries, and DDL differences.
- The reusable pieces are real, but they should be extracted only after a caller is proven active.
- Best target if preserved: split by database load ownership, with common helper functions for file parsing and load history.

Decision:

- Recommended action: `DELETE CANDIDATE - CONDITIONAL`.
- Do not delete until Jenkins job definitions and manual runbooks confirm no external invocation.
- If retained, refactor only after creating compatibility tests for MySQL, MSSQL, and PostgreSQL load behavior.

## `scripts/data_loader_mongodb.py`

Current behavior:

- MongoDB-only loader for CSV/JSON files under `incoming/mongodb`.
- Loads `config/windows/mongodb.conf` or `config/ubuntu/mongodb.conf` based on runtime OS.
- Inserts documents into collections derived from file names.
- Writes history and moves successful/failed files.

Ownership assessment:

- This belongs to MongoDB load ownership, not common.
- Common extraction is possible only for file parsing, history records, and archive/failed movement.
- MongoDB connection and insert logic should remain under MongoDB.

Decision:

- Recommended action: `DELETE CANDIDATE - CONDITIONAL`.
- If retained, target location should be `scripts/python/mongodb/load/`.
- Validate against active MongoDB load scripts before any removal, especially `scripts/python/mongodb/load_data.py` and `scripts/python/mongodb/load_all.py`.

## `scripts/run_liquibase.py`

Current behavior:

- Scans `liquibase/generated` and executes XML changelogs.
- Saves execution history under `metadata/liquibase_execution_history.jsonl`.
- Intended to support MySQL, PostgreSQL, and MSSQL URL construction.
- Main execution currently loads MySQL config first, falls back to hardcoded MySQL defaults, and executes every XML file as MySQL.
- Uses a fixed MySQL JDBC driver in the Liquibase command.

Ownership assessment:

- This is not a valid database-neutral common utility as-is.
- Liquibase applies only to MySQL, MSSQL, and PostgreSQL in the target architecture.
- MongoDB must not use Liquibase.
- Driver selection, changelog ownership, URL construction, and credentials should be database-owned or config-driven.

Decision:

- Recommended action: `DELETE CANDIDATE - CONDITIONAL`.
- If retained, split by database setup ownership:
  - `scripts/python/mysql/setup/`
  - `scripts/python/mssql/setup/`
  - `scripts/python/postgresql/setup/`
- Keep only a tiny common process runner if needed.

## Pipeline Call Analysis

| Pipeline Area | Evidence | Result |
| --- | --- | --- |
| Jenkins Groovy | No static references to the three script names were found. | No Jenkins pipeline caller identified. |
| Jenkins Batch Wrappers | No static references to the three script names were found. | No Jenkins wrapper caller identified. |
| `scripts/batch` | Database-owned `.bat` files call database-specific loaders and Liquibase batch runners, not these root scripts. | No Batch caller identified. |
| `scripts/bash` | Database-owned `.sh` files call database-specific loaders and Liquibase shell runners, not these root scripts. | No Bash caller identified. |
| `scripts/powershell` | No static references to the three script names were found. | No PowerShell caller identified. |
| Python imports/calls | No static imports or subprocess calls to these script files were found. | No Python caller identified. |

## Recommendation

Do not move these files directly into `common`.

Safe refactoring path:

1. Audit external Jenkins job definitions for direct script invocation.
2. Confirm whether any operator documentation or scheduled task calls these root scripts.
3. If no external usage exists, mark all three as DELETE CANDIDATE in a cleanup-only PR.
4. If usage exists, preserve behavior first, then split ownership:
   - generic file/history/path helpers to `scripts/python/common/`
   - relational load behavior to database-owned MySQL, MSSQL, and PostgreSQL load folders
   - MongoDB load behavior to MongoDB load folder
   - Liquibase execution to MySQL, MSSQL, and PostgreSQL setup folders
5. Run affected setup/load pipelines after any move or deletion.

## Final Classification

| File | Final Classification |
| --- | --- |
| `scripts/data_loader.py` | Conditional DELETE CANDIDATE; otherwise split into common helpers plus MySQL/MSSQL/PostgreSQL load ownership. |
| `scripts/data_loader_mongodb.py` | Conditional DELETE CANDIDATE; otherwise move to MongoDB load ownership. |
| `scripts/run_liquibase.py` | Conditional DELETE CANDIDATE; otherwise split into MySQL/MSSQL/PostgreSQL setup ownership with database-specific Liquibase handling. |
