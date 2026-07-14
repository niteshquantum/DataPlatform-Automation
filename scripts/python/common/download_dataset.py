from pathlib import Path
import sys

import gdown

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from scripts.python.common.config_loader import (
    load_common_config,
    get_project_root
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

    download_directory = (
        project_root /
        config["DOWNLOAD_DIRECTORY"]
    )

    create_directory(download_directory)

    output_file = (
        download_directory /
        config["DATASET_NAME"]
    )

    if (
        output_file.exists()
        and
        config["FORCE_DOWNLOAD"].lower() != "true"
    ):
        print()
        print(f"[INFO] Dataset already exists:")
        print(output_file)
        return output_file

    print()
    print("Downloading dataset...")
    print()

    gdown.download(
        config["DATASET_URL"],
        str(output_file),
        quiet=False
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