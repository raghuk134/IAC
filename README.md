# Resume Auto - GitHub Actions CI/CD Pipeline

This project implements a comprehensive CI/CD pipeline using GitHub Actions to deploy a Node.js frontend to AWS S3/CloudFront and a Python backend to AWS Lambda, with infrastructure managed by Terraform.

## Architecture

- **Frontend**: Node.js/React application deployed to S3 with CloudFront CDN
- **Backend**: Python Lambda function with Function URLs for API endpoints
- **Infrastructure**: Managed with Terraform using modular approach
- **CI/CD**: GitHub Actions for automated builds and deployments

## Prerequisites

1. AWS Account with appropriate permissions
2. GitHub repository with the following secrets configured:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

## Project Structure

```
.
├── .github/workflows/
│   └── deploy.yml                 # Main CI/CD pipeline
├── terraform/
│   ├── main.tf                   # Main Terraform configuration
│   ├── variables.tf              # Terraform variables
│   ├── outputs.tf                # Terraform outputs
│   └── modules/
│       ├── s3/                   # S3 module for frontend hosting
│       ├── cloudfront/           # CloudFront module for CDN
│       ├── lambda/               # Lambda module for backend
│       └── api-gateway/          # API Gateway module (optional)
├── frontend/                     # Node.js frontend application
│   ├── src/
│   │   └── fileupload.js        # Updated with Lambda URL
│   └── package.json
├── backend/                      # Python backend application
│   ├── lambda_function.py       # Main Lambda handler
│   └── requirements.txt         # Python dependencies
└── README.md
```

## Setup Instructions

### 1. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

```bash
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
```

### 2. Initialize Terraform Backend

Create an S3 bucket for Terraform state:

```bash
aws s3 mb s3://resume-auto-terraform-state
```

### 3. Deploy Infrastructure

The GitHub Actions workflow will automatically:

1. **Plan and Apply Terraform**: Creates AWS infrastructure
2. **Build Backend**: Packages Python Lambda function
3. **Deploy Backend**: Updates Lambda function code
4. **Build Frontend**: Compiles React application with updated API URL
5. **Deploy Frontend**: Syncs to S3 and invalidates CloudFront

## Features

### GitHub Actions Workflow

- **Multi-environment support**: Separate dev/prod deployments based on branch
- **Terraform integration**: Infrastructure as code with state management
- **Automated API URL updates**: Frontend automatically configured with Lambda URL
- **CloudFront invalidation**: Ensures fresh content delivery
- **Error handling**: Comprehensive error reporting and rollback capabilities

### Infrastructure Components

#### S3 Module
- Static website hosting
- Public read access
- Versioning enabled
- Server-side encryption

#### CloudFront Module
- Global CDN distribution
- HTTPS redirection
- Custom error pages for SPA routing
- Origin Access Control (OAC)

#### Lambda Module
- Python 3.9 runtime
- Function URLs with CORS
- IAM roles and policies
- Environment-specific configurations

### Backend Features

- **File Upload**: Handle resume uploads to S3
- **Text Extraction**: Use AWS Textract for resume parsing
- **Health Checks**: API health monitoring
- **CORS Support**: Cross-origin request handling
- **Error Handling**: Comprehensive error responses

### Frontend Integration

- **Dynamic API Configuration**: Automatically uses deployed Lambda URL
- **File Upload Support**: Multiple upload methods (FormData, Base64)
- **Progress Tracking**: Upload progress callbacks
- **Error Handling**: User-friendly error messages
- **File Validation**: Type and size validation

## Environment Variables

The pipeline automatically manages these environment variables:

- `REACT_APP_API_URL`: Set to Lambda function URL during build
- `ENVIRONMENT`: Deployment environment (dev/prod)

## Deployment Process

1. **Push to repository**: Triggers GitHub Actions workflow
2. **Terraform Plan**: Reviews infrastructure changes
3. **Infrastructure Updates**: Applies necessary AWS resource changes
4. **Backend Deployment**: Packages and deploys Lambda function
5. **Frontend Build**: Compiles with correct API endpoint
6. **Frontend Deployment**: Uploads to S3 and invalidates CloudFront

## Monitoring and Debugging

### CloudWatch Logs
- Lambda function logs available in CloudWatch
- API Gateway logs (if using API Gateway module)

### S3 Access Logs
- CloudFront access logs can be configured for analytics

### Terraform State
- State stored in S3 bucket for team collaboration
- State locking can be added with DynamoDB table

## Customization

### Adding New Routes
Update `lambda_function.py` to handle additional endpoints:

```python
elif path == '/new-endpoint' and http_method == 'POST':
    response_body = handle_new_functionality(body)
```

### Frontend Configuration
Modify `fileupload.js` to add new API methods:

```javascript
async newApiMethod(data) {
    const response = await fetch(`${this.apiBaseUrl}/new-endpoint`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
    return response.json();
}
```

### Infrastructure Changes
Modify Terraform modules to add new AWS resources or update existing ones.

## Cost Optimization

- **S3**: Pay only for storage and requests
- **CloudFront**: Free tier includes 1TB data transfer
- **Lambda**: Free tier includes 1M requests/month
- **Textract**: Pay per document processed

## Security Considerations

- **IAM Roles**: Least privilege access for Lambda functions
- **CORS Configuration**: Restricted to necessary origins in production
- **S3 Bucket Policies**: Public read access only for frontend assets
- **Encryption**: Server-side encryption enabled for S3

## Troubleshooting

### Common Issues

1. **Lambda Timeout**: Increase timeout in `terraform/modules/lambda/main.tf`
2. **CORS Errors**: Verify CORS headers in Lambda function
3. **Build Failures**: Check Node.js/Python versions in workflow
4. **Terraform State Lock**: Manually unlock if needed

### Debug Commands

```bash
# Check Terraform outputs
terraform output

# View Lambda logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/resume-auto

# Test API endpoint
curl -X GET https://your-lambda-url.lambda-url.region.on.aws/health
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test locally
4. Submit a pull request

The CI/CD pipeline will automatically test and deploy approved changes.