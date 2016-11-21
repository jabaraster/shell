#!/bin/sh
curl https://a.wunderlist.com/api/v1/lists -X GET \
  -H "Content-Type: application/json" \
  -H "X-Client-ID: $CLIENT_ID" \
  -H "X-Access-Token: $ACCESS_TOKEN" \
  -d "{\"title\": \"${1}\"}"
