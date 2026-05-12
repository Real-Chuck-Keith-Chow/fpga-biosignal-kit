from pathlib import Path

import sqlite3
import numpy as np
from flask import Flask, jsonify

BASE_DIR = Path(__file__).resolve().parent.parent
DB_PATH = BASE_DIR / "data" / "biosignal.db"

app = Flask(__name__)


def query_db(sql, params=()):
    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        return conn.execute(sql, params).fetchall()


@app.get("/api/latest")
def latest():
    rows = query_db("""
        SELECT ts, value, mean, sigma, fault
        FROM biosignal
        ORDER BY ts DESC
        LIMIT 1
    """)

    if not rows:
        return jsonify(error="No data found"), 404

    row = rows[0]

    return jsonify({
        "timestamp": row["ts"],
        "value": row["value"],
        "mean": row["mean"],
        "sigma": row["sigma"],
        "fault": bool(row["fault"])
    })


@app.get("/api/stats")
def stats():
    rows = query_db("""
        SELECT value
        FROM biosignal
        ORDER BY ts DESC
        LIMIT 200
    """)

    values = [row["value"] for row in rows]

    return jsonify({
        "count": len(values),
        "mean": float(np.mean(values)) if values else 0.0,
        "stddev": float(np.std(values)) if values else 0.0,
        "min": int(np.min(values)) if values else 0,
        "max": int(np.max(values)) if values else 0
    })


@app.get("/api/recent")
def recent():
    rows = query_db("""
        SELECT ts, value, fault
        FROM biosignal
        ORDER BY ts DESC
        LIMIT 100
    """)

    return jsonify([
        {
            "timestamp": row["ts"],
            "value": row["value"],
            "fault": bool(row["fault"])
        }
        for row in rows
    ])


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
