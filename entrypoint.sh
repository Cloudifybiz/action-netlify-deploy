#!/bin/bash

set -e

# Deploy to Netlify
export NETLIFY_SITE_ID="${NETLIFY_SITE_ID}"
export NETLIFY_AUTH_TOKEN="${NETLIFY_AUTH_TOKEN}"
export WORKING_DIRECTORY="${WORKING_DIRECTORY}"

cd "$WORKING_DIRECTORY"

# Run install command
if [[ -f yarn.lock ]]
then
  yarn
elif [[ -f pnpm-lock.yaml ]]
then
  pnpm i
else
  npm i
fi

CONTEXT="branch-deploy"

# Get contex for env:list
if [[ "${NETLIFY_DEPLOY_TO_PROD}" == "true" ]]
then
  CONTEXT="production"
fi

# Save netlify json env variables to a variable
if [[ -n "${NETLIFY_SITE_ID}" ]]
then
  export $(netlify env:list --json --context ${CONTEXT} | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]")
fi

COMMAND="netlify deploy --build"

if [[ "${NETLIFY_DEPLOY_TO_PROD}" == "true" ]]
then
  COMMAND+=" --prod"
elif [[ -n "${DEPLOY_ALIAS}" ]]
then
  COMMAND+=" --alias ${DEPLOY_ALIAS}"
fi

exec 5>&1
OUTPUT=$(sh -c "$COMMAND" | tee >(cat - >&5))

function get_output() {
   echo "$OUTPUT" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" | grep -Po "(?<=$1:)\s*(http|https)://[a-zA-Z0-9./?=_-]*" | tail -1 | xargs
}

# Set outputs
NETLIFY_OUTPUT=$(echo "$OUTPUT")
NETLIFY_PREVIEW_URL=$(get_output "Website Draft URL")
NETLIFY_LOGS_URL=$(get_output "Logs")
NETLIFY_LIVE_URL=$(get_output "Website URL")


if [[ -z "${NETLIFY_PREVIEW_URL}" && -z "${NETLIFY_LIVE_URL}" ]]
then
  echo "Failed to deploy to Netlify"
  exit 1
fi

echo "NETLIFY_OUTPUT=$(echo $NETLIFY_OUTPUT)" >> $GITHUB_OUTPUT

echo "NETLIFY_PREVIEW_URL=$(echo $NETLIFY_PREVIEW_URL)" >> $GITHUB_OUTPUT

echo "NETLIFY_LOGS_URL=$(echo $NETLIFY_LOGS_URL)" >> $GITHUB_OUTPUT

echo "NETLIFY_LIVE_URL=$(echo $NETLIFY_LIVE_URL)" >> $GITHUB_OUTPUT
