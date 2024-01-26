#!/bin/bash

SCRIPTS_DIR="$(dirname "$0")"
. "$SCRIPTS_DIR/common.sh"

terraform apply ${AUTO_APPROVE:+-auto-approve} -var-file="${VAR_DIR}/variables.tfvars" -var="sandbox_prefix=${SANDBOX_PREFIX}"
