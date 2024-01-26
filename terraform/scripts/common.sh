#!/bin/bash

PROJECT_NAME=${1:-$USER}
TF_STATE_BUCKET=${2:-sbg-sso-terraform-state}
TF_STATE_BUCKET_AWS_REGION=${3:-us-east-1}

if [[ "$PROJECT_NAME" == "dev" ]]; then
    PROJECT_NAME=$USER
fi

TERRAFORM_DIR=`echo "$(dirname "$0")" | sed 's/\/scripts//'`
ENVIRONMENTS_DIR="environments"

SANDBOX_PREFIX="${PROJECT_NAME}-"
VAR_DIR="${ENVIRONMENTS_DIR}/dev"

if [[ "$PROJECT_NAME" == "ci" || "$PROJECT_NAME" == "integration" || "$PROJECT_NAME" == "staging" || "$PROJECT_NAME" == "prod" || "$PROJECT_NAME" == "prodeu" || "$PROJECT_NAME" == "prodapjc" ]]; then
    SANDBOX_PREFIX=""
    VAR_DIR="${ENVIRONMENTS_DIR}/$PROJECT_NAME"
fi

if [[ ! -f "${TERRAFORM_DIR}/${VAR_DIR}/variables.tfvars" ]]; then
    echo "terraform variable file ${TERRAFORM_DIR}/${VAR_DIR}/variables.tfvars does not exist"
    exit 1
fi

cd "$TERRAFORM_DIR"
terraform init -reconfigure -backend-config="bucket=${TF_STATE_BUCKET}" -backend-config="key=posaas/${PROJECT_NAME}/terraform.tfstate" -backend-config="region=${TF_STATE_BUCKET_AWS_REGION}" 1> /dev/null
