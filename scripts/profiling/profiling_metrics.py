"""
Common profiling metric utilities.

This module calculates reusable dataset-level, column-level,
and data-quality metrics for incoming datasets.

The generated metrics are database-independent and support
CSV files as well as MongoDB-style nested JSON datasets.

The profiling output is designed to support future
reconciliation, assessment, recommendation, technical reporting,
and executive reporting modules.
"""

import json
from typing import Any, Dict, List

import pandas as pd


# ============================================================
# HASHABLE DATAFRAME CONVERSION
# ============================================================

def make_dataframe_hashable(
    dataframe: pd.DataFrame,
) -> pd.DataFrame:
    """
    Create a profiling-safe DataFrame copy.

    MongoDB JSON datasets may contain nested dictionaries
    and arrays. Pandas duplicated() and nunique() operations
    cannot directly process unhashable list and dictionary values.

    Nested values are converted into stable JSON strings only
    for metric calculation.

    The original source DataFrame is not modified.
    """

    safe_dataframe = dataframe.copy()

    for column_name in safe_dataframe.columns:

        safe_dataframe[column_name] = (
            safe_dataframe[column_name].apply(
                lambda value: json.dumps(
                    value,
                    sort_keys=True,
                    ensure_ascii=False,
                )
                if isinstance(value, (list, dict))
                else value
            )
        )

    return safe_dataframe


# ============================================================
# BASIC DATASET METRICS
# ============================================================

def calculate_basic_metrics(
    dataframe: pd.DataFrame,
) -> Dict[str, Any]:
    """
    Calculate basic dataset-level profiling metrics.
    """

    safe_dataframe = make_dataframe_hashable(
        dataframe
    )

    total_rows = len(dataframe)

    total_columns = len(
        dataframe.columns
    )

    duplicate_rows = int(
        safe_dataframe.duplicated().sum()
    )

    duplicate_percentage = (
        round(
            (duplicate_rows / total_rows) * 100,
            2,
        )
        if total_rows > 0
        else 0.0
    )

    memory_usage_bytes = int(
        dataframe.memory_usage(
            index=True,
            deep=True,
        ).sum()
    )

    return {
        "total_rows": total_rows,
        "total_columns": total_columns,
        "duplicate_rows": duplicate_rows,
        "duplicate_percentage": duplicate_percentage,
        "memory_usage_bytes": memory_usage_bytes,
    }


# ============================================================
# COLUMN METRICS
# ============================================================

def calculate_column_metrics(
    dataframe: pd.DataFrame,
) -> Dict[str, Any]:
    """
    Calculate detailed column-level profiling metrics.

    Nested MongoDB arrays and dictionaries are converted into
    stable JSON representations before uniqueness calculations.
    """

    safe_dataframe = make_dataframe_hashable(
        dataframe
    )

    column_metrics = {}

    total_rows = len(dataframe)

    for column_name in dataframe.columns:

        original_column = dataframe[
            column_name
        ]

        safe_column = safe_dataframe[
            column_name
        ]

        null_count = int(
            original_column.isnull().sum()
        )

        non_null_count = int(
            original_column.notnull().sum()
        )

        unique_count = int(
            safe_column.nunique(
                dropna=True
            )
        )

        null_percentage = (
            round(
                (null_count / total_rows) * 100,
                2,
            )
            if total_rows > 0
            else 0.0
        )

        uniqueness_percentage = (
            round(
                (
                    unique_count
                    / non_null_count
                )
                * 100,
                2,
            )
            if non_null_count > 0
            else 0.0
        )

        column_metrics[
            str(column_name)
        ] = {
            "detected_data_type": str(
                original_column.dtype
            ),
            "null_count": null_count,
            "null_percentage": (
                null_percentage
            ),
            "non_null_count": (
                non_null_count
            ),
            "unique_value_count": (
                unique_count
            ),
            "uniqueness_percentage": (
                uniqueness_percentage
            ),
        }

    return column_metrics


# ============================================================
# DATA QUALITY SUMMARY
# ============================================================

def calculate_data_quality_summary(
    dataframe: pd.DataFrame,
) -> Dict[str, Any]:
    """
    Generate dataset-level data-quality metrics.
    """

    safe_dataframe = make_dataframe_hashable(
        dataframe
    )

    total_rows = len(dataframe)

    total_cells = int(
        dataframe.size
    )

    total_null_cells = int(
        dataframe.isnull().sum().sum()
    )

    duplicate_rows = int(
        safe_dataframe.duplicated().sum()
    )

    overall_null_percentage = (
        round(
            (
                total_null_cells
                / total_cells
            )
            * 100,
            2,
        )
        if total_cells > 0
        else 0.0
    )

    duplicate_percentage = (
        round(
            (
                duplicate_rows
                / total_rows
            )
            * 100,
            2,
        )
        if total_rows > 0
        else 0.0
    )

    columns_with_nulls = int(
        (
            dataframe.isnull().sum()
            > 0
        ).sum()
    )

    return {
        "total_cells": total_cells,
        "total_null_cells": (
            total_null_cells
        ),
        "overall_null_percentage": (
            overall_null_percentage
        ),
        "duplicate_rows": (
            duplicate_rows
        ),
        "duplicate_percentage": (
            duplicate_percentage
        ),
        "columns_with_nulls": (
            columns_with_nulls
        ),
    }


# ============================================================
# PROFILING ISSUE DETECTION
# ============================================================

def detect_profiling_issues(
    dataframe: pd.DataFrame,
) -> List[Dict[str, Any]]:
    """
    Detect important profiling observations.

    This function does not decide whether migration should
    succeed or fail.

    It identifies data-quality observations for future
    assessment, recommendation, technical reporting,
    and executive reporting modules.
    """

    safe_dataframe = make_dataframe_hashable(
        dataframe
    )

    issues = []

    total_rows = len(dataframe)

    # --------------------------------------------------------
    # EMPTY DATASET
    # --------------------------------------------------------

    if total_rows == 0:

        issues.append(
            {
                "issue_type": (
                    "EMPTY_DATASET"
                ),
                "severity": "HIGH",
                "column": None,
                "message": (
                    "The dataset contains "
                    "no records."
                ),
            }
        )

        return issues

    # --------------------------------------------------------
    # DUPLICATE ROWS
    # --------------------------------------------------------

    duplicate_rows = int(
        safe_dataframe.duplicated().sum()
    )

    if duplicate_rows > 0:

        duplicate_percentage = round(
            (
                duplicate_rows
                / total_rows
            )
            * 100,
            2,
        )

        severity = (
            "HIGH"
            if duplicate_percentage >= 10
            else "MEDIUM"
        )

        issues.append(
            {
                "issue_type": (
                    "DUPLICATE_ROWS"
                ),
                "severity": severity,
                "column": None,
                "affected_records": (
                    duplicate_rows
                ),
                "affected_percentage": (
                    duplicate_percentage
                ),
                "message": (
                    f"{duplicate_rows} "
                    "duplicate records "
                    "were detected."
                ),
            }
        )

    # --------------------------------------------------------
    # COLUMN NULL ANALYSIS
    # --------------------------------------------------------

    for column_name in dataframe.columns:

        column = dataframe[
            column_name
        ]

        null_count = int(
            column.isnull().sum()
        )

        if null_count == 0:
            continue

        null_percentage = round(
            (
                null_count
                / total_rows
            )
            * 100,
            2,
        )

        if null_percentage >= 80:

            severity = "HIGH"

        elif null_percentage >= 30:

            severity = "MEDIUM"

        else:

            severity = "LOW"

        issues.append(
            {
                "issue_type": (
                    "NULL_VALUES"
                ),
                "severity": severity,
                "column": str(
                    column_name
                ),
                "affected_records": (
                    null_count
                ),
                "affected_percentage": (
                    null_percentage
                ),
                "message": (
                    f"Column '{column_name}' "
                    f"contains "
                    f"{null_percentage}% "
                    "null values."
                ),
            }
        )

    # --------------------------------------------------------
    # CONSTANT COLUMN ANALYSIS
    # --------------------------------------------------------

    for column_name in dataframe.columns:

        original_column = dataframe[
            column_name
        ]

        safe_column = safe_dataframe[
            column_name
        ]

        non_null_count = int(
            original_column.notnull().sum()
        )

        unique_count = int(
            safe_column.nunique(
                dropna=True
            )
        )

        if (
            non_null_count > 0
            and unique_count == 1
        ):

            issues.append(
                {
                    "issue_type": (
                        "CONSTANT_COLUMN"
                    ),
                    "severity": "LOW",
                    "column": str(
                        column_name
                    ),
                    "affected_records": (
                        non_null_count
                    ),
                    "message": (
                        f"Column "
                        f"'{column_name}' "
                        "contains only one "
                        "unique non-null value."
                    ),
                }
            )

    return issues


# ============================================================
# PROFILING ISSUE SUMMARY
# ============================================================

def summarize_profiling_issues(
    issues: List[Dict[str, Any]],
) -> Dict[str, int]:
    """
    Generate a severity-based profiling issue summary.
    """

    high_issues = 0
    medium_issues = 0
    low_issues = 0

    for issue in issues:

        severity = issue.get(
            "severity"
        )

        if severity == "HIGH":

            high_issues += 1

        elif severity == "MEDIUM":

            medium_issues += 1

        elif severity == "LOW":

            low_issues += 1

    return {
        "total_issues": len(issues),
        "high_severity_issues": (
            high_issues
        ),
        "medium_severity_issues": (
            medium_issues
        ),
        "low_severity_issues": (
            low_issues
        ),
    }