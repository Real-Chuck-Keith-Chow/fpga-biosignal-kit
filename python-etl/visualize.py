import sqlite3
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

DB_PATH = "biosignal.db"

# ---------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------
conn = sqlite3.connect(DB_PATH)
df = pd.read_sql_query("SELECT * FROM biosignal ORDER BY ts ASC", conn)
conn.close()

if df.empty:
    print("No data found in database.")
    exit()

# ---------------------------------------------------------------------
# Compute statistics
# ---------------------------------------------------------------------
values = df["value"].to_numpy()
mean_val = np.mean(values)
sigma_val = np.std(values)
upper = mean_val + 3 * sigma_val
lower = mean_val - 3 * sigma_val

# ---------------------------------------------------------------------
# Plot
# ---------------------------------------------------------------------
plt.figure(figsize=(10, 5))
plt.plot(df["ts"], df["value"], label="Signal", linewidth=1)
plt.axhline(mean_val, color="green", linestyle="--", label="Mean")
plt.axhline(upper, color="red", linestyle="--", label="+3σ Threshold")
plt.axhline(lower, color="red", linestyle="--", label="-3σ Threshold")
plt.title("FPGA Biosignal Trend")
plt.xlabel("Timestamp (s)")
plt.ylabel("ADC Value")
plt.legend(loc="upper right")
plt.grid(True)
plt.tight_layout()
plt.show()
