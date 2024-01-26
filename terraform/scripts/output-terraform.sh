#!/bin/bash

SCRIPTS_DIR="$(dirname "$0")"
. "$SCRIPTS_DIR/common.sh"

#remove debug output if exists
TF_OUTPUT=`terraform output -json`
TF_OUTPUT=`echo $TF_OUTPUT | sed 's/.*-json//' | sed 's/} } }.*/} } }/'`
echo $TF_OUTPUT
