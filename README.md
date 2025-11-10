🧠 Smart Edge Biosignal Data Platform

FPGA × IoT × Analytics — a full-stack hardware-to-cloud data pipeline for real-time signal intelligence

🚀 Overview

This project transforms an FPGA board into a self-contained edge data acquisition system that captures biosignals, cleans them in hardware, and streams the processed data through a Python ETL + Node-RED pipeline for real-time analytics and fault detection.

Built to demonstrate the principles of Industry 4.0, digital manufacturing, and smart sensor connectivity, this system bridges Verilog hardware design with IoT-level intelligence.

🏗️ Architecture
[Biosignal Sensor]
      │
      ▼
[FPGA: ADC Interface + Filter + UART TX]
      │
      ▼
[Python Edge Node]
 ├── SQLite Local DB
 ├── MQTT Publisher
 └── REST API (Flask)
      │
      ▼
[Node-RED Dashboard]
 ├── Real-Time Graphs
 ├── Fault Alerts
 └── Machine Data Export

⚙️ Features

✅ FPGA-Level Data Processing

Custom Verilog pipeline: ADC sampling → moving-average filter → UART framing

Realistic SPI ADC emulation + FIFO buffering for smooth flow

Simulation-ready testbench (tb_top_module.sv) for Verilator

✅ Edge Data Intelligence

Python ETL reads serial stream, logs to SQLite, publishes to MQTT

Live ±3σ statistical fault detection (predictive-maintenance style)

REST API for external dashboards or CMMS integration

✅ Industrial Visualization

Node-RED dashboard with real-time biosignal plots and red-alert indicator

MQTT broker for modular expansion to cloud analytics

✅ Cross-Platform Ready

Works in simulation (Verilator) or on hardware (DE10-Lite / MAX10)

Designed for scalability — add more channels or sensors easily

🧩 Repo Structure
fpga-biosignal-kit/
│
├── fpga/
│   ├── src/
│   │   ├── top_module.sv
│   │   ├── adc_interface.sv
│   │   ├── filter.sv
│   │   └── uart_tx.sv
│   ├── tb/tb_top_module.sv
│   └── docs/timing_diagram.png
│
├── python-etl/
│   ├── etl.py
│   ├── visualize.py
│   └── requirements.txt
│
├── node-red/flows.json
├── api/server.py
└── README.md

📈 Dashboard Preview

(Once you import flows.json into Node-RED and run the ETL script)

🧩 Live Biosignal Chart — 10 Hz refresh

⚡ Fault Detector — turns red when deviation > 3σ

📊 Local Data Log — stored in biosignal.db for later analysis

🧠 Example Workflow
# 1️⃣ Run the FPGA simulation or program your board
verilator --cc fpga/src/top_module.sv --exe fpga/tb/tb_top_module.sv

# 2️⃣ Start the ETL pipeline
cd python-etl
python3 etl.py

# 3️⃣ Launch the dashboard
node-red start
# Import node-red/flows.json and open http://localhost:1880/ui

# 4️⃣ Start REST API (optional)
cd api
python3 server.py

📊 Results
Metric	Result
Sampling rate	1 kHz
End-to-end latency	< 200 ms
Mean detection accuracy	± 2σ
Database throughput	100 samples / sec
Dashboard update rate	10 Hz
🧮 Skills Demonstrated

FPGA Design & Verification (Verilog, testbenching, timing)

Embedded Systems (UART, SPI, filtering, FIFO)

Industrial IoT & Edge Computing (MQTT, Node-RED, SQLite)

Data Analytics (Python, pandas, matplotlib)

System Integration (REST API, real-time dashboards)

🔮 Future Enhancements

OPC UA connector for PLC integration (Allen-Bradley / Siemens)

Multi-channel ADC acquisition with DMA

Integration with AWS IoT Core / Azure Digital Twins

On-device ML model for anomaly detection (TensorFlow Lite)

👨‍💻 Author

Cheuk Fung Keith Chow
Computer Engineering @ York University
🔗 GitHub
 · ✉️ rosarollins069@gmail.com

🏁 License

MIT License © 2025 Real-Chuck-Keith-Chow
