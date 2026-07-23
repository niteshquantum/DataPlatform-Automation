"""Configuration and safety helpers shared by database RBAC modules."""
from __future__ import annotations

import re
from pathlib import Path

from scripts.python.common.config_loader import load_database_config

ROLES = ("admin", "developer", "qa", "viewer")
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]{0,127}$")


def database_rbac_config(database: str) -> tuple[dict, dict[str, dict[str, str]]]:
    config = load_database_config(database)
    enabled = config.get("RBAC_ENABLED", "true").lower()
    if enabled not in {"true", "false"}:
        raise ValueError("RBAC_ENABLED must be true or false")
    users = {}
    for role in ROLES:
        prefix = f"RBAC_{role.upper()}_"
        username = config.get(prefix + "USERNAME")
        password = config.get(prefix + "PASSWORD")
        if not username or not password:
            raise ValueError(f"Missing {prefix}USERNAME or {prefix}PASSWORD")
        validate_identifier(username, "RBAC username")
        users[role] = {"username": username, "password": password}
    return config, users


def validate_identifier(value: str, label: str = "identifier") -> str:
    if not IDENTIFIER.fullmatch(value):
        raise ValueError(f"Unsafe {label}: {value!r}")
    return value


def project_root() -> Path:
    return Path(__file__).resolve().parents[3]
