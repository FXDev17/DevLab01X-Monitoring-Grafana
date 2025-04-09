import json
import time
import boto3
import os
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.boto3 import patch_all
from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.metrics import MetricUnit

# Initialize tooling
logger = Logger(service="observability-api")
metrics = Metrics(namespace="ObservabilityAPI")
tracer = Tracer(service="observability-api")
patch_all()  # Enable X-Ray for all boto3 clients

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.getenv('DYNAMODB_TABLE'))

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

        # Endpoint-specific logic
        if path.endswith('/ping'):
            return handle_ping(request_id)
        elif path.endswith('/fail'):
            return handle_fail(request_id)
        else:
            raise ValueError(f"Unsupported path: {path}")

    except Exception as e:
        logger.error("Request failed", error=str(e), path=path)
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
            'ttl': int(time.time() + 604800)  # 7-day TTL
        })
        
        metrics.add_metric(name="Latency", unit=MetricUnit.Milliseconds, value=latency_ms)
        metrics.add_metric(name="SuccessRequests", unit=MetricUnit.Count, value=1)
        metrics.add_dimension(name="Path", value="/ping")
        
        return success_response(request_id, latency_ms)

def handle_fail(request_id):
    """Process /fail endpoint requests"""
    with xray_recorder.capture('handle_fail'):
        # Simulate processing time even for failures
        measure_latency()
        
        table.put_item(Item={
            'request_id': request_id,
            'path': '/fail',
            'status': 'failed',
            'timestamp': int(time.time()),
            'ttl': int(time.time() + 604800)
        })
        
        metrics.add_metric(name="FailureRequests", unit=MetricUnit.Count, value=1)
        metrics.add_dimension(name="Path", value="/fail")
        
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