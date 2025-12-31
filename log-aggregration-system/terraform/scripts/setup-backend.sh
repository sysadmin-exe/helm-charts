#!/bin/bash
set -euo pipefail

REGION="${1:-us-east-1}"
ACCOUNT_ID="${2:-}"

if [ -z "$ACCOUNT_ID" ]; then
  echo "Error: AWS Account ID is required"
  echo "Usage: $0 <region> <account-id>"
  echo "Example: $0 us-east-1 123456789012"
  exit 1
fi

echo "🔧 Setting up Terraform backend in region: $REGION"

ENVIRONMENTS=("dev" "staging" "prod")
DYNAMODB_TABLE="log-aggregation-terraform-locks"

echo ""
echo "📦 Creating S3 buckets..."

for env in "${ENVIRONMENTS[@]}"; do
  BUCKET_NAME="log-aggregation-terraform-state-${env}"
  
  echo "  Creating bucket: $BUCKET_NAME"
  
  if aws s3 ls "s3://${BUCKET_NAME}" --region "$REGION" 2>/dev/null; then
    echo "    ✓ Bucket already exists"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" \
      $([ "$REGION" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=$REGION" || echo "") \
      2>/dev/null && echo "    ✓ Bucket created" || echo "    ✓ Bucket already exists"
  fi
  
  echo "  Enabling versioning..."
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled \
    --region "$REGION"
  echo "    ✓ Versioning enabled"
  
  echo "  Enabling default encryption..."
  aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
      "Rules": [
        {
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          },
          "BucketKeyEnabled": true
        }
      ]
    }' \
    --region "$REGION"
  echo "    ✓ Encryption enabled (AES-256)"
  
  echo "  Blocking public access..."
  aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region "$REGION"
  echo "    ✓ Public access blocked"
done

echo ""
echo "🔒 Creating DynamoDB table for state locking..."

TABLE_EXISTS=$(aws dynamodb describe-table \
  --table-name "$DYNAMODB_TABLE" \
  --region "$REGION" 2>/dev/null || echo "")

if [ -n "$TABLE_EXISTS" ]; then
  echo "  ✓ DynamoDB table already exists"
else
  echo "  Creating table: $DYNAMODB_TABLE"
  aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION" \
    --sse-specification Enabled=true,SSEType=KMS \
    --tags Key=Environment,Value=terraform Key=ManagedBy,Value=terraform-backend-setup \
    2>/dev/null && echo "  ✓ DynamoDB table created with KMS encryption" || echo "  ✓ Table already exists"
  
  echo "  Waiting for table to be active..."
  aws dynamodb wait table-exists \
    --table-name "$DYNAMODB_TABLE" \
    --region "$REGION"
  echo "  ✓ Table is active"
fi

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "Configuration summary:"
echo "  Region:              $REGION"
echo "  DynamoDB Table:      $DYNAMODB_TABLE"
echo ""
echo "S3 Buckets:"
for env in "${ENVIRONMENTS[@]}"; do
  echo "  - log-aggregation-terraform-state-${env}"
done

echo ""
echo "📝 Next steps:"
echo "  1. From each environment directory, run:"
echo "     cd terraform/envs/<env>"
echo "     terraform init"
echo "     terraform plan"
echo "     terraform apply"
