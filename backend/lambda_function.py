import json
import boto3
import base64
from typing import Dict, Any

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda function handler for resume-auto backend
    """
    
    # CORS headers
    cors_headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With'
    }
    
    try:
        # Handle preflight OPTIONS request
        if event.get('httpMethod') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': cors_headers,
                'body': ''
            }
        
        # Extract HTTP method and path
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '/')
        
        # Parse request body
        body = {}
        if event.get('body'):
            if event.get('isBase64Encoded', False):
                decoded_body = base64.b64decode(event['body']).decode('utf-8')
                body = json.loads(decoded_body)
            else:
                body = json.loads(event['body'])
        
        # Route handling
        if path == '/health' and http_method == 'GET':
            response_body = {'status': 'healthy', 'message': 'Resume Auto Backend is running'}
            
        elif path == '/upload' and http_method == 'POST':
            response_body = handle_file_upload(body, event)
            
        elif path == '/process' and http_method == 'POST':
            response_body = handle_resume_processing(body)
            
        else:
            response_body = {'error': 'Route not found', 'path': path, 'method': http_method}
            return {
                'statusCode': 404,
                'headers': cors_headers,
                'body': json.dumps(response_body)
            }
        
        return {
            'statusCode': 200,
            'headers': {
                **cors_headers,
                'Content-Type': 'application/json'
            },
            'body': json.dumps(response_body)
        }
        
    except Exception as e:
        error_response = {
            'error': str(e),
            'message': 'Internal server error occurred'
        }
        
        return {
            'statusCode': 500,
            'headers': cors_headers,
            'body': json.dumps(error_response)
        }

def handle_file_upload(body: Dict[str, Any], event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle file upload functionality
    """
    try:
        # Extract file data from request
        file_data = body.get('file')
        file_name = body.get('fileName', 'resume.pdf')
        
        if not file_data:
            return {'error': 'No file data provided'}
        
        # Initialize S3 client
        s3_client = boto3.client('s3')
        bucket_name = f"resume-auto-uploads-{get_environment()}"
        
        # Upload file to S3
        try:
            # Decode base64 file data if needed
            if isinstance(file_data, str):
                file_content = base64.b64decode(file_data)
            else:
                file_content = file_data
            
            s3_client.put_object(
                Bucket=bucket_name,
                Key=f"uploads/{file_name}",
                Body=file_content,
                ContentType='application/pdf'
            )
            
            return {
                'message': 'File uploaded successfully',
                'fileName': file_name,
                'key': f"uploads/{file_name}"
            }
            
        except Exception as e:
            return {'error': f'Failed to upload file: {str(e)}'}
            
    except Exception as e:
        return {'error': f'File upload error: {str(e)}'}

def handle_resume_processing(body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle resume processing functionality
    """
    try:
        file_key = body.get('fileKey')
        processing_type = body.get('processingType', 'extract')
        
        if not file_key:
            return {'error': 'File key is required'}
        
        # Initialize AWS services
        s3_client = boto3.client('s3')
        textract_client = boto3.client('textract')
        
        bucket_name = f"resume-auto-uploads-{get_environment()}"
        
        # Process the resume based on type
        if processing_type == 'extract':
            # Use Textract to extract text from resume
            response = textract_client.detect_document_text(
                Document={
                    'S3Object': {
                        'Bucket': bucket_name,
                        'Name': file_key
                    }
                }
            )
            
            # Extract text from Textract response
            extracted_text = ""
            for item in response['Blocks']:
                if item['BlockType'] == 'LINE':
                    extracted_text += item['Text'] + '\n'
            
            return {
                'message': 'Resume processed successfully',
                'extractedText': extracted_text,
                'processingType': processing_type
            }
        
        elif processing_type == 'analyze':
            # Add resume analysis logic here
            return {
                'message': 'Resume analysis completed',
                'analysis': {
                    'skills': ['Python', 'AWS', 'Machine Learning'],
                    'experience': '3+ years',
                    'education': 'Bachelor\'s Degree'
                }
            }
        
        else:
            return {'error': f'Unknown processing type: {processing_type}'}
            
    except Exception as e:
        return {'error': f'Resume processing error: {str(e)}'}

def get_environment() -> str:
    """
    Get the current environment from environment variables
    """
    import os
    return os.environ.get('ENVIRONMENT', 'dev')