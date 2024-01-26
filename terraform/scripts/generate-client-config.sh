#!/bin/bash

# Input
TARGET=${1}
CONFIG=${2}
TF_STATE_BUCKET=${3:-sbg-sso-terraform-state}
TF_STATE_BUCKET_AWS_REGION=${4:-us-east-1}

# Locations
DIR=$(dirname "${0}")
TF_DIR=$(cd "${DIR}/.." && pwd)

# Get data from TF
echo "Using target '${TARGET}' to generate '${CONFIG}'..."
TF_OUTPUT=$(${TF_DIR}/scripts/output-terraform.sh ${TARGET} ${TF_STATE_BUCKET} ${TF_STATE_BUCKET_AWS_REGION})

# temporary solution until we find a right way to do it
case "${1}" in
  ci)
    IROH_ISSUER="https://visibility.test.iroh.site"
    IROH_CLIENT_ID="client-172079c8-a2fd-47c6-b946-3ad18f9d890d"
    ;;
  integration)
    IROH_ISSUER="https://visibility.int.iroh.site"
    IROH_CLIENT_ID="client-fcc450b6-d962-4171-9d7b-65379dda0855"
    ;;
  staging)
    IROH_ISSUER="https://visibility.test.iroh.site"
    IROH_CLIENT_ID="client-1afa272d-f563-476e-b373-034cc57f330b"
    ;;
  prod)
    IROH_ISSUER="https://visibility.amp.cisco.com"
    IROH_CLIENT_ID="client-584a5246-0026-46bf-9aa4-39626c825cac"
    ;;
  prodeu)
    IROH_ISSUER="https://visibility.eu.amp.cisco.com"
    IROH_CLIENT_ID="client-11c18fb4-2862-4e20-890a-c98d4a3084c4"
    ;;
  prodapjc)
    IROH_ISSUER="https://visibility.apjc.amp.cisco.com"
    IROH_CLIENT_ID="client-41acb90c-c489-4f71-bbb5-fafa50933ffb"
    ;;
  *)
    # All the rest goes to iroh dev env
    IROH_ISSUER="https://visibility.test.iroh.site"
    IROH_CLIENT_ID="client-49bc1343-d6d5-475f-9b30-e461aa1bb5e1"
    ;;
esac

# Generate configuration file
jq -n \
  --arg graphql "$(echo ${TF_OUTPUT} | jq -r .graphql_endpoint.value)" \
  --arg awsRegion "$(echo ${TF_OUTPUT} | jq -r .aws_region.value)" \
  --arg irohIssuer "${IROH_ISSUER}" \
  --arg irohClientId "${IROH_CLIENT_ID}" \
  '{
    graphql: {
      url: $graphql,
      region: $awsRegion
    },
    iroh: {
      issuer: $irohIssuer,
      clientId: $irohClientId
    },
    basePath: "/assets",
    standalone: true
  }' > ${CONFIG}
