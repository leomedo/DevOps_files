#!/bin/bash

if [[ -z "$FRAPPE_SITE_NAME_HEADER" ]]; then
    export FRAPPE_SITE_NAME_HEADER=\$host
fi

if [[ -z "$PROXY_READ_TIMEOUT" ]]; then
    export PROXY_READ_TIMEOUT=120
fi

if [[ -z "$CLIENT_MAX_BODY_SIZE" ]]; then
    export CLIENT_MAX_BODY_SIZE=50m
fi

envsubst '${BACKEND} ${SOCKETIO} ${FRAPPE_SITE_NAME_HEADER} ${PROXY_READ_TIMEOUT} ${CLIENT_MAX_BODY_SIZE}' \
    < /templates/nginx/frappe.conf.template \
    > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
