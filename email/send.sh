#!/bin/bash

# exit on error
set -e

# check env vars
SECRETS_DIR=/secrets
if [ -z "$SECRETS_DIR" ]; then
    echo "ERROR: No SECRETS_DIR env var set"
    exit 1
fi

# check arguments
if [ $# -ne 1 ]; then
    echo "Usage: email/send.sh email_json"
    exit 1
fi
EMAIL_JSON="$1"

# create json-parsing function
get_field() {
    CMD=$(echo \
        "import json; " \
        "print(json.loads(" \
            "open('$SECRETS_DIR/titans-email-token', 'r').read()" \
        ")['$1'])" \
    )
    python -c "$CMD"
}

# load secrets
. $SECRETS_DIR/titans-email-creds

# create curl data body
DATA=$(echo \
    "client_id=$CLIENT_ID" \
    "&client_secret=$CLIENT_SECRET" \
    "&scope=offline_access%20mail.send" \
    "&refresh_token=$(get_field refresh_token)" \
    "&grant_type=refresh_token" \
)

# curl for new token
curl -sH "Content-Type: application/x-www-form-urlencoded" \
    -d "$DATA" https://login.microsoftonline.com/$TENANT/oauth2/v2.0/token \
> $SECRETS_DIR/titans-email-token

# send email with new token
curl -sX POST \
    -H "Authorization: Bearer $(get_field access_token)" \
    -H "Content-type: application/json" \
    -H "Host: graph.microsoft.com" \
    -d "$EMAIL_JSON" \
    https://graph.microsoft.com/v1.0/me/sendMail
