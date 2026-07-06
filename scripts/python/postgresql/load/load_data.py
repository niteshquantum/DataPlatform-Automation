"""
load_data.py - Entry point for Jenkins 'Load Data' stage.
Delegates to load_all.py which handles dataset generation + loading.
"""
import sys
from load_all import load_all


if __name__ == "__main__":
    try:
        load_all()
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)
