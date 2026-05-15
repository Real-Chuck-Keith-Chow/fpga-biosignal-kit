#!/usr/bin/env python3

import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent.parent / "data" / "biosignal.db"


def main():
    if not DB_PATH.exists():
        print(f"No database found at: {DB_PATH}")
        return

    with sqlite3.connect(DB_PATH) as conn:
        rows = conn.execute("""
            SELECT ts, value, mean, sigma, fault
            FROM biosignal
            ORDER BY ts DESC
            LIMIT 20
        """).fetchall()

    if not rows:
        print("No samples found.")
        return

    print("\nLast 20 Samples")
    print("-" * 72)

    for ts, value, mu, sigma, fault in reversed(rows):
        status = "FAULT" if fault else "OK"
        print(
            f"{ts:.2f} | value={value:4d} | "
            f"mean={mu:8.2f} | sigma={sigma:7.2f} | {status}"
        )


if __name__ == "__main__":
    main()
