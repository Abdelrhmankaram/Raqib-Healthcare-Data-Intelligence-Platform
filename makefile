.PHONY: doctor lab doctor2 produce spark-patients spark-admissions spark-lab

doctor:
	docker exec -it spark-notebook bash -c "cd /home/jovyan/work && PYTHONPATH=/home/jovyan/work python consumer/doctor_consumer.py"

lab:
	docker exec -it spark-notebook bash -c "cd /home/jovyan/work && PYTHONPATH=/home/jovyan/work python consumer/lab_consumer.py"

doctor2:
	docker exec -it spark-notebook bash -c "cd /home/jovyan/work && PYTHONPATH=/home/jovyan/work python consumer/second_doctor_consumer.py"

produce:
	docker exec -it spark-notebook bash -c "cd /home/jovyan/work && PYTHONPATH=/home/jovyan/work python producer/receptionist_producer.py"

spark-patients:
	docker exec -it spark-notebook bash -c "cd /home/jovyan/work && PYTHONPATH=/home/jovyan/work spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.3,org.postgresql:postgresql:42.7.1 spark/patientConsumer.py"

spark-admissions:
	docker exec -it spark-notebook bash -c "cd /home/jovyan/work && PYTHONPATH=/home/jovyan/work spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.3,org.postgresql:postgresql:42.7.1 spark/spark_admissions.py"

spark-lab:
	docker exec -it spark-notebook bash -c "cd /home/jovyan/work && PYTHONPATH=/home/jovyan/work spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.3,org.postgresql:postgresql:42.7.1 spark/spark_lab.py"