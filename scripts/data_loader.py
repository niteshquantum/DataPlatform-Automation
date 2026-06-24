#!/usr/bin/env python
"""
Generic Data Loader

Automatically loads CSV and JSON files from incoming/ into the database using
dynamic schema detection and parameterized inserts.
"""

import csv
import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path
import platform
try:
    import mysql.connector
except ImportError:
    mysql = None
else:
    mysql = mysql

try:
    import psycopg2
    import psycopg2.extras
except ImportError:
    psycopg2 = None

try:
    import pyodbc
except ImportError:
    pyodbc = None

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

BATCH_SIZE = 500
HISTORY_FILE = None


def load_config(config_path):
    config = {}
    try:
        if config_path.exists():
            with open(config_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith('#'):
                        continue
                    if '=' in line:
                        key, value = line.split('=', 1)
                        config[key.strip()] = value.strip()
        return config
    except Exception as e:
        logger.error(f"Error reading config file {config_path}: {e}")
        return {}


# def detect_db_type():
#     env_db = os.environ.get('DB_TYPE')
#     if env_db:
#         return env_db.lower()

#     root = Path(__file__).resolve().parent.parent
#     if (root / 'config' / 'mysql.conf').exists():
#         return 'mysql'
#     if (root / 'config' / 'ubuntu' / 'mssql.conf').exists():
#         return 'mssql'
#     if (root / 'config' / 'postgres.conf').exists():
#         return 'postgresql'
#     if (root / 'config' / 'ubuntu' / 'postgres.conf').exists():
#         return 'postgresql'
#     return 'mysql'


def get_database_connection(db_type, config):
    if db_type == 'mysql':
        if mysql is None:
            raise ImportError('mysql.connector is not installed')
        return mysql.connector.connect(
            host=config.get('MYSQL_HOST', 'localhost'),
            port=int(config.get('MYSQL_PORT', 3306)),
            user=config.get('MYSQL_USER', 'root'),
            password=config.get('MYSQL_PASSWORD', ''),
            database=config.get('MYSQL_DB', '')
        )
    if db_type == 'postgresql':
        if psycopg2 is None:
            raise ImportError('psycopg2 is not installed')
        return psycopg2.connect(
            host=config.get('POSTGRES_HOST', 'localhost'),
            port=int(config.get('POSTGRES_PORT', 5432)),
            user=config.get('POSTGRES_USER', 'postgres'),
            password=config.get('POSTGRES_PASSWORD', ''),
            dbname=config.get('POSTGRES_DB', '')
        )
    if db_type == 'mssql':
        if pyodbc is None:
            raise ImportError('pyodbc is not installed')
        driver = config.get('MSSQL_DRIVER', 'ODBC Driver 18 for SQL Server')
        return pyodbc.connect(
            f"DRIVER={{{driver}}};"
            f"SERVER={config.get('MSSQL_HOST', 'localhost')},{config.get('MSSQL_PORT', 1433)};"
            f"DATABASE={config.get('MSSQL_DB', '')};"
            f"UID={config.get('MSSQL_USER', 'sa')};"
            f"PWD={config.get('MSSQL_PASSWORD', '')};"
            f"Encrypt=yes;TrustServerCertificate=yes;"
        )
    raise ValueError(f"Unsupported DB_TYPE: {db_type}")


def quote_name(name, db_type):
    if db_type == 'mysql':
        return '"' + name.replace('"', '""') + '"'
    if db_type == 'postgresql':
        return '"' + name.replace('"', '""') + '"'
    if db_type == 'mssql':
        return '"' + name.replace('"', '""') + '"'
    return name


def placeholders(db_type, count):
    if db_type == 'mysql' or db_type == 'postgresql':
        return ', '.join(['%s'] * count)
    if db_type == 'mssql':
        return ', '.join(['?'] * count)
    return ', '.join(['%s'] * count)


def get_table_columns(conn, db_type, table_name):
    cursor = conn.cursor()
    try:
        if db_type == 'mysql':
            cursor.execute(
                "SELECT COLUMN_NAME FROM information_schema.columns "
                "WHERE table_schema = DATABASE() AND table_name = %s",
                (table_name,)
            )
            return [row[0] for row in cursor.fetchall()]
        if db_type == 'postgresql':
            cursor.execute(
                "SELECT column_name FROM information_schema.columns "
                "WHERE table_schema = 'public' AND table_name = %s",
                (table_name,)
            )
            return [row[0] for row in cursor.fetchall()]
        if db_type == 'mssql':
            cursor.execute(
                "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS "
                "WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = ?",
                (table_name,)
            )
            return [row[0] for row in cursor.fetchall()]
    except Exception:
        return []
    finally:
        cursor.close()


def table_exists(conn, db_type, table_name):
    return bool(get_table_columns(conn, db_type, table_name))


def create_table(conn, db_type, table_name, column_names):
    quoted_table = quote_name(table_name, db_type)
    columns_sql = ', '.join(
        f"{quote_name(name, db_type)} VARCHAR(255)" for name in column_names
    )
    sql = f"CREATE TABLE {quoted_table} ({columns_sql})"
    cursor = conn.cursor()
    try:
        logger.info(f"Creating table {table_name} with {len(column_names)} column(s)")
        cursor.execute(sql)
        conn.commit()
    finally:
        cursor.close()


def add_missing_columns(conn, db_type, table_name, missing_columns):
    if not missing_columns:
        return
    quoted_table = quote_name(table_name, db_type)
    definitions = ', '.join(
        f"{quote_name(name, db_type)} VARCHAR(255)" for name in missing_columns
    )
    sql = f"ALTER TABLE {quoted_table} ADD {definitions}"
    cursor = conn.cursor()
    try:
        logger.info(f"Adding {len(missing_columns)} missing column(s) to {table_name}")
        cursor.execute(sql)
        conn.commit()
    finally:
        cursor.close()


def prepare_rows(rows, actual_columns, file_columns):
    prepared = []
    for row in rows:
        values = [row.get(col) if col in row else None for col in actual_columns]
        prepared.append(values)
    return prepared


def insert_rows(conn, db_type, table_name, actual_columns, rows):
    if not rows:
        return 0
    quoted_table = quote_name(table_name, db_type)
    quoted_columns = ', '.join(quote_name(col, db_type) for col in actual_columns)
    value_placeholders = placeholders(db_type, len(actual_columns))
    sql = f"INSERT INTO {quoted_table} ({quoted_columns}) VALUES ({value_placeholders})"
    cursor = conn.cursor()
    rows_inserted = 0
    try:
        for start in range(0, len(rows), BATCH_SIZE):
            batch = rows[start:start + BATCH_SIZE]
            cursor.executemany(sql, batch)
            rows_inserted += len(batch)
        conn.commit()
    finally:
        cursor.close()
    return rows_inserted


def read_csv_file(path):
    rows = []
    with open(path, 'r', encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append({k: (v if v != '' else None) for k, v in row.items()})
    return rows


def read_json_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read().strip()
        if not content:
            return []
        try:
            data = json.loads(content)
        except json.JSONDecodeError:
            rows = []
            for line in content.splitlines():
                if line.strip():
                    rows.append(json.loads(line))
            return rows
        if isinstance(data, dict):
            return [data]
        if isinstance(data, list):
            return [item if isinstance(item, dict) else {} for item in data]
        return []


def write_history(record):
    path = Path(HISTORY_FILE)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, 'a', encoding='utf-8') as f:
        f.write(json.dumps(record) + '\n')

def is_file_already_processed(file_name):
    """
    Check if file has already been successfully processed.
    """
    history_path = Path(HISTORY_FILE)

    if not history_path.exists():
        return False

    try:
        with open(history_path, 'r', encoding='utf-8') as f:

            for line in f:

                if not line.strip():
                    continue

                try:
                    record = json.loads(line)

                    if (
                        record.get('file') == file_name
                        and record.get('status') == 'SUCCESS'
                    ):
                        return True

                except json.JSONDecodeError:
                    continue

        return False

    except Exception as e:
        logger.error(f"Error reading history file: {e}")
        return False

def move_file(source_path, dest_dir):
    dest_dir = Path(dest_dir)
    dest_dir.mkdir(parents=True, exist_ok=True)
    target = dest_dir / source_path.name
    source_path.rename(target)
    return target


def load_and_insert_file(conn, db_type, path):
    table_name = (
    path.stem
    .strip()
    .lower()
    .replace(' ', '_')
    )
    logger.info(f"Processing file: {path.name} -> table: {table_name}")

    if path.suffix.lower() == '.csv':
        rows = read_csv_file(path)
    else:
        rows = read_json_file(path)

    if not rows:
        logger.warning(f"No rows found in file {path.name}")
        return 0

    file_columns = list({key for row in rows for key in row.keys() if key is not None})
    if not file_columns:
        logger.warning(f"No columns detected in file {path.name}")
        return 0

    existing_columns = get_table_columns(conn, db_type, table_name)
    if not existing_columns:
        create_table(conn, db_type, table_name, file_columns)
        existing_columns = file_columns
    else:
        new_columns = [col for col in file_columns if col not in existing_columns]
        if new_columns:
            add_missing_columns(conn, db_type, table_name, new_columns)
            existing_columns.extend(new_columns)

    actual_columns = [col for col in existing_columns if col in file_columns] + \
                     [col for col in existing_columns if col not in file_columns]
    rows_prepared = prepare_rows(rows, actual_columns, file_columns)
    inserted = insert_rows(conn, db_type, table_name, actual_columns, rows_prepared)
    return inserted




def get_config_for_db(db_type):
    root = Path(__file__).resolve().parent.parent

    if db_type == 'mysql':

        if platform.system() == "Windows":
            return load_config(root / 'config' / 'mysql.conf')

        return load_config(
            root / 'config' / 'ubuntu' / 'mysql.config'
        )

    if db_type == 'postgresql':
        config = load_config(root / 'config' / 'postgres.conf')
        if not config:
            config = load_config(root / 'config' / 'ubuntu' / 'postgres.conf')
        return config

    if db_type == 'mssql':
        config = load_config(root / 'config' / 'ubuntu' / 'mssql.conf')
        if not config:
            config = load_config(root / 'config' / 'mssql.conf')
        return config

    return {}


def main():
    
    logger.info('Starting generic data loader...')

    project_root = Path(__file__).resolve().parent.parent

    db_type = sys.argv[1].lower() if len(sys.argv) > 1 else "mysql"

    global HISTORY_FILE

    HISTORY_FILE = (
        project_root
        / 'metadata'
        / db_type
        / 'data_load_history.jsonl'
    )

    incoming_dir = project_root / 'incoming' / db_type

    archive_dir = project_root / 'archive' / db_type

    failed_dir = project_root / 'failed' / db_type

    if not incoming_dir.exists():
        logger.error('incoming/ directory does not exist')
        return

    db_type = sys.argv[1].lower() if len(sys.argv) > 1 else "mysql"
    config = get_config_for_db(db_type)
    if not config:
        logger.error(f'No configuration found for database type {db_type}')
        return

    try:
        conn = get_database_connection(db_type, config)
    except Exception as exc:
        logger.error(f'Unable to connect to database: {exc}')
        return

    
    data_files = [p for p in incoming_dir.glob('*.csv')] + [p for p in incoming_dir.glob('*.json')]
    logger.info(f'Found {len(data_files)} data file(s) in incoming/')

    for path in data_files:
        # Skip already processed files
        if is_file_already_processed(path.name):
            logger.info(f"{path.name} already processed. Skipping.")
            continue
        timestamp = datetime.now().isoformat()
        rows_inserted = 0
        status = 'FAILED'
        try:
            rows_inserted = load_and_insert_file(conn, db_type, path)
            status = 'SUCCESS'
            logger.info(
                f"Loaded {rows_inserted} rows from {path.name}"
            )
        except Exception as exc:
            logger.error(f'Error loading file {path.name}: {exc}')
            move_file(path, failed_dir)
        finally:
            record = {
                'timestamp': timestamp,
                'file': path.name,
                'table': (
                    path.stem
                    .strip()
                    .lower()
                    .replace(' ', '_')
                ),
                'rows_inserted': rows_inserted,
                'status': status
            }
            write_history(record)

    if conn:
        conn.close()
    logger.info('Data loader completed')


if __name__ == '__main__':
    main()
