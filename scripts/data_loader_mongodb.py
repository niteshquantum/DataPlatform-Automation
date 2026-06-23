#!/usr/bin/env python
"""
MongoDB Generic Data Loader

Automatically loads CSV and JSON files from incoming/ into MongoDB collections
using dynamic collection naming and parameterless inserts.
"""
import platform
import csv
import json
import sys
import logging
from datetime import datetime
from pathlib import Path
import sys

try:
    import pandas as pd
except ImportError:
    pd = None

try:
    from pymongo import MongoClient
    from pymongo.errors import PyMongoError
except ImportError:
    MongoClient = None
    PyMongoError = None

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

HISTORY_FILE = 'metadata/data_load_history.jsonl'


def load_config(config_path):
    """Load MongoDB configuration from file."""
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


def connect_mongodb(config):
    """Connect to MongoDB using configuration."""
    try:
        if MongoClient is None:
            raise ImportError('pymongo is not installed')
        
        host = config.get('MONGODB_HOST', 'localhost')
        port = int(config.get('MONGODB_PORT', 27017))
        database = config.get('MONGODB_DATABASE', 'test')
        
        logger.info(f"Connecting to MongoDB at {host}:{port}/{database}")
        
        client = MongoClient(host, port, serverSelectionTimeoutMS=5000)
        # Verify connection
        client.admin.command('ping')
        
        db = client[database]
        logger.info(f"Successfully connected to MongoDB database: {database}")
        return client, db
    except Exception as e:
        logger.error(f"Failed to connect to MongoDB: {e}")
        raise


def read_csv_file(path):
    """
    Read CSV file and convert to list of dictionaries.
    """
    try:
        if pd is not None:
            df = pd.read_csv(path)
            # Replace NaN with None for MongoDB compatibility
            df = df.where(pd.notna(df), None)
            records = df.to_dict(orient='records')
            logger.info(f"Read {len(records)} rows from {path.name} using pandas")
            return records
        else:
            # Fallback: use standard csv module
            records = []
            with open(path, 'r', encoding='utf-8-sig', newline='') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    # Convert empty strings to None
                    records.append({k: (v if v != '' else None) for k, v in row.items()})
            logger.info(f"Read {len(records)} rows from {path.name} using csv module")
            return records
    except Exception as e:
        logger.error(f"Error reading CSV file {path}: {e}")
        return []


def read_json_file(path):
    """
    Read JSON file and convert to list of dictionaries.
    Handles both JSON objects and JSON arrays.
    """
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read().strip()
            if not content:
                return []
            
            # Try parsing as single JSON object first
            try:
                data = json.loads(content)
            except json.JSONDecodeError:
                # Try parsing as JSON lines (one object per line)
                records = []
                for line in content.splitlines():
                    if line.strip():
                        try:
                            records.append(json.loads(line))
                        except json.JSONDecodeError:
                            logger.warning(f"Skipped invalid JSON line in {path.name}")
                return records
            
            # Handle different JSON structures
            if isinstance(data, dict):
                records = [data]
            elif isinstance(data, list):
                records = [item if isinstance(item, dict) else {} for item in data]
            else:
                logger.warning(f"Unexpected JSON structure in {path.name}")
                records = []
            
            logger.info(f"Read {len(records)} documents from {path.name}")
            return records
    except Exception as e:
        logger.error(f"Error reading JSON file {path}: {e}")
        return []


def insert_documents(collection, documents):
    """
    Insert documents into MongoDB collection using insert_many.
    """
    if not documents:
        return 0
    
    try:
        result = collection.insert_many(documents)
        inserted_count = len(result.inserted_ids)
        logger.info(f"Inserted {inserted_count} documents into {collection.name}")
        return inserted_count
    except Exception as e:
        logger.error(f"Error inserting documents into {collection.name}: {e}")
        raise


def write_history(record):
    """Write load history record to JSONL file."""
    path = Path(HISTORY_FILE)
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with open(path, 'a', encoding='utf-8') as f:
            f.write(json.dumps(record) + '\n')
    except Exception as e:
        logger.error(f"Error writing history record: {e}")


def is_file_already_processed(file_name):
    """Check if file has already been successfully processed."""
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
                    if record.get('file') == file_name and record.get('status') == 'SUCCESS':
                        return True
                except json.JSONDecodeError:
                    continue
        return False
    except Exception as e:
        logger.error(f"Error reading history file: {e}")
        return False


def move_file(source_path, dest_dir):
    """Move file to destination directory with timestamp appending if it already exists."""
    try:
        dest_dir = Path(dest_dir)
        dest_dir.mkdir(parents=True, exist_ok=True)
        target = dest_dir / source_path.name
        
        # If target already exists, append timestamp
        if target.exists():
            stem = source_path.stem
            suffix = source_path.suffix
            timestamp_str = datetime.now().strftime("%Y%m%d_%H%M%S")
            new_name = f"{stem}_{timestamp_str}{suffix}"
            target = dest_dir / new_name
            logger.info(f"File {source_path.name} already exists. Appending timestamp.")
        
        source_path.rename(target)
        logger.info(f"Moved {source_path.name} to {dest_dir.name}/{target.name}")
        return target
    except Exception as e:
        logger.error(f"Error moving file {source_path.name}: {e}")
        return None


def load_file_into_mongodb(db, path):
    """
    Load a single file (CSV or JSON) into MongoDB.
    Returns number of documents inserted.
    """
    collection_name = path.stem.lower().replace(" ", "_")
    logger.info(f"Processing file: {path.name} -> collection: {collection_name}")
    
    # Read file based on extension
    if path.suffix.lower() == '.csv':
        documents = read_csv_file(path)
    elif path.suffix.lower() == '.json':
        documents = read_json_file(path)
    else:
        logger.warning(f"Skipping unsupported file type: {path.name}")
        return 0
    
    if not documents:
        logger.warning(f"No documents found in {path.name}")
        return 0
    
    # Get collection and insert
    collection = db[collection_name]
    inserted_count = insert_documents(collection, documents)
    return inserted_count


def main():
    """Main function to load all files from incoming/ into MongoDB."""
    logger.info('Starting MongoDB data loader...')
    
    project_root = Path(__file__).resolve().parent.parent
    incoming_dir = project_root / "incoming" / "mongodb"
    archive_dir = project_root / "archive" / "mongodb"
    failed_dir = project_root / "failed" / "mongodb"
    

    if platform.system() == "Windows":
        config_path = (
            project_root
            / "config"
            / "windows"
            / "mongodb.conf"
        )
    else:
        config_path = (
            project_root
            / "config"
            / "ubuntu"
            / "mongodb.conf"
        )
        
    # Verify incoming directory exists
    if not incoming_dir.exists():
        logger.error('incoming/ directory does not exist')
        sys.exit(1)
    
    # Load MongoDB configuration
    config = load_config(config_path)
    if not config:
        logger.error('No MongoDB configuration found')
        sys.exit(1) 
    
    # Connect to MongoDB
   

    try:
        client, db = connect_mongodb(config)
    except Exception as e:
        logger.error(f'Failed to connect to MongoDB: {e}')
        sys.exit(1)
    
    # Find all data files
    data_files = sorted(list(incoming_dir.glob('*.csv')) + list(incoming_dir.glob('*.json')))
    logger.info(f'Found {len(data_files)} data file(s) in incoming/')
    
    if not data_files:
        logger.info('No files to process')
        client.close()
        return
    
    # Process each file
    successful_count = 0
    failed_count = 0
    skipped_count = 0
    
    for path in data_files:
        # Check if file was already processed successfully
        if is_file_already_processed(path.name):
            logger.info(f"{path.name} already processed. Skipping.")
            skipped_count += 1
            continue
        
        timestamp = datetime.now().isoformat()
        collection_name = path.stem.lower().replace(" ", "_")
        rows_inserted = 0
        status = 'FAILED'
        
        try:
            rows_inserted = load_file_into_mongodb(db, path)
            status = 'SUCCESS'
            move_file(path, archive_dir)
            successful_count += 1
            logger.info(f'Successfully loaded {rows_inserted} documents from {path.name}')
        except Exception as e:
            logger.error(f'Error loading file {path.name}: {e}')
            move_file(path, failed_dir)
            failed_count += 1
        finally:
            # Write history record
            record = {
                'timestamp': timestamp,
                'file': path.name,
                'collection': collection_name,
                'rows_inserted': rows_inserted,
                'status': status
            }
            write_history(record)
    
    # Close MongoDB connection
    client.close()
    logger.info(f'MongoDB connection closed')
    
    # Summary
    logger.info(f"\n{'='*60}")
    logger.info(f"MongoDB Data Loader Summary:")
    logger.info(f"  Total files found: {len(data_files)}")
    logger.info(f"  Successful: {successful_count}")
    logger.info(f"  Failed: {failed_count}")
    logger.info(f"  Skipped (already processed): {skipped_count}")
    logger.info(f"  Archive dir: {archive_dir}")
    logger.info(f"  Failed dir: {failed_dir}")
    logger.info(f"  History file: {Path(HISTORY_FILE)}")
    logger.info(f"{'='*60}")


if __name__ == '__main__':
    main()
