from pathlib import Path
import shutil
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from scripts.python.common.config_loader import (
    load_common_config,
    get_project_root
)


def print_header():

    print()
    print("=" * 60)
    print("DATASET EXTRACTION")
    print("=" * 60)


def remove_old_dataset(incoming_path: Path):

    dataset_folders = [
        "mysql",
        "mongodb",
        "mssql",
        "postgresql"
    ]

    for folder in dataset_folders:

        folder_path = incoming_path / folder

        if folder_path.exists():

            print(f"[INFO] Removing {folder_path}")

            shutil.rmtree(folder_path)


def extract_dataset():

    config = load_common_config("dataset")

    project_root = get_project_root()

    archive_file = (
        project_root /
        config["DOWNLOAD_DIRECTORY"] /
        config["DATASET_NAME"]
    )

    if not archive_file.exists():

        raise FileNotFoundError(
            f"Dataset archive not found:\n{archive_file}"
        )

    incoming_path = project_root / "incoming"

    # Skip extraction if dataset already exists
    if (
        dataset_already_extracted(incoming_path)
        and
        config["FORCE_EXTRACT"].lower() != "true"
    ):

        print()
        print("[INFO] Dataset already extracted.")
        print("[INFO] Skipping extraction.")

        return

    # Remove old dataset only when force extract is enabled
    if config["FORCE_EXTRACT"].lower() == "true":

        remove_old_dataset(incoming_path)

    print()
    print("Extracting dataset...")
    print()

    with zipfile.ZipFile(
        archive_file,
        "r"
    ) as zip_ref:

        zip_ref.extractall(incoming_path)

    print("[SUCCESS] Dataset extracted successfully.")

    if config["DELETE_ARCHIVE"].lower() == "true":

        archive_file.unlink()

        print("[INFO] Archive deleted.")

def verify_dataset():

    incoming = get_project_root() / "incoming"

    folders = [
        "mysql",
        "mongodb",
        "mssql",
        "postgresql"
    ]

    print()

    print("=" * 60)
    print("DATASET VERIFICATION")
    print("=" * 60)

    for folder in folders:

        folder_path = incoming / folder

        if folder_path.exists():

            print(f"[OK] {folder}")

        else:

            raise Exception(
                f"{folder} folder not found."
            )

def dataset_already_extracted(incoming_path: Path):

    dataset_folders = [
        "mysql",
        "mongodb",
        "mssql",
        "postgresql"
    ]

    for folder in dataset_folders:

        folder_path = incoming_path / folder

        if not folder_path.exists():
            return False

        if not any(folder_path.iterdir()):
            return False

    return True


def main():

    print_header()

    extract_dataset()

    verify_dataset()


if __name__ == "__main__":

    main()