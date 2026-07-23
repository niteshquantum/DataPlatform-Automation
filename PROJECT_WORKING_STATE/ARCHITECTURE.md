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
   - LOAD must provision its own tools without assuming SETUP workspace binaries exist.
   - Relevant commits: 7fd3d7d (fresh LOAD workspace tool provisioning)

3. **RUNTIME-GENERATED ARTIFACTS**
   - Generated Liquibase/object XML files must be regenerated when required.
   - Gitignored artifacts are expected; do not require them to exist before runtime generation.
   - master.xml handles table/schema changes only.
   - master_objects.xml handles business objects separately.
   - Relevant commits: 1182c25 (master_objects.xml excluded from master.xml)

4. **POST/ARCHIVE SAFETY**
   - archiveArtifacts must use allowEmptyArchive: true
   - Prevents MissingContextVariableException after early checkout failure
   - Relevant commits: 215a533

5. **SERVICE REUSE**
   - Managed instances can be reused across Jenkins workspaces when valid.
   - Requires ownership verification, not just port check.
   - Relevant commits: febdf7f

## MySQL Windows Adaptation Requirements

MySQL must adapt the proven architecture to its own specific capabilities:

### Instance Lifecycle
- MySQL service management differs from PostgreSQL pg_ctl/psql
- Instance-state detection must use MySQL-specific commands (mysqld, mysqladmin, systemctl)
- Service reuse must verify MySQL instance ownership, not just port 3306 availability

### Tooling
- MySQL-specific JDBC driver
- mysqladmin, mysqldump, mysql client utilities
- Potential need for MySQL-specific PowerShell/CLI commands on Windows

### Schema/Liquibase
- MySQL-specific Liquibase configuration
- Different data types, engine settings, collation
- master.xml adaptation for MySQL dialect

### Object Generation
- Views, functions, procedures, indexes, triggers differ in MySQL
- MySQL-specific syntax for stored programs
- Different capabilities and limitations (e.g., no materialized views in standard MySQL)

### CDC
- MySQL binlog-based CDC or alternative approach
- Different configuration requirements than PostgreSQL logical decoding

### Assessment/Reconciliation/Discovery/Reporting
- Must query MySQL system catalogs (information_schema, performance_schema)
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
FinalMysql1/
├── PROJECT_WORKING_STATE/
│   ├── README.md
│   ├── CURRENT_STATE.md
│   ├── ARCHITECTURE.md
│   ├── HANDOFFS/
│   ├── ERRORS/
│   ├── TESTS/
│   └── DECISIONS/
├── jenkins/mysql/windows/
│   ├── setup_pipeline.groovy
│   ├── load_pipeline.groovy
│   └── cleanup_pipeline.groovy
├── scripts/
│   ├── batch/mysql/               # Windows .bat orchestrators
│   ├── python/mysql/              # MySQL-specific Python utilities
│   └── common/                    # Shared utilities
├── liquibase/mysql/
│   ├── master.xml
│   └── master_objects.xml
├── metadata/mysql/
│   └── schema_registry.json       # If needed for object generation
└── objects/mysql/generated/       # Gitignored runtime artifacts
```
