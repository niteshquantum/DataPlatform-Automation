# ARCHITECTURE

## Proven Reference: PostgreSQL Windows

PostgreSQL Windows implementation is the proven architectural reference for all database implementations in this project. It has been validated through extensive Jenkins testing and contains multiple fixes discovered through real pipeline execution.

### Key Proven Behaviors

1. **PORT OPEN != INSTANCE OWNERSHIP**
   - A PostgreSQL instance answering on configured host:port does NOT automatically mean it is the current workspace-managed deployment.
   - Instance state must be checked before reuse decision.
   - Relevant commits: febdf7f (service reuse across workspaces)

2. **FRESH WORKSPACE COMPATIBILITY**
   - SETUP and LOAD may execute in different Jenkins workspaces.
   - LOAD must provision its own tools (Liquibase, JDBC) without assuming SETUP workspace binaries exist.
   - Relevant commits: 7fd3d7d (fresh LOAD workspace tool provisioning)

3. **RUNTIME-GENERATED ARTIFACTS**
   - Generated Liquibase/object XML files may be gitignored intentionally.
   - Main Groovy must not require generated XML to exist before runtime generation.
   - master.xml handles table/schema changes only.
   - master_objects.xml handles business objects separately.
   - Relevant commits: 1182c25 (master_objects.xml excluded from master.xml)

4. **POST/ARCHIVE SAFETY**
   - archiveArtifacts must use allowEmptyArchive: true
   - Prevents MissingContextVariableException after early checkout failure
   - Relevant commits: 215a533

5. **SERVICE REUSE**
   - PostgreSQLAutomation service can be reused across Jenkins workspaces when valid.
   - Requires ownership verification, not just port check.
   - Relevant commits: febdf7f

## MSSQL Windows Adaptation Requirements

MSSQL must adapt the proven architecture to its own specific capabilities:

### Instance Lifecycle
- MSSQL service management differs from PostgreSQL pg_ctl/psql
- Instance-state detection must use MSSQL-specific commands
- Service reuse must verify MSSQL instance ownership, not just port 1433 availability

### Tooling
- SQLCMD or equivalent MSSQL client tooling
- MSSQL-specific JDBC driver
- Potential need for sqlpackage or similar deployment tools

### Schema/Liquibase
- MSSQL-specific Liquibase configuration
- Different data types, identity columns, schemas
- master.xml adaptation for MSSQL dialect

### Object Generation
- Views, functions, procedures, indexes, triggers differ in MSSQL
- T-SQL syntax vs PL/pgSQL
- Different capabilities and limitations

### CDC
- MSSQL CDC/CT (Change Tracking) or alternative approach
- Different configuration requirements

### Assessment/Reconciliation/Discovery/Reporting
- Must query MSSQL system catalogs (sys.tables, sys.columns, etc.)
- Different metadata queries than PostgreSQL
- Must preserve same output structure where possible

## What Must NOT Be Copied

- PostgreSQL Windows service implementation (pg_ctl, postgresql.conf)
- PostgreSQL-specific Liquibase behavior
- PostgreSQL object types (PL/pgSQL functions, etc.)
- PostgreSQL-specific PowerShell commands
- PostgreSQL-specific schema_registry.json handling unless通用

## Workspace Structure

```
FinalMssql1/
├── PROJECT_WORKING_STATE/
│   ├── README.md
│   ├── CURRENT_STATE.md
│   ├── ARCHITECTURE.md
│   ├── HANDOFFS/
│   ├── ERRORS/
│   ├── TESTS/
│   └── DECISIONS/
├── jenkins/mssql/windows/
│   ├── setup_pipeline.groovy
│   ├── load_pipeline.groovy
│   └── cleanup_pipeline.groovy
├── scripts/
│   ├── batch/mssql/              # Windows .bat orchestrators
│   ├── bash/mssql/               # If any Ubuntu cross-reference needed
│   ├── python/mssql/             # MSSQL-specific Python utilities
│   └── common/                   # Shared utilities
├── liquibase/mssql/
│   ├── master.xml
│   └── master_objects.xml
├── metadata/mssql/
│   └── schema_registry.json      # If needed for object generation
└── objects/mssql/generated/      # Gitignored runtime artifacts
```
