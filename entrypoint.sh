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

COMMAND="netlify deploy --build"

if [[ "${NETLIFY_DEPLOY_TO_PROD}" == "true" ]]
then
  COMMAND+=" --prod"
elif [[ -n "${DEPLOY_ALIAS}" ]]
then
  COMMAND+=" --alias ${DEPLOY_ALIAS}"
fi

OUTPUT=$(sh -c "$COMMAND")

# Set outputs
NETLIFY_OUTPUT=$(echo "$OUTPUT")
NETLIFY_PREVIEW_URL=$(echo "$OUTPUT" | grep -Eo '(http|https)://[a-zA-Z0-9./?=_-]*(--)[a-zA-Z0-9./?=_-]*' | tail -1) #Unique key: --
NETLIFY_LOGS_URL=$(echo "$OUTPUT" | grep -Eo '(http|https)://app.netlify.com/[a-zA-Z0-9./?=_-]*' | tail -1) #Unique key: app.netlify.com
NETLIFY_LIVE_URL=$(echo "$OUTPUT" | grep -Eo '(http|https)://[a-zA-Z0-9./?=_-]*' | grep -Eov "netlify.com" | tail -1) #Unique key: don't containr -- and app.netlify.com


echo "NETLIFY_OUTPUT<<EOF" >> $GITHUB_OUTPUT
echo "$NETLIFY_OUTPUT" >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT

echo "NETLIFY_PREVIEW_URL<<EOF" >> $GITHUB_OUTPUT
echo "$NETLIFY_PREVIEW_URL" >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT

echo "NETLIFY_LOGS_URL<<EOF" >> $GITHUB_OUTPUT
echo "$NETLIFY_LOGS_URL" >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT

echo "NETLIFY_LIVE_URL<<EOF" >> $GITHUB_OUTPUT
echo "$NETLIFY_LIVE_URL" >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT
