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
   - Generated artifacts must be regenerated when required.
   - Gitignored artifacts are expected; do not require them to exist before runtime generation.

4. **POST/ARCHIVE SAFETY**
   - archiveArtifacts must use allowEmptyArchive: true
   - Prevents MissingContextVariableException after early checkout failure
   - Relevant commits: 215a533

5. **SERVICE REUSE**
   - Managed instances can be reused across Jenkins workspaces when valid.
   - Requires ownership verification, not just port check.
   - Relevant commits: febdf7f

## MongoDB Windows Adaptation Requirements

MongoDB must adapt the proven architecture to its own specific capabilities:

### Instance Lifecycle
- MongoDB service management differs from PostgreSQL pg_ctl/psql
- Instance-state detection must use MongoDB-specific commands (mongod, mongosh)
- Service reuse must verify MongoDB instance ownership, not just port 27017 availability

### Tooling
- MongoDB Database Tools or mongosh for operations
- MongoDB-specific JDBC/ODBC driver if needed
- Potential need for mongodump/mongorestore for data loading

### Data Loading
- MongoDB is document-oriented (collections vs tables)
- No traditional Liquibase schema migration for collections
- Data loading may use JSON/CSV import tools or application-level insertion

### Object Generation
- No traditional views, functions, procedures, triggers like relational databases
- May use MongoDB aggregations, change streams, validation rules
- Object validation must adapt to MongoDB capabilities

### CDC
- MongoDB Change Streams or oplog tailing
- Different configuration requirements than PostgreSQL logical decoding

### Assessment/Reconciliation/Discovery/Reporting
- Must query MongoDB system collections (db.stats(), db.getCollectionNames(), etc.)
- Different metadata queries than relational databases
- Must preserve same output structure where possible

## What Must NOT Be Copied

- PostgreSQL Windows service implementation (pg_ctl, postgresql.conf)
- PostgreSQL-specific Liquibase behavior for relational schemas
- PostgreSQL object types (PL/pgSQL functions, etc.)
- PostgreSQL-specific PowerShell commands
- PostgreSQL-specific schema_registry.json handling for tables

## Workspace Structure

```
FinalMongo1/
├── PROJECT_WORKING_STATE/
│   ├── README.md
│   ├── CURRENT_STATE.md
│   ├── ARCHITECTURE.md
│   ├── HANDOFFS/
│   ├── ERRORS/
│   ├── TESTS/
│   └── DECISIONS/
├── jenkins/mongodb/windows/
│   ├── setup_pipeline.groovy
│   ├── load_pipeline.groovy
│   └── cleanup_pipeline.groovy
├── scripts/
│   ├── batch/mongodb/             # Windows .bat orchestrators
│   ├── python/mongodb/            # MongoDB-specific Python utilities
│   └── common/                    # Shared utilities
├── metadata/mongodb/
│   └── schema_registry.json       # If needed for data profiling
└── objects/mongodb/generated/     # Gitignored runtime artifacts
```
