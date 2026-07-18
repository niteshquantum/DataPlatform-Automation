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
    print("DATASET EXTRACTION & MERGE")
    print("=" * 60)

def extract_and_merge_zip(archive_file: Path, incoming_path: Path):
    """
    Zip ke andar ke content ko incoming folder me merge karta hai.
    Permission error aane par overwrite karne ke liye purani file delete karne ki koshish karta hai.
    """
    print()
    print("Extracting and merging dataset...")
    print()

    with zipfile.ZipFile(archive_file, "r") as zip_ref:
        for member in zip_ref.infolist():
            target_path = incoming_path / member.filename
            
            if member.is_dir():
                target_path.mkdir(parents=True, exist_ok=True)
                continue
                
            target_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Agar file pehle se maujood hai aur locked/permission issue hai
            if target_path.exists():
                try:
                    target_path.unlink() # Purani file ko pehle delete karne ki koshish karein
                except PermissionError:
                    print(f"[WARNING] Cannot delete/overwrite {target_path}. Trying to force write...")

            try:
                with zip_ref.open(member) as source, open(target_path, "wb") as target:
                    shutil.copyfileobj(source, target)
            except PermissionError as e:
                print(f"[ERROR] Permission Denied for file: {target_path}")
                print("Tip: Jenkins workspace folders ke permissions `chmod -R 775` se sahi karein.")
                raise e
                
    print("[SUCCESS] Dataset extracted and merged successfully.")


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
    incoming_path.mkdir(parents=True, exist_ok=True)

    # Zip ke andar kaunse folders hain unhe scan karein
    with zipfile.ZipFile(archive_file, "r") as zip_ref:
        # Zip ke top-level folders nikalne ke liye
        zip_top_folders = {Path(p).parts[0] for p in zip_ref.namelist() if '/' in p}

    # Check karein kya zip ke saare folders already extracted aur non-empty hain
    already_exists = True
    for folder in zip_top_folders:
        folder_path = incoming_path / folder
        if not folder_path.exists() or not any(folder_path.iterdir()):
            already_exists = False
            break

    # Skip extraction agar sab pehle se maujood hai aur FORCE_EXTRACT true nahi hai
    if already_exists and config["FORCE_EXTRACT"].lower() != "true":
        print()
        print("[INFO] All folders from ZIP already exist in incoming.")
        print("[INFO] Skipping extraction.")
        return

    # Extract aur merge process chalayein
    extract_and_merge_zip(archive_file, incoming_path)

    if config["DELETE_ARCHIVE"].lower() == "true":
        archive_file.unlink()
        print("[INFO] Archive deleted.")


def verify_dataset():
    """
    Ab ye zip ke hisab se dynamically verify karega ki jo zip me tha 
    wo incoming folder me aaya ya nahi.
    """
    config = load_common_config("dataset")
    project_root = get_project_root()
    incoming = project_root / "incoming"
    
    archive_file = (
        project_root /
        config["DOWNLOAD_DIRECTORY"] /
        config["DATASET_NAME"]
    )

    print()
    print("=" * 60)
    print("DATASET VERIFICATION")
    print("=" * 60)

    # Agar archive delete ho chuka hai toh sirf check karein ki incoming khali na ho
    if not archive_file.exists():
        if incoming.exists() and any(incoming.iterdir()):
            print("[OK] Incoming folder has data (Archive already deleted).")
            return
        else:
            raise Exception("Incoming folder is empty.")

    # Zip ke mutabik folders check karein
    with zipfile.ZipFile(archive_file, "r") as zip_ref:
        zip_top_folders = {Path(p).parts[0] for p in zip_ref.namelist() if '/' in p}

    for folder in zip_top_folders:
        folder_path = incoming / folder
        if folder_path.exists():
            print(f"[OK] Verified folder: {folder}")
        else:
            raise Exception(f"Verification failed: {folder} folder not found.")


def main():
    print_header()
    extract_dataset()
    verify_dataset()


if __name__ == "__main__":
    main()
