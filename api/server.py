from flask import Flask, jsonify
import sqlite3
import numpy as np

DB_PATH = "../python-etl/biosignal.db"

app = Flask(__name__)


def query_db(sql):
    with sqlite3.connect(DB_PATH) as conn:
        return conn.execute(sql).fetchall()


@app.get("/api/latest")
def latest():
    rows = query_db(
        "SELECT ts, value FROM biosignal ORDER BY ts DESC LIMIT 1"
    )

    if not rows:
        return jsonify(error="No data found"), 404

    ts, value = rows[0]
    return jsonify(timestamp=ts, value=value)


@app.get("/api/stats")
def stats():
    rows = query_db(
        "SELECT value FROM biosignal ORDER BY ts DESC LIMIT 200"
    )

    values = [row[0] for row in rows]

    return jsonify({
        "mean": float(np.mean(values)) if values else 0,
        "stddev": float(np.std(values)) if values else 0,
        "count": len(values)
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
