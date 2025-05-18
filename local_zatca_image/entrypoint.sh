#!/bin/bash
set -e

cd /home/frappe/frappe-bench

# Remove old assets in volume so they don't override new ones
rm -rf ./sites/assets/*

bench build --production
# bench migrate
bench --site all clear-cache
bench --site all clear-website-cache

exec gunicorn \
  --chdir sites \
  --bind=0.0.0.0:8000 \
  --threads=4 \
  --workers=2 \
  --worker-class=gthread \
  --worker-tmp-dir=/dev/shm \
  --timeout=120 \
  --preload \
  frappe.app:application
