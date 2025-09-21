# lambda_function.py
import awsgi2
from mfa_server import app

def lambda_handler(event, context):
    """
    AWS Lambda handler that serves the Flask application ('app') via awsgi2.

    This function acts as the entry point for the AWS Lambda runtime, translating
    the Lambda invocation event into a standard WSGI request that the Flask
    application can understand.
    """
    return awsgi2.response(app, event, context)
