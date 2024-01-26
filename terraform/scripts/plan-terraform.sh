#!/bin/bash

SCRIPTS_DIR="$(dirname "$0")"
. "$SCRIPTS_DIR/common.sh"

terraform plan -var-file="${VAR_DIR}/variables.tfvars" -var="sandbox_prefix=${SANDBOX_PREFIX}"
