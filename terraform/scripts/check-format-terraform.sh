#!/bin/bash

SCRIPTS_DIR="$(dirname "$0")"
. "$SCRIPTS_DIR/common.sh"

terraform fmt -check -recursive -diff
