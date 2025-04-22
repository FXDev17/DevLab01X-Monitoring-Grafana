#!/bin/bash

echo "📦 Packaging Lambda..."
cd infra/LAMBDA/lambda_function_payload || exit 1
./package_lambda.sh || exit 1

echo "🚀 Running Terraform..."
cd ../../..
terraform init || exit 1
terraform plan -out=tfplan || exit 1
terraform apply tfplan || exit 1