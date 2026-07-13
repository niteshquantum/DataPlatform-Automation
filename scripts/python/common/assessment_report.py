"""Generate a single report from all database assessment inventory files."""

import argparse
import json
from pathlib import Path

from scripts.python.common.assessment import ASSESSMENT_ROOT, ROOT


def generate_report():
    platforms = {}
    for platform_dir in sorted(path for path in ASSESSMENT_ROOT.iterdir() if path.is_dir()) if ASSESSMENT_ROOT.exists() else []:
        inventories = {}
        for inventory_file in sorted(platform_dir.glob("*.json")):
            data = json.loads(inventory_file.read_text(encoding="utf-8"))
            inventories[data["inventory"]] = {
                "record_count": data["record_count"],
                "status": data["status"],
                **({"detail": data["detail"]} if "detail" in data else {}),
            }
        platforms[platform_dir.name] = inventories

    report = {
        "platform_count": len(platforms),
        "inventory_count": sum(len(inventories) for inventories in platforms.values()),
        "platforms": platforms,
    }
    output = ASSESSMENT_ROOT / "assessment_report.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Assessment report: {output.relative_to(ROOT)}")
    return output


if __name__ == "__main__":
    argparse.ArgumentParser(description="Generate the unified assessment report").parse_args()
    generate_report()
