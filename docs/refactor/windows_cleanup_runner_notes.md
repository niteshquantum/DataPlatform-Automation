# Windows Cleanup Runner Integration - Architecture Notes

## Why wrapper → common runner produced circular orchestration

The database cleanup wrappers (`cleanup_mysql.bat`, `mssql_cleanup_pipeline.bat`, `postgresql_cleanup_pipeline.bat`, `mongodb_cleanup_pipeline.bat`) are not simple launchers. Each wrapper contains the full database-specific orchestration logic: step sequencing, mode validation, script path resolution, and stage error handling.

A common runner that receives `database` and `cleanupMode` cannot invoke the existing database-specific cleanup without either:
- duplicating all database-specific orchestration inside the common runner, or
- having the common runner call back into the very wrappers it is supposed to replace.

Both options create circular orchestration: wrappers delegate to the common runner, and the common runner delegates back to wrappers.

## Why wrapper integration must wait until the cleanup engine exists

Wrapper integration is an orchestration-layer concern. It requires a component that sits *below* the wrappers and *above* the PowerShell cleanup implementations—a cleanup engine that provides cross-cutting behavior (logging, reporting, error handling, configuration loading) without owning database-specific step sequences.

Milestone 2 created only a stub common runner. Without a real cleanup engine, there is nowhere for wrappers to delegate to except each other.

## What Milestone 3 should become instead

Milestone 3 must introduce the cleanup engine, not integrate wrappers with the runner. The engine should:
- encapsulate cross-cutting concerns shared by all databases,
- expose a stable interface that wrappers can call,
- leave database-specific orchestration inside the wrappers.

Only after the engine exists can wrappers become thin delegates. Attempting wrapper integration before the engine exists forces the runner to absorb orchestration it was never designed to hold.
