"""Small standard CLI used by database-specific RBAC modules."""
from __future__ import annotations

import argparse


def command_arguments(description: str) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("command", choices=("configure", "validate"))
    parser.add_argument("--skip-validation", action="store_true")
    return parser.parse_args()
