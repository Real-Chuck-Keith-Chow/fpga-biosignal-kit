#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import time
import json
import sqlite3
from collections import deque
from statistics import mean, pstdev

import serial
import paho.mqtt.client as mqtt

# --------------------------- Config ---------------------------------
SERIAL_PORT   = os.getenv("FPGA_SERIAL", "/dev/ttyUSB0")
BAUD_RATE     = int(os.getenv("FPGA_BAUD", "115200"))
MQTT_BROKER   = os.getenv("MQTT_BROKER", "localhost")
MQTT_PORT     = int(os.getenv("MQTT_PORT", "1883"))
MQTT_TOPIC    = os.getenv("MQTT_TOPIC", "factory/signal")
CHANNEL_ID    = int(os.getenv("CHANNEL_ID", "0"))
DB_PATH       = os.path.join(os.path.dirname(__file__), "../data/biosignal.db")
WINDOW_SIZE   = int(os.getenv("ETL_WINDOW", "64"))  # samples for σ/mean
ALPHA         = float(os.getenv("IIR_ALPHA", "0.5"))  # IIR: y = a*y + (1-a)*x
HEADER_BYTE   = 0xA5  # must match top_module framing

# --------------------------- DB Setup --------------------------------
os.makedirs(os.path.dirname(os.path.abspath(DB_PATH)), exist_ok=True)
conn = sqlite3.connect(DB_PATH, check_same_thread=False)
cur  = conn.cursor()
cur.execute("PRAGMA journal_mode=WAL;")
cur.execute("PRAGMA synchronous=NORMAL;")

cur.execute("""
CREATE TABLE IF NOT EXISTS biosignal_data (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    ts          REAL NOT NULL,
    channel     INTEGER NOT NULL,
    raw         INTEGER NOT NULL,
    filtered    REAL NOT NULL,
    mean        REAL NOT NULL,
    sigma       REAL NOT NULL,
    fault       INTEGER NOT NULL
);
""")
cur.execute("CREATE INDEX IF NOT EXISTS idx_bios_ts ON biosignal_data(ts);")
cur.execute("CREATE INDEX IF NOT EXISTS idx_bios_ch ON biosignal_data(channel);")
conn.commit()

def store_sample(ts, ch, raw, filt, mu, sig, fault):
    cur.execute(
        "INSERT INTO biosignal_data (ts, channel, raw, filtered, mean, sigma, fault) "
        "VALUES (?, ?, ?, ?, ?, ?, ?);",
        (ts, ch, int(raw), float(filt), float(mu), float(sig), int(bool(fault)))
    )
    conn.commit()

# --------------------------- MQTT ------------------------------------
mqtt_client = mqtt.Client()
mqtt_client.connect(MQTT_BROKER, MQTT_PORT, 60)
mqtt_client.loop_start()

# --------------------------- Serial ----------------------------------
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)

def read_framed_sample(ser_port) -> int | None:
    """
    Frame: [0xA5][HI][LO]
      - 12-bit sample value is: (HI<<4) | (LO>>4)
      - LO low 4 bits are padding (sent as zeros in HW)
    """
    b = ser_port.read(1)
    if not b:
        return None
    if b[0] != HEADER_BYTE:
        # resync: keep reading until header is found
        ser_port.reset_input_buffer()
        return None
    hi = ser_port.read(1)
    lo = ser_port.read(1)
    if not hi or not lo:
        return None
    sample = ((hi[0] & 0xFF) << 4) | ((lo[0] & 0xF0) >> 4)
    return sample

# --------------------------- ETL Loop --------------------------------
window = deque(maxlen=WINDOW_SIZE)
y_prev = 0.0  # IIR state

print(f"[ETL] Serial={SERIAL_PORT} @ {BAUD_RATE} | MQTT={MQTT_BROKER}:{MQTT_PORT} "
      f"| DB={os.path.abspath(DB_PATH)} | WINDOW={WINDOW_SIZE}")

try:
    while True:
        raw = read_framed_sample(ser)
        if raw is None:
            continue

        # IIR filter
        y = ALPHA * y_prev + (1.0 - ALPHA) * raw
        y_prev = y

        # stats
        window.append(raw)
        mu = mean(window)
        sig = pstdev(window) if len(window) > 1 else 0.0
        fault = (abs(raw - mu) > 3.0 * sig) if sig > 0.0 else False

        ts = time.time()

        # DB store
        store_sample(ts, CHANNEL_ID, raw, y, mu, sig, fault)

        # MQTT publish
        payload = {
            "timestamp": ts,
            "channel": CHANNEL_ID,
            "raw": raw,
            "filtered": y,
            "mean": mu,
            "sigma": sig,
            "fault": bool(fault)
        }
        mqtt_client.publish(MQTT_TOPIC, json.dumps(payload))

        # Optional console trace
        print(json.dumps(payload))

except KeyboardInterrupt:
    print("\n[ETL] Stopping...")
finally:
    try:
        mqtt_client.loop_stop()
    except Exception:
        pass
    try:
        ser.close()
    except Exception:
        pass
    try:
        conn.close()
    except Exception:
        pass
