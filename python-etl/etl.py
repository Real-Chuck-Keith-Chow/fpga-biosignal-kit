import serial
import sqlite3
import time
import json
import paho.mqtt.client as mqtt
from statistics import mean, pstdev

DB_PATH = "biosignal.db"
MQTT_BROKER = "localhost"
MQTT_TOPIC = "factory/signal"
SERIAL_PORT = "/dev/ttyUSB0"
BAUD_RATE = 115200

# ---------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------
conn = sqlite3.connect(DB_PATH, check_same_thread=False)
c = conn.cursor()
c.execute("""CREATE TABLE IF NOT EXISTS biosignal (
    ts REAL,
    value REAL
)""")
conn.commit()

ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
mqtt_client = mqtt.Client()
mqtt_client.connect(MQTT_BROKER, 1883, 60)
mqtt_client.loop_start()

window = []

# ---------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------
while True:
    try:
        line = ser.readline().decode(errors="ignore").strip()
        if not line:
            continue
        if not line.isdigit():
            continue

        value = int(line)
        ts = time.time()
        window.append(value)
        if len(window) > 50:
            window.pop(0)

        c.execute("INSERT INTO biosignal VALUES (?, ?)", (ts, value))
        conn.commit()

        avg = mean(window)
        sigma = pstdev(window) if len(window) > 1 else 0
        fault = abs(value - avg) > 3 * sigma if sigma > 0 else False

        payload = {
            "timestamp": ts,
            "value": value,
            "mean": avg,
            "sigma": sigma,
            "fault": fault
        }

        mqtt_client.publish(MQTT_TOPIC, json.dumps(payload))
        print(json.dumps(payload))

    except KeyboardInterrupt:
        print("Exiting...")
        break
    except Exception as e:
        print("Error:", e)
        time.sleep(0.1)

mqtt_client.loop_stop()
conn.close()
ser.close()
