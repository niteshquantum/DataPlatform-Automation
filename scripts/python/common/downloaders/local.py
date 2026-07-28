import os
import shutil
from pathlib import Path

SOURCE_TYPE = "local"

def download(config, output_path):
    """
    Copy a dataset from the local file system.
    """

    source_path = (
        os.getenv("SOURCE_PATH")
        or config.get("SOURCE_PATH")
    )

    if not source_path:
        raise ValueError(
            "SOURCE_PATH is not configured."
        )

    source = Path(source_path)

    if not source.exists():
        raise FileNotFoundError(
            f"Local dataset not found: {source}"
        )

    shutil.copy2(
        source,
        output_path
    )