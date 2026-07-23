"""Consistent, secret-safe logging for database RBAC automation."""
from __future__ import annotations

import logging
import sys


def get_rbac_logger(database: str) -> logging.Logger:
    logger = logging.getLogger(f"rbac.{database}")
    if logger.handlers:
        return logger
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter(
        "%(asctime)s %(levelname)s [%(name)s] %(message)s",
        "%Y-%m-%dT%H:%M:%S%z",
    ))
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    logger.propagate = False
    return logger
