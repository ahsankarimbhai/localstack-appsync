#!/bin/bash

SCRIPTS_DIR="$(dirname "$0")"
. "$SCRIPTS_DIR/common.sh"

terraform destroy -var-file=${VAR_DIR}/variables.tfvars
