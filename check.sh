#!/bin/bash

# Regular Expressions
WRIKE_REGEX="\\(https:\\|\\)//\\(www\\.\\|\\)wrike\\.com/open.htm?id=[[:digit:]]\\+"
AZURE_REGEX="AB#[[:digit:]]\\+"

# Environment Variables (expected to be passed in or available in GitHub Actions)
AZURE_PAT="FC3IF8Ubrg5PBXiFl4v2rjerfsPeq9KfJWQVDDZLbzuIw1ovEOoqJQQJ99BEACAAAAA1kgrNAAASAZDO3waD "
AZURE_ORG_URL="https://dev.azure.com/rapyuta-robotics"
AZURE_PROJECT="Oks"
PR_BODY="Link To Azure Work Item: AB#58921 General PR Checklist:"

# Validate PR Body Contains Wrike or Azure Link
if ! echo "$PR_BODY" | grep -e "$WRIKE_REGEX" -e "$AZURE_REGEX"; then
  echo "::error::Neither a Wrike link nor an Azure code found in the PR body. Please add a Wrike link or an Azure code (AB#<task_number>)."
  exit 1
fi

# Extract Azure Work Item ID
AZURE_ID=$(echo "$PR_BODY" | grep -oE 'AB#[0-9]+' | cut -d'#' -f2)

echo "Azure ID: $AZURE_ID"

# Only proceed if an Azure ID is found
if [ -n "$AZURE_ID" ]; then
  API_URL="${AZURE_ORG_URL}/${AZURE_PROJECT}/_apis/wit/workitems/$AZURE_ID?api-version=7.1"
  RESPONSE=$(curl -s -u ":${AZURE_PAT}" "$API_URL")

  # Check for error in Azure DevOps response
  if echo "$RESPONSE" | jq -e .error > /dev/null; then
    echo "::error::Failed to fetch work item from Azure DevOps:"
    echo "$RESPONSE" | jq -r .error.message
    exit 1
  fi

  # Validate Work Item Type
  WorkItemType=$(echo "$RESPONSE" | jq -r '.fields["System.WorkItemType"]')
  # Print the work item type
  echo "Azure Work Item Type: $WorkItemType"
  if [ "$WorkItemType" = "Issue" ]; then
    echo "::error::Azure Work Item type 'Issue' is not allowed."
    exit 1
  fi
fi

echo "::notice::Valid Wrike or Azure link found in PR body."
