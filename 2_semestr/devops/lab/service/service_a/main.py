import os
import pika
import time
import datetime
import json
import logging

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("service_a")
RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "localhost")
RABBITMQ_PORT = int(os.getenv("RABBITMQ_PORT", 5672))
RABBITMQ_USER = os.getenv("RABBITMQ_USER", "guest")
RABBITMQ_PASSWORD = os.getenv("RABBITMQ_PASSWORD", "guest")


def connect_to_rabbitmq():
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

        # Declare the queue
        channel.queue_declare(queue="timestamp_queue", durable=True)

        return connection, channel
    except Exception as e:
        logger.error(f"Failed to connect to RabbitMQ: {e}")
        raise


def run_service():
    connection, channel = connect_to_rabbitmq()
    logger.info("Service A started. Publishing timestamps every 10 seconds...")

    try:
        while True:
            timestamp = datetime.datetime.now().isoformat()
            message = json.dumps({"timestamp": timestamp})

            channel.basic_publish(
                exchange="",
                routing_key="timestamp_queue",
                body=message,
                properties=pika.BasicProperties(
                    delivery_mode=2,
                    content_type="application/json",
                ),
            )

            logger.info(f"Published message: {message}")
            time.sleep(10)
    except KeyboardInterrupt:
        logger.info("Service A shutting down...")
    except Exception as e:
        logger.error(f"Error in Service A: {e}")
    finally:
        connection.close()
        logger.info("Connection to RabbitMQ closed")


if __name__ == "__main__":
    run_service()
