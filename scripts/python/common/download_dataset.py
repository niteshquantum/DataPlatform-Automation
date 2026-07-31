import os
from pathlib import Path
import sys

import gdown

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from scripts.python.common.config_loader import (
    load_common_config,
    get_project_root
)

from scripts.python.common.factory.downloader_factory import (
    get_downloader
)
from scripts.python.common.source_utils import (
    get_output_filename,
    is_archive_file
)


def print_header():

    print()
    print("=" * 60)
    print("DATASET DOWNLOAD")
    print("=" * 60)


def create_directory(directory: Path):

    directory.mkdir(parents=True, exist_ok=True)


def download_dataset():

    config = load_common_config("dataset")

    project_root = get_project_root()

    source_type = (
        os.getenv("SOURCE_TYPE")
        or config.get("SOURCE_TYPE")
    )

    source_path = (
        os.getenv("SOURCE_PATH")
        or config.get("SOURCE_PATH")
    )

    database = (
        os.getenv("DATABASE")
        or config.get("DATABASE")
    )

    downloader = get_downloader(source_type)

    output_filename = get_output_filename(
        source_type=source_type,
        source_path=source_path,
        config=config
    )

    # -------------------------
    # Decide destination
    # -------------------------

    if is_archive_file(source_path):

        destination_directory = (
            project_root /
            config["DOWNLOAD_DIRECTORY"]
        )

    else:

        if not database:
            raise ValueError("DATABASE is required for non-archive datasets.")

        destination_directory = (
            project_root /
            "incoming" /
            database.lower()
        )

    create_directory(destination_directory)

    source = Path(source_path)

    if source.is_dir():

        output_file = destination_directory

    else:

        output_file = (
            destination_directory /
            output_filename
        )

    force = (
        config.get("FORCE_DOWNLOAD", "false").lower() == "true"
    )

    if output_file.exists() and not force:

        print()
        print("[INFO] Dataset already exists:")
        print(output_file)

        return output_file

    print()
    print("Downloading dataset...")
    print()

    downloader.download(
        config,
        str(output_file)
    )

    print()
    print("[SUCCESS] Dataset downloaded successfully.")
    print(output_file)

    return output_file




def main():

    print_header()

    download_dataset()


if __name__ == "__main__":
    main()