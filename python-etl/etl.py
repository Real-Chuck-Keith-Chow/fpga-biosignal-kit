#!/usr/bin/env python3

import os
import json
import time
import sqlite3
from collections import deque
from statistics import mean, pstdev

import serial
import paho.mqtt.client as mqtt

SERIAL_PORT = os.getenv("FPGA_SERIAL", "/dev/ttyUSB0")
BAUD_RATE   = 115200

MQTT_TOPIC  = "factory/signal"
MQTT_HOST   = "localhost"

DB_PATH     = "../data/biosignal.db"

HEADER      = 0xA5
WINDOW_SIZE = 64

# -------------------------------------------------------------------

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

cur.execute("""
CREATE TABLE IF NOT EXISTS biosignal (
    ts REAL,
    value INTEGER,
    mean REAL,
    sigma REAL,
    fault INTEGER
)
""")

mqtt_client = mqtt.Client()
mqtt_client.connect(MQTT_HOST, 1883, 60)

ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)

window = deque(maxlen=WINDOW_SIZE)

# -------------------------------------------------------------------

def read_sample():
    if ser.read(1) != bytes([HEADER]):
        return None

    hi = ser.read(1)
    lo = ser.read(1)

    if not hi or not lo:
        return None

    return (hi[0] << 4) | (lo[0] >> 4)

# -------------------------------------------------------------------

print(f"[ETL] Listening on {SERIAL_PORT}")

try:
    while True:
        sample = read_sample()

        if sample is None:
            continue

        window.append(sample)

        mu = mean(window)
        sigma = pstdev(window) if len(window) > 1 else 0

        fault = abs(sample - mu) > (3 * sigma) if sigma else False

        payload = {
            "timestamp": time.time(),
            "value": sample,
            "mean": mu,
            "sigma": sigma,
            "fault": fault
        }

        cur.execute(
            "INSERT INTO biosignal VALUES (?, ?, ?, ?, ?)",
            (
                payload["timestamp"],
                sample,
                mu,
                sigma,
                int(fault)
            )
        )

        conn.commit()

        mqtt_client.publish(
            MQTT_TOPIC,
            json.dumps(payload)
        )

        print(json.dumps(payload))

except KeyboardInterrupt:
    print("\nStopping...")

finally:
    ser.close()
    conn.close()
