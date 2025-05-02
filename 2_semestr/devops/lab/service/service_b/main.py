import os
import pika
import json
import psycopg2
import logging
from datetime import datetime

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("service_b")
RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "localhost")
RABBITMQ_PORT = int(os.getenv("RABBITMQ_PORT", 5672))
RABBITMQ_USER = os.getenv("RABBITMQ_USER", "guest")
RABBITMQ_PASSWORD = os.getenv("RABBITMQ_PASSWORD", "guest")

POSTGRES_HOST = os.getenv("POSTGRES_HOST", "localhost")
POSTGRES_PORT = int(os.getenv("POSTGRES_PORT", 5432))
POSTGRES_DB = os.getenv("POSTGRES_DB", "{{ postgres_db }}")
POSTGRES_USER = os.getenv("POSTGRES_USER", "{{ postgres_user }}")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "{{ postgres_password }}")
DB_CONFIG = {
    "dbname": POSTGRES_DB,
    "user": POSTGRES_USER,
    "password": POSTGRES_PASSWORD,
    "host": POSTGRES_HOST,
    "port": str(POSTGRES_PORT),
}


def connect_to_db():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        cursor = conn.cursor()

        # Create table if it doesn't exist
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS timestamps (
                id SERIAL PRIMARY KEY,
                received_timestamp TIMESTAMP NOT NULL,
                message_timestamp TIMESTAMP NOT NULL,
                raw_message TEXT NOT NULL
            )
        """
        )

        logger.info("Database connection established and table verified")
        return conn
    except Exception as e:
        logger.error(f"Database connection error: {e}")
        raise


def save_message_to_db(conn, message):
    try:
        cursor = conn.cursor()
        data = json.loads(message)
        message_timestamp = datetime.fromisoformat(data["timestamp"])
        received_timestamp = datetime.now()

        cursor.execute(
            """
            INSERT INTO timestamps (received_timestamp, message_timestamp, raw_message)
            VALUES (%s, %s, %s)
        """,
            (received_timestamp, message_timestamp, message),
        )

        logger.info(f"Saved message to database: {message}")
    except Exception as e:
        logger.error(f"Error saving message to database: {e}")


def callback(ch, method, properties, body, conn):
    try:
        message = body.decode("utf-8")
        logger.info(f"Received message: {message}")
        save_message_to_db(conn, message)
        ch.basic_ack(delivery_tag=method.delivery_tag)
    except Exception as e:
        logger.error(f"Error processing message: {e}")
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)


def run_service():
    db_conn = connect_to_db()
    try:
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(
                host=RABBITMQ_HOST,
                port=RABBITMQ_PORT,
                virtual_host="/",
                credentials=pika.PlainCredentials("guest", "guest"),
            )
        )
        channel = connection.channel()
        channel.queue_declare(queue="timestamp_queue", durable=True)
        channel.basic_qos(prefetch_count=1)
        channel.basic_consume(
            queue="timestamp_queue",
            on_message_callback=lambda ch, method, properties, body: callback(
                ch, method, properties, body, db_conn
            ),
        )

        logger.info("Service B started. Waiting for messages...")
        channel.start_consuming()
    except KeyboardInterrupt:
        logger.info("Service B shutting down...")
        channel.stop_consuming()
    except Exception as e:
        logger.error(f"Error in Service B: {e}")
    finally:
        if connection.is_open:
            connection.close()
        db_conn.close()
        logger.info("Connections closed")


if __name__ == "__main__":
    run_service()
