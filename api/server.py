from flask import Flask, jsonify
import sqlite3
import numpy as np

DB_PATH = "../python-etl/biosignal.db"

app = Flask(__name__)

def get_latest_record():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT ts, value FROM biosignal ORDER BY ts DESC LIMIT 1")
    row = c.fetchone()
    conn.close()
    return row

def get_stats():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT value FROM biosignal ORDER BY ts DESC LIMIT 200")
    data = [r[0] for r in c.fetchall()]
    conn.close()
    if not data:
        return {"mean": 0, "stddev": 0, "count": 0}
    return {
        "mean": float(np.mean(data)),
        "stddev": float(np.std(data)),
        "count": len(data)
    }

@app.route("/api/latest", methods=["GET"])
def latest():
    row = get_latest_record()
    if row:
        return jsonify({"timestamp": row[0], "value": row[1]})
    return jsonify({"error": "no data"})

@app.route("/api/stats", methods=["GET"])
def stats():
    return jsonify(get_stats())

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
