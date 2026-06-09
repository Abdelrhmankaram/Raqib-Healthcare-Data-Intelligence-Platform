# Raqib — Hospital Streaming Data Pipeline

An end-to-end hospital data pipeline built on a 3-broker Kafka cluster, with real-time Spark Streaming, a Snowflake data warehouse, dbt transformations, Airflow orchestration, and a RAG chatbot for querying patient data.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Environment Variables](#environment-variables)
- [Getting Started](#getting-started)
- [Kafka Pipeline — Run Order](#kafka-pipeline--run-order)
- [Airflow DAG](#airflow-dag)
- [dbt Transformations](#dbt-transformations)
- [RAG Chatbot](#rag-chatbot)
- [Monitoring](#monitoring)
- [Service Ports](#service-ports)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         STREAMING LAYER                             │
│                                                                     │
│  Receptionist Producer                                              │
│       │                                                             │
│       ▼  patients-topic                                             │
│  Doctor Consumer ──────────────────────────────────────────────┐   │
│       │  Path A: admissions-topic    Path B: transfers-topic    │   │
│       │                              Path C: lab-results-topic  │   │
│       ▼                                    │                    │   │
│  2nd Doctor Consumer               Lab Consumer                 │   │
│  (handles transfers)               (fills results)              │   │
│       │                                    │                    │   │
│       └────────────┬───────────────────────┘                    │   │
│                    ▼                                             │   │
│             Spark Streaming                                      │   │
│         (patientConsumer, spark_admissions, spark_lab)           │   │
│                    │                                             │   │
│                    ▼                                             │   │
│              PostgreSQL DWH                                      │   │
└────────────────────┬────────────────────────────────────────────┘   │
                     │                                                 │
┌────────────────────▼────────────────────────────────────────────┐   │
│                      BATCH / WAREHOUSE LAYER                    │   │
│                                                                 │   │
│  Airflow DAG: kafka_to_s3                                       │   │
│      │  Reads DWH → uploads Parquet to S3                       │   │
│      ▼                                                          │   │
│  Snowflake (raw tables via COPY INTO)                           │   │
│      │                                                          │   │
│      ▼                                                          │   │
│  dbt (raqib_sf): staging → intermediate → marts (dim/fact)     │   │
│      │                                                          │   │
│      ▼                                                          │   │
│  Power BI Dashboard  +  RAG Chatbot (Streamlit + Ollama)        │   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
Raqib/
├── docker-compose.yml          # Full infrastructure (Kafka, Spark, Postgres, Airflow, monitoring)
├── makefile                    # Shortcuts for running pipeline components
├── pyproject.toml              # Python project config (dbt + Snowflake deps)
├── .env                        # Environment secrets (not committed)
│
├── ITI/                        # Kafka streaming pipeline
│   ├── config/
│   │   └── config.py           # Broker addresses, topic names, producer/consumer defaults
│   ├── data/
│   │   └── data.py             # Sample patient seed data
│   ├── model/
│   │   └── models.py           # Pydantic models: Patient, Admission, Diagnosis, etc.
│   ├── producer/
│   │   └── receptionist_producer.py   # Produces patients to patients-topic
│   ├── consumer/
│   │   ├── doctor_consumer.py         # Routes patients (admit / transfer / lab)
│   │   ├── second_doctor_consumer.py  # Handles transfer patients
│   │   └── lab_consumer.py            # Fills and publishes lab results
│   ├── spark/
│   │   ├── patientConsumer.py         # Spark job: patients → Postgres
│   │   ├── spark_admissions.py        # Spark job: admissions → Postgres
│   │   └── spark_lab.py               # Spark job: lab results → Postgres
│   └── requirements.txt
│
├── Dags/
│   └── kafka_to_s3.py          # Airflow DAG: DWH → S3 Parquet → Snowflake
│
├── raqib_sf_dbt/               # dbt project targeting Snowflake
│   └── models/
│       ├── staging/            # stg_patients, stg_admissions, stg_lab_events, etc.
│       ├── history/            # int_patients_360, int_clinical_events, int_lab_analysis, etc.
│       └── marts/
│           ├── dim/            # dim_patients, dim_provider, dim_date, dim_diagnosis, etc.
│           └── fact/           # fact_encounters, fact_lab_results, fact_transfers, etc.
│
├── RAG/                        # Streamlit + Ollama RAG chatbot
│   ├── App.py
│   ├── config.py
│   ├── constants.py
│   ├── rag.py
│   ├── snowflake.py
│   └── README.md
│
├── Dashboard/
│   └── Raqib - Dashboard.pbix  # Power BI dashboard
│
├── monitoring/
│   └── prometheus.yml          # Prometheus scrape config
│
└── src/
    ├── clean_drugs.py          # Drug data cleaning scripts
    ├── clean_drugs_v2.py
    ├── download_drugs.py
    └── extract_drugs.py
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Message Broker | Apache Kafka (Confluent Platform 7.6.3), KRaft mode, 3 brokers |
| Schema Management | Confluent Schema Registry |
| Stream Processing | Apache Spark 3.5.3 (PySpark), Structured Streaming |
| Python Kafka Client | `confluent-kafka` 2.4.0 |
| Source Database | PostgreSQL (logical replication enabled) |
| Data Warehouse | Snowflake |
| Object Storage | AWS S3 (Parquet, partitioned by date) |
| Orchestration | Apache Airflow 2.9.0 |
| Transformations | dbt-core + dbt-snowflake |
| RAG Chatbot | Streamlit + Ollama (llama3 / nomic-embed-text) |
| BI Dashboard | Power BI |
| Monitoring | Prometheus + Grafana + kafka-exporter + postgres-exporter |
| Infra | Docker Compose, YAML anchors for DRY config |

---

## Prerequisites

- Docker and Docker Compose
- Python 3.10–3.13
- `uv` (for managing Python deps) or `pip`
- AWS credentials with S3 access
- Snowflake account
- Ollama running locally (for the RAG chatbot)

---

## Environment Variables

Create a `.env` file in the project root with the following:

```env
# Source Postgres
DATABASE_HOSTNAME_SOURCE=postgres
DATABASE_PORT=5432
DATABASE_USER_SOURCE=your_source_user
DATABASE_PASSWORD_SOURCE=your_source_password
DATABASE_DB_NAME_SOURCE=your_source_db

# DWH Postgres
DATABASE_USER_DESTINATION=kafka_admin
DATABASE_PASSWORD_DESTINATION=kafka_admin_password
DATABASE_DB_NAME_DESTINATION=kafka_dwh

# pgAdmin
PGADMIN_EMAIL=admin@admin.com
PGADMIN_PASSWORD=admin

# AWS
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
S3_BUCKET_NAME=raqib-streaming-pipeline-raw-bucket

# Snowflake
SNOWFLAKE_USER=your_user
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_WAREHOUSE=your_warehouse
SNOWFLAKE_DATABASE=your_database
SNOWFLAKE_SCHEMA=your_schema
```

---

## Getting Started

**1. Start the infrastructure:**

```bash
docker compose up -d
```

Wait for all 3 brokers to pass their healthchecks before proceeding (~60 seconds). You can watch this with:

```bash
docker compose ps
```

**2. Run the pipeline in order** (see next section).

---

## Kafka Pipeline — Run Order

Components must be started in this order so consumers are ready before the producer fires.

```bash
# 1. Start Doctor consumer (routes patients to admission, transfer, or lab)
make doctor

# 2. Start Lab consumer (receives lab requests, fills results)
make lab

# 3. Start second Doctor consumer (handles transfer patients)
make doctor2

# 4. Start Spark Streaming jobs (write to Postgres DWH)
make spark-patients
make spark-admissions
make spark-lab

# 5. Fire the producer last — this kicks off the whole pipeline
make produce
```

All `make` targets run inside the `spark-notebook` container via `docker exec`.

### Kafka Topics

| Topic | Producer | Consumer |
|---|---|---|
| `patients-topic` | Receptionist | Doctor consumer |
| `admissions-topic` | Doctor (Path A) | Spark (spark_admissions) |
| `transfers-topic` | Doctor (Path B) | 2nd Doctor consumer |
| `lab-results-topic` | Doctor (Path C) + Lab consumer | Spark (spark_lab) |

All topics are created with 3 partitions and replication factor 3. Patients are keyed by `patient_id` for consistent partition routing.

### Doctor Routing Logic

Each patient is routed to one of three paths:

- **Path A — Direct Admission:** Doctor fills `Admission`, `Diagnosis`, and `Prescriptions` and publishes to `admissions-topic`.
- **Path B — Transfer:** Doctor fills `Service` + `TransferEvent` and publishes to `transfers-topic`. The 2nd Doctor consumer handles it.
- **Path C — Lab Required:** Doctor sends a `LAB_REQUEST` event to `lab-results-topic`. The Lab consumer fills results and publishes a `LAB_RESULT` event back to the same topic for Spark to consume.

---

## Airflow DAG

The `kafka_to_s3` DAG runs daily and performs:

1. Reads each hospital table from the DWH Postgres (`SELECT * WHERE created_at::date = today`)
2. Serializes to Parquet and uploads to S3 at `s3://raqib-streaming-pipeline-raw-bucket/hospital/{table}/date={YYYY-MM-DD}/`
3. Loads from S3 into Snowflake via `COPY INTO`

Airflow is accessible at **http://localhost:8080**.

---

## dbt Transformations

The `raqib_sf_dbt` project models the Snowflake warehouse in three layers:

**Staging** (`models/staging/`) — light cleaning and type casting on raw Snowflake tables:
`stg_patients`, `stg_admissions`, `stg_lab_events`, `stg_diagnosis`, `stg_providers`, `stg_prescriptions`, `stg_transfers`, `stg_services`, `stg_emergency_contacts`, `stg_drugs`, `stg_lab_specimen_types`

**Intermediate / History** (`models/history/`) — business logic joins:
`int_patients_360`, `int_clinical_events`, `int_encounters`, `int_lab_analysis`

**Marts** (`models/marts/`) — dimensional model ready for BI:

*Dimensions:* `dim_patients`, `dim_provider`, `dim_diagnosis`, `dim_date`, `dim_time`, `dim_location`, `dim_admission_type`, `dim_lab_types`, `dim_services`

*Facts:* `fact_encounters`, `fact_lab_results`, `fact_transfers`, `fact_clinical_events`, `fact_patient_finances`, `fact_patient_services`, `fact_providers_performance`

**Run dbt:**

```bash
# install deps
uv sync   # or: pip install -r requirements.txt

# run all models
dbt run

# run tests
dbt test
```

---

## RAG Chatbot

A Streamlit app (`RAG/`) that supports two modes:

- **Document Upload** — upload any document and ask questions about it using a local Ollama LLM.
- **Snowflake Patient Query** — query the Snowflake warehouse directly using natural language.

**Models used (via Ollama):**
- Chat: `llama3`
- Embeddings: `nomic-embed-text`

See [`RAG/README.md`](RAG/README.md) and [`RAG/SETUP.md`](RAG/SETUP.md) for setup instructions.

---

## Monitoring

Prometheus scrapes metrics from:
- **kafka-exporter** (`:9308`) — consumer lag, topic offsets, partition counts
- **postgres-exporter** (`:9187`) — DWH table sizes, row counts, connections

Grafana dashboards are auto-provisioned from `monitoring/grafana/provisioning/` on startup.

---

## Service Ports

| Service | Port |
|---|---|
| Kafka Broker 1 | 9092 |
| Kafka Broker 2 | 9093 |
| Kafka Broker 3 | 9094 |
| Schema Registry | 8081 |
| Kafka Connect 1 | 8083 |
| Kafka Connect 2 | 8084 |
| Kafka UI | 8090 |
| Source Postgres | 5433 |
| DWH Postgres | 5434 |
| pgAdmin | 5050 |
| Spark Notebook | 8888 |
| Spark UI | 4040 |
| Airflow | 8080 |
| SQLMesh | 8000 |
| Prometheus | 9090 |
| Grafana | 3000 |
| Kafka Exporter | 9308 |
| Postgres Exporter | 9187 |
