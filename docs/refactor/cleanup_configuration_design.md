# Cleanup Configuration Design

## Purpose

This document defines the configuration foundation for all database cleanup pipelines in the DataPlatform-Automation repository. The architecture provides a declarative, configuration-driven approach to cleanup that supports Windows, Ubuntu, MySQL, MSSQL, MongoDB, and PostgreSQL without modifying runtime behavior.

## Hierarchy

The cleanup configuration follows a layered merge hierarchy:

```
Common Policy (cleanup.conf)
    ↓
OS Configuration (windows/os.conf or ubuntu/os.conf)
    ↓
Database Configuration (windows/<db>.conf or ubuntu/<db>.conf)
    ↓
Runtime Overrides (environment variables, not yet implemented)
```

Each layer provides settings that are relevant to its scope. Lower layers inherit defaults from upper layers and override only the values that differ.

## Ownership

| Layer | Owner | Responsibility |
|-------|-------|----------------|
| Architecture | Repository maintainers | Define config structure, validation rules, merge order |
| OS Layer | Platform team | Runner type, path separator, shell type, service model |
| Database Layer | Database owners | Installation paths, terraform resources, feature flags, artifact ownership |
| Runtime | Cleanup engine (future) | Mode-specific overrides, per-run parameters |

## Configuration Merge Order

1. **Common**: `config/cleanup/cleanup.conf` defines global policy (modes, validation, artifact rules, safety rules).
2. **OS**: `config/cleanup/{os}/os.conf` defines runner type, path separator, service model, temporary directory, and shell type.
3. **Database**: `config/cleanup/{os}/{db}.conf` defines database-specific installation locations, terraform resources, Liquibase ownership, artifact paths, and future cleanup switches.
4. **Runtime overrides**: Environment variables and parameters passed at execution time take highest precedence. This layer is reserved for future engine implementation.

## Future Usage

These configuration files are prepared for Phase 2 implementation of the cleanup engine. They are not consumed by any existing script or pipeline today. When the engine is built, it will:

- Load `cleanup.conf` to validate cleanup mode and apply global safety rules.
- Load the OS config to determine which shell and runner to use.
- Load the database config to assemble the ordered step list (stop, remove, reset_terraform, xml, load_artifacts, validate) and resolve script paths.
- Apply runtime overrides for per-build parameters (e.g., `CLEANUP_MODE`).

## Why This Architecture Was Chosen

The repository currently achieves cleanup through duplicated shell scripts and Jenkins pipelines across four databases and two operating systems. The duplication is approximately 90-99%, with only path and database name variations. This creates significant maintenance burden and risk of regression.

This configuration-first architecture addresses the problem by:

- **Centralizing policy**: Global rules like allowed modes and safety constraints live in one place.
- **Decomposing variation**: OS differences (PowerShell vs Bash, Windows service vs process) are isolated to the OS layer. Database differences (paths, steps, feature flags) are isolated to the database layer.
- **Preserving existing runtime**: .conf files are the existing convention. No YAML or JSON is introduced, avoiding parser dependencies and maintaining consistency with the rest of the repository.
- **Enabling progressive adoption**: The engine can be introduced incrementally. Existing pipelines continue to operate unchanged while the new configs are populated and validated.
- **Supporting extensibility**: Adding a new database (e.g., Oracle) or OS (e.g., Linux variant) requires only a new conf file, not engine changes.
