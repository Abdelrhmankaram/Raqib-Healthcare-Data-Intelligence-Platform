.PHONY: start stop restart receptionist doctor second-doctor lab patient status check-dwh

SPARK_CONTAINER := spark-notebook
WORKDIR := /home/jovyan/work

# ─── Infrastructure ───────────────────────────────────────────────────────────

install:
	docker exec $(SPARK_CONTAINER) pip install -r $(WORKDIR)/requirements.txt --break-system-packages
	
up:
	@echo "Infrastructure already running. Starting stream processors..."
	docker exec -d $(SPARK_CONTAINER) spark-submit \
		$(WORKDIR)/spark/patientConsumer.py
	docker exec -d $(SPARK_CONTAINER) spark-submit \
		$(WORKDIR)/spark/spark_admissions.py
	docker exec -d $(SPARK_CONTAINER) spark-submit \
		$(WORKDIR)/spark/spark_lab.py
	docker exec -d $(SPARK_CONTAINER) python3 -u \
		$(WORKDIR)/consumer/second_doctor_consumer.py
	docker exec -d $(SPARK_CONTAINER) python3 -u \
		$(WORKDIR)/consumer/lab_consumer.py
	@echo ""
	@echo "   Consumers running!"
	@echo "   Run 'make receptionist' in terminal 1"
	@echo "   Run 'make doctor'       in terminal 2"

start:
	@echo "Starting infrastructure..."
	docker compose up -d
	@echo "Waiting for Kafka brokers..."
	@until docker exec broker-1 kafka-broker-api-versions \
		--bootstrap-server localhost:9092 > /dev/null 2>&1; do \
		echo "  brokers not ready, retrying..."; sleep 5; done
	@echo "Brokers ready. Starting automated consumers..."
	docker exec -d $(SPARK_CONTAINER) spark-submit \
		$(WORKDIR)/spark/patientConsumer.py
	docker exec -d $(SPARK_CONTAINER) spark-submit \
		$(WORKDIR)/spark/spark_admissions.py
	docker exec -d $(SPARK_CONTAINER) spark-submit \
		$(WORKDIR)/spark/spark_lab.py
	docker exec -d $(SPARK_CONTAINER) python3 -u \
		$(WORKDIR)/consumer/second_doctor_consumer.py
	docker exec -d $(SPARK_CONTAINER) python3 -u \
		$(WORKDIR)/consumer/lab_consumer.py
	@echo ""
	@echo "   Pipeline running!"
	@echo "   Run 'make receptionist' in terminal 1 — register patients"
	@echo "   Run 'make doctor'       in terminal 2 — doctor input"

stop:
	docker compose down

restart: stop start

# ─── Interactive Services (need human input) ──────────────────────────────────

receptionist:
	docker exec -it $(SPARK_CONTAINER) python3 -u \
		$(WORKDIR)/producer/receptionist_producer.py

doctor:
	docker exec -it $(SPARK_CONTAINER) python3 -u \
		$(WORKDIR)/consumer/doctor_consumer.py

# ─── Manual overrides (run detached if needed) ────────────────────────────────

second-doctor:
	docker exec -it $(SPARK_CONTAINER) python3 -u \
		$(WORKDIR)/consumer/second_doctor_consumer.py

lab:
	docker exec -it $(SPARK_CONTAINER) python3 -u \
		$(WORKDIR)/consumer/lab_consumer.py

patient:
	docker exec -it $(SPARK_CONTAINER) spark-submit \
		$(WORKDIR)/spark/patientConsumer.py

# ─── Monitoring ───────────────────────────────────────────────────────────────

status:
	docker compose ps

check-dwh:
	docker exec -it dwh psql -U kafka_admin -d kafka_dwh -c \
		"SELECT COUNT(*) FROM admissions;" -c \
		"SELECT COUNT(*) FROM diagnosis;"