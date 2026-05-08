# FPGA × IoT × Analytics  
### Real-Time Signal Intelligence Pipeline from Hardware to Cloud

A full-stack edge analytics platform that combines FPGA-based signal processing, IoT messaging, and real-time visualization into a unified hardware-to-cloud pipeline.

Designed around Industry 4.0 principles, this project demonstrates how low-level digital hardware can integrate seamlessly with modern edge computing and analytics infrastructure.

---

## 🚀 Overview

This system transforms an FPGA development board into a self-contained edge acquisition platform capable of:

- Capturing biosignal data
- Performing real-time hardware filtering directly on the FPGA
- Streaming processed telemetry through a Python ETL pipeline
- Publishing live data via MQTT
- Visualizing analytics and fault events through Node-RED dashboards

The project bridges:

- **Digital Hardware Design (Verilog/SystemVerilog)**
- **Embedded Communication Protocols**
- **Edge Computing & IoT Infrastructure**
- **Real-Time Data Analytics**

---

## 🏗️ System Architecture

```text
[Biosignal Sensor]
        │
        ▼
[FPGA]
 ├── ADC Interface
 ├── Moving-Average Filter
 └── UART Transmitter
        │
        ▼
[Python Edge Node]
 ├── SQLite Storage
 ├── MQTT Publisher
 └── REST API (Flask)
        │
        ▼
[Node-RED Dashboard]
 ├── Real-Time Visualization
 ├── Fault Detection Alerts
 └── Data Export & Monitoring
```

---

## ⚙️ Core Features

### FPGA Signal Processing

- Custom Verilog pipeline for:
  - ADC sampling
  - Moving-average filtering
  - UART packet framing
- SPI ADC emulation with FIFO buffering
- Simulation-ready SystemVerilog testbench compatible with Verilator
- Modular architecture for multi-channel scalability

### Edge Data Intelligence

- Python ETL pipeline for serial ingestion and preprocessing
- Local persistence using SQLite
- MQTT publishing for distributed analytics workflows
- Real-time statistical anomaly detection using ±3σ thresholds
- REST API for external integrations and monitoring systems

### Industrial IoT Visualization

- Node-RED dashboard with:
  - Live biosignal plotting
  - Fault-state visualization
  - Streaming telemetry updates
- MQTT-based messaging architecture for cloud extensibility
- Real-time monitoring with low-latency updates

### Deployment Flexibility

- Supports both:
  - Hardware deployment (Intel DE10-Lite / MAX10 FPGA)
  - Full software simulation (Verilator)
- Cross-platform development workflow
- Easily extensible to additional sensors and acquisition channels

---

## 📁 Repository Structure

```text
fpga-biosignal-kit/
│
├── fpga/
│   ├── src/
│   │   ├── top_module.sv
│   │   ├── adc_interface.sv
│   │   ├── filter.sv
│   │   └── uart_tx.sv
│   │
│   ├── tb/
│   │   └── tb_top_module.sv
│   │
│   └── docs/
│       └── timing_diagram.png
│
├── python-etl/
│   ├── etl.py
│   ├── visualize.py
│   └── requirements.txt
│
├── node-red/
│   └── flows.json
│
├── api/
│   └── server.py
│
└── README.md
```

---

## 📊 Dashboard Capabilities

After importing `flows.json` into Node-RED and starting the ETL pipeline:

- **Live Biosignal Visualization**  
  Real-time waveform plotting with ~10 Hz refresh rate

- **Fault Detection Alerts**  
  Automatic alert triggering when signal deviation exceeds statistical thresholds

- **Historical Data Logging**  
  Sensor data persisted locally in `biosignal.db` for offline analysis

---

## 🧠 Example Workflow

### 1. Run FPGA Simulation

```bash
verilator --cc fpga/src/top_module.sv \
          --exe fpga/tb/tb_top_module.sv
```

Or deploy directly to supported FPGA hardware.

---

### 2. Start the Python ETL Pipeline

```bash
cd python-etl
python3 etl.py
```

---

### 3. Launch Node-RED Dashboard

```bash
node-red start
```

Import:

```text
node-red/flows.json
```

Then open:

```text
http://localhost:1880/ui
```

---

### 4. Start REST API (Optional)

```bash
cd api
python3 server.py
```

---

## 📈 Performance Metrics

| Metric | Result |
|---|---|
| Sampling Rate | 1 kHz |
| End-to-End Latency | < 200 ms |
| Database Throughput | 100 samples/sec |
| Dashboard Refresh Rate | 10 Hz |
| Fault Detection Method | ±3σ Statistical Analysis |

---

## 🛠️ Technologies Used

### Hardware & Embedded
- Verilog / SystemVerilog
- FPGA Design & Verification
- UART Communication
- SPI Interfaces
- FIFO Buffering

### Software & Analytics
- Python
- SQLite
- MQTT
- Flask
- pandas
- matplotlib

### IoT & Visualization
- Node-RED
- Real-Time Dashboards
- REST APIs
- Edge Analytics

---

## 🎯 Engineering Concepts Demonstrated

- FPGA-based digital signal processing
- Hardware/software co-design
- Embedded communication systems
- Real-time telemetry pipelines
- Industrial IoT architectures
- Edge analytics and anomaly detection
- End-to-end systems integration

---

## 🔮 Future Enhancements

- OPC UA integration for industrial PLC communication
- Multi-channel DMA-based acquisition
- AWS IoT Core / Azure Digital Twins connectivity
- TensorFlow Lite anomaly detection at the edge
- FPGA-based FFT and spectral analysis
- Containerized deployment for edge gateways

---

## 👨‍💻 Author

**Cheuk Fung Keith Chow**  
Computer Engineering — York University

- GitHub: https://github.com/Real-Chuck-Keith-Chow
- Email: rosarollins069@gmail.com

---

## 📄 License

MIT License © 2025 Cheuk Fung Keith Chow
