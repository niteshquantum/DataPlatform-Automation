#!/usr/bin/env python3

"""
Change Detector

Compares current file checksums with previously stored metadata.
"""

from metadata_manager import (
    get_file_metadata,
    update_file_metadata
)


def detect_changes(current_checksums):
    """
    Detect changes between current and previous checksums.

    Args:
        current_checksums (dict)

    Returns:
        dict
    """

    results = {}

    for file_name, details in current_checksums.items():

        current_checksum = details["checksum"]

        previous_metadata = get_file_metadata(file_name)

        previous_checksum = previous_metadata.get("checksum")

        if previous_checksum is None:

            status = "NEW"

        elif previous_checksum == current_checksum:

            status = "UNCHANGED"

        else:

            status = "CHANGED"

        results[file_name] = {
            "status": status,
            "checksum": current_checksum
        }
        update_file_metadata(
        file_name,
        {
            "checksum": current_checksum
        }
    )

    return results