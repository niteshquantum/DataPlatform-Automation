"""Idempotent native MySQL RBAC provisioning and verification."""
from __future__ import annotations
import sys
from pathlib import Path
import mysql.connector

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))
from scripts.python.common.rbac_config import database_rbac_config, validate_identifier
from scripts.python.common.rbac_logging import get_rbac_logger
from scripts.python.common.rbac_cli import command_arguments

DATABASE = "mysql"
ROLE_NAMES = {role: f"dp_{role}" for role in ("admin", "developer", "qa", "viewer")}

def connect(config, database=None, user=None, password=None):
    return mysql.connector.connect(host=config["MYSQL_HOST"], port=int(config["MYSQL_PORT"]),
        user=user or config["MYSQL_USER"], password=password or config["MYSQL_PASSWORD"], database=database)

def sql(cursor, statement, params=None):
    cursor.execute(statement, params or ())

def configure():
    config, users = database_rbac_config(DATABASE); log = get_rbac_logger(DATABASE)
    if config.get("RBAC_ENABLED", "true").lower() == "false": log.info("RBAC disabled by configuration"); return
    db = validate_identifier(config["MYSQL_DB"], "database name")
    conn = connect(config); cursor = conn.cursor()
    try:
        for role in ROLE_NAMES.values(): sql(cursor, f"CREATE ROLE IF NOT EXISTS `{role}`")
        # Explicit grants make reruns convergent and do not grant user-management to non-admin roles.
        sql(cursor, f"GRANT ALL PRIVILEGES ON *.* TO `{ROLE_NAMES['admin']}` WITH GRANT OPTION")
        sql(cursor, f"GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO `{ROLE_NAMES['admin']}`")
        sql(cursor, f"GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, EXECUTE ON `{db}`.* TO `{ROLE_NAMES['developer']}`")
        sql(cursor, f"GRANT SELECT, EXECUTE ON `{db}`.* TO `{ROLE_NAMES['qa']}`")
        sql(cursor, f"GRANT SELECT ON `{db}`.* TO `{ROLE_NAMES['viewer']}`")
        for role, credentials in users.items():
            username = credentials["username"]
            sql(cursor, "CREATE USER IF NOT EXISTS %s@'%%' IDENTIFIED BY %s", (username, credentials["password"]))
            sql(cursor, "ALTER USER %s@'%%' IDENTIFIED BY %s", (username, credentials["password"]))
            sql(cursor, "GRANT `%s` TO %s@'%%'" % (ROLE_NAMES[role], "`" + username + "`"))
            sql(cursor, "SET DEFAULT ROLE `%s` TO %s@'%%'" % (ROLE_NAMES[role], "`" + username + "`"))
            log.info("user and role reconciled: %s -> %s", username, ROLE_NAMES[role])
        conn.commit(); log.info("RBAC configuration PASS")
    finally: cursor.close(); conn.close()

def expect(label, allowed, operation):
    try: operation()
    except Exception as error:
        result = not allowed
        print(f"{'PASS' if result else 'FAIL'} {label}: {error.__class__.__name__}")
        return result
    print(f"{'PASS' if allowed else 'FAIL'} {label}"); return allowed

def validate():
    config, users = database_rbac_config(DATABASE); db = validate_identifier(config["MYSQL_DB"], "database name")
    log = get_rbac_logger(DATABASE); results = []
    def run(role, statement):
        def op():
            c = connect(config, db, users[role]["username"], users[role]["password"]); cur = c.cursor(); cur.execute(statement); c.rollback(); cur.close(); c.close()
        return op
    def admin_database_test():
        c = connect(config, user=users["admin"]["username"], password=users["admin"]["password"])
        cur = c.cursor()
        try:
            cur.execute("CREATE DATABASE dp_rbac_validation_tmp")
            cur.execute("DROP DATABASE dp_rbac_validation_tmp")
        finally:
            cur.close(); c.close()
    results += [expect("admin can create database", True, admin_database_test),
                expect("developer can modify schema", True, run("developer", "CREATE TABLE IF NOT EXISTS dp_rbac_validation_tmp(id INT PRIMARY KEY)")),
                expect("developer can insert", True, run("developer", "INSERT INTO dp_rbac_validation_tmp VALUES (1)")),
                expect("developer can update", True, run("developer", "UPDATE dp_rbac_validation_tmp SET id=2 WHERE id=1")),
                expect("developer can delete", True, run("developer", "DELETE FROM dp_rbac_validation_tmp WHERE id=2")),
                expect("developer cannot manage users", False, run("developer", "CREATE USER dp_denied IDENTIFIED BY 'x'")),
                expect("qa can read", True, run("qa", "SELECT * FROM dp_rbac_validation_tmp")),
                expect("qa cannot modify data", False, run("qa", "INSERT INTO dp_rbac_validation_tmp VALUES (1)")),
                expect("viewer can read", True, run("viewer", "SELECT * FROM dp_rbac_validation_tmp")),
                expect("viewer cannot insert", False, run("viewer", "INSERT INTO dp_rbac_validation_tmp VALUES (1)")),
                expect("viewer cannot modify schema", False, run("viewer", "CREATE TABLE dp_viewer_denied(id INT)"))]
    # The project owner removes the validation object because the developer role deliberately lacks DROP.
    c = connect(config); cur = c.cursor(); cur.execute(f"DROP TABLE IF EXISTS `{db}`.dp_rbac_validation_tmp"); cur.close(); c.close()
    log.info("RBAC validation %s", "PASS" if all(results) else "FAIL")
    if not all(results): raise SystemExit(1)

def main():
    args = command_arguments("MySQL RBAC"); configure()
    if args.command == "validate" or not args.skip_validation: validate()
if __name__ == "__main__": main()
