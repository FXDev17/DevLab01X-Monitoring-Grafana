import json
import time
import boto3
import os
import random
import logging
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.boto3 import patch_all
from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.metrics import MetricUnit
from loguru import logger
from grafana_loki import LokiHandler
import requests  # For sending logs to Loki

# Initialize tooling
patch_all()  # Enable X-Ray for all boto3 clients
logger = Logger(service="observability-api")
metrics = Metrics(namespace="ObservabilityAPI")
tracer = Tracer(service="observability-api")

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.getenv('DYNAMODB_TABLE'))

# Loki Handler for Powertools Logger
class LokiHandler(logging.Handler):
    def __init__(self, loki_url, api_key, labels):
        super().__init__()
        self.loki_url = loki_url
        self.headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
        self.labels = labels

    def emit(self, record):
        try:
            log_entry = self.format(record)
            timestamp = int(time.time() * 1_000_000_000)  # Nanoseconds
            payload = {
                "streams": [
                    {
                        "stream": self.labels,
                        "values": [[str(timestamp), log_entry]]
                    }
                ]
            }
            requests.post(self.loki_url, headers=self.headers, json=payload)
        except Exception as e:
            print(f"Failed to send log to Loki: {e}")

# Loki handler Configurations 
loki_handler = LokiHandler(
    loki_url=os.getenv('LOKI_ENDPOINT', 'https://logs-prod-us-central1.grafana.net/loki/api/v1/push'),
    api_key=os.getenv('LOKI_API_KEY'),
    labels={"application": "api_funct", "environment": "prod", "service": "observability-api"}
)
loki_handler.setLevel(logging.INFO)
logger.logger.addHandler(loki_handler)

@tracer.capture_lambda_handler
@logger.inject_lambda_context(log_event=True)
@metrics.log_metrics
def lambda_handler(event, context):
    try:
        # Parse API Gateway event
        path = event.get('path', '')
        http_method = event.get('httpMethod', 'GET')
        request_id = context.aws_request_id
        tracer.put_annotation("path", path)
        tracer.put_annotation("method", http_method)
        tracer.put_annotation("request_id", request_id)  # Add for trace-log correlation

        # Log with trace ID for correlation
        logger.info(f"Processing request for path: {path}", extra={"trace_id": request_id})

        # Endpoint-specific logic
        if path.endswith('/ping'):
            return handle_ping(request_id)
        elif path.endswith('/fail'):
            return handle_fail(request_id)
        else:
            raise ValueError(f"Unsupported path: {path}")

    except Exception as e:
        logger.error("Request failed", extra={"error": str(e), "path": path, "trace_id": request_id})
        metrics.add_metric(name="Errors", unit=MetricUnit.Count, value=1)
        metrics.add_dimension(name="Path", value=path)
        return error_response(e, request_id)

def handle_ping(request_id):
    """Process /ping endpoint requests"""
    with xray_recorder.capture('handle_ping'):
        latency_ms = measure_latency()
        
        table.put_item(Item={
            'request_id': request_id,
            'path': '/ping',
            'status': 'success',
            'latency': latency_ms,
            'timestamp': int(time.time()),
            'expires_at': int(time.time() + 604800)  # 7-day TTL (use expires_at for DynamoDB TTL)
        })
        
        metrics.add_metric(name="Latency", unit=MetricUnit.Milliseconds, value=latency_ms)
        metrics.add_metric(name="SuccessRequests", unit=MetricUnit.Count, value=1)
        metrics.add_dimension(name="Path", value="/ping")
        
        logger.info("Ping request processed successfully", extra={"trace_id": request_id, "latency_ms": latency_ms})
        
        return success_response(request_id, latency_ms)

def handle_fail(request_id):
    """Process /fail endpoint requests"""
    with xray_recorder.capture('handle_fail'):
        # Simulate processing time even for failures
        latency_ms = measure_latency()
        
        table.put_item(Item={
            'request_id': request_id,
            'path': '/fail',
            'status': 'failed',
            'timestamp': int(time.time()),
            'expires_at': int(time.time() + 604800)  # 7-day TTL
        })
        
        metrics.add_metric(name="FailureRequests", unit=MetricUnit.Count, value=1)
        metrics.add_dimension(name="Path", value="/fail")
        
        logger.error("Simulated failure", extra={"trace_id": request_id})
        
        raise Exception("Simulated failure as requested")

def measure_latency():
    """Simulate processing latency"""
    start = time.time()
    time.sleep(random.uniform(0.01, 0.1))  # Random delay between 10-100ms
    return (time.time() - start) * 1000

def success_response(request_id, latency):
    return {
        'statusCode': 200,
        'body': json.dumps({
            'status': 'success',
            'request_id': request_id,
            'latency_ms': round(latency, 2),
            'timestamp': int(time.time())
        }),
        'headers': {
            'Content-Type': 'application/json',
            'X-Request-ID': request_id
        }
    }

def error_response(error, request_id):
    return {
        'statusCode': 500,
        'body': json.dumps({
            'status': 'error',
            'request_id': request_id,
            'error_type': error.__class__.__name__,
            'message': str(error),
            'timestamp': int(time.time())
        }),
        'headers': {
            'Content-Type': 'application/json',
            'X-Request-ID': request_id
        }
    }