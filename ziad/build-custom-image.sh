#!/bin/bash

# This script builds a custom Frappe Docker image with your specific apps

# 1. Create apps.json file
echo "Creating apps.json file..."
cat > apps.json << 'EOF'
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },
  {
    "url": "https://ghp_Vvyj@github.com/readerorg/ERPNext-Zatca.git",
    "branch": "main"
  }
]
EOF

# 2. Base64 encode the apps.json file
APPS_JSON_BASE64=$(cat apps.json | base64 -w 0)
echo "APPS_JSON_BASE64 generated."

# 3. Create a temporary Dockerfile if not exists
if [ ! -f "Dockerfile" ]; then
  echo "Creating a temporary Dockerfile..."
  cat > Dockerfile << 'EOF'
ARG PYTHON_VERSION=3.11.6
ARG DEBIAN_BASE=bookworm
FROM python:${PYTHON_VERSION}-slim-${DEBIAN_BASE} AS base

COPY resources/nginx-template.conf /templates/nginx/frappe.conf.template
COPY resources/nginx-entrypoint.sh /usr/local/bin/nginx-entrypoint.sh

ARG WKHTMLTOPDF_VERSION=0.12.6.1-3
ARG WKHTMLTOPDF_DISTRO=bookworm
ARG NODE_VERSION=18.18.2
ENV NVM_DIR=/home/frappe/.nvm
ENV PATH=${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/:${PATH}

RUN useradd -ms /bin/bash frappe \
    && apt-get update \
    && apt-get install --no-install-recommends -y \ 
    curl \
    git \
    vim \
    nginx \
    gettext-base \
    file \
    # weasyprint dependencies
    libpango-1.0-0 \
    libharfbuzz0b \
    libpangoft2-1.0-0 \
    libpangocairo-1.0-0 \
    # For backups
    restic \
    gpg \
    # MariaDB
    mariadb-client \
    less \
    # Postgres
    libpq-dev \
    postgresql-client \
    # For healthcheck
    wait-for-it \
    jq \
    ghostscript \
    # NodeJS
    && mkdir -p ${NVM_DIR} \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash \
    && . ${NVM_DIR}/nvm.sh \
    && nvm install ${NODE_VERSION} \
    && nvm use v${NODE_VERSION} \
    && npm install -g yarn \
    && nvm alias default v${NODE_VERSION} \
    && rm -rf ${NVM_DIR}/.cache \
    && echo 'export NVM_DIR="/home/frappe/.nvm"' >>/home/frappe/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >>/home/frappe/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >>/home/frappe/.bashrc \
    # Install wkhtmltopdf with patched qt
    && if [ "$(uname -m)" = "aarch64" ]; then export ARCH=arm64; fi \
    && if [ "$(uname -m)" = "x86_64" ]; then export ARCH=amd64; fi \
    && downloaded_file=wkhtmltox_${WKHTMLTOPDF_VERSION}.${WKHTMLTOPDF_DISTRO}_${ARCH}.deb \
    && curl -sLO https://github.com/wkhtmltopdf/packaging/releases/download/$WKHTMLTOPDF_VERSION/$downloaded_file \
    && apt-get install -y ./$downloaded_file \
    && rm $downloaded_file \
    # Clean up
    && rm -rf /var/lib/apt/lists/* \
    && rm -fr /etc/nginx/sites-enabled/default \
    # install python-dotenv
    && pip3 install frappe-bench python-dotenv \
    # install pikepdf
    && pip3 install pikepdf \
    # Fixes for non-root nginx and logs to stdout
    && sed -i '/user www-data/d' /etc/nginx/nginx.conf \
    && ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log \
    && touch /run/nginx.pid \
    && chown -R frappe:frappe /etc/nginx/conf.d \
    && chown -R frappe:frappe /etc/nginx/nginx.conf \
    && chown -R frappe:frappe /var/log/nginx \
    && chown -R frappe:frappe /var/lib/nginx \
    && chown -R frappe:frappe /run/nginx.pid \
    && chmod 755 /usr/local/bin/nginx-entrypoint.sh \
    && chmod 644 /templates/nginx/frappe.conf.template

FROM base AS builder

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    # For frappe framework
    wget \
    #for building arm64 binaries
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    # For psycopg2
    libpq-dev \
    # Other
    libffi-dev \
    liblcms2-dev \
    libldap2-dev \
    libmariadb-dev \
    libsasl2-dev \
    libtiff5-dev \
    libwebp-dev \
    redis-tools \
    rlwrap \
    tk8.6-dev \
    cron \
    # For pandas
    gcc \
    build-essential \
    libbz2-dev \
    && rm -rf /var/lib/apt/lists/*

# apps.json includes
ARG APPS_JSON_BASE64
RUN if [ -n "${APPS_JSON_BASE64}" ]; then \
    mkdir /opt/frappe && echo "${APPS_JSON_BASE64}" | base64 -d > /opt/frappe/apps.json; \
  fi

  
  USER frappe
  
  ARG FRAPPE_BRANCH=version-15
  ARG FRAPPE_PATH=https://github.com/frappe/frappe
  RUN export APP_INSTALL_ARGS="" && \
  if [ -n "${APPS_JSON_BASE64}" ]; then \
  export APP_INSTALL_ARGS="--apps_path=/opt/frappe/apps.json"; \
  fi && \
  bench init ${APP_INSTALL_ARGS} --ignore-exist \
  --frappe-branch=${FRAPPE_BRANCH} \
  --frappe-path=${FRAPPE_PATH} \
  --no-procfile \
  --no-backups \
  --skip-redis-config-generation \
  --verbose \
  /home/frappe/frappe-bench && \
  cd /home/frappe/frappe-bench && \
  bench pip install python-dotenv && \
  bench pip install pikepdf && \
  echo "{}" > sites/common_site_config.json
  # find apps -mindepth 1 -path "*/.git" | xargs rm -fr

FROM base AS backend
USER frappe

COPY --from=builder --chown=frappe:frappe /home/frappe/frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

VOLUME [ \
  "/home/frappe/frappe-bench/sites", \
  # "/home/frappe/frappe-bench/sites/assets", \
  "/home/frappe/frappe-bench/logs" \
]

# COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# RUN chmod +x /usr/local/bin/entrypoint.sh

CMD [ \
  "/home/frappe/frappe-bench/env/bin/gunicorn", \
  "--chdir=/home/frappe/frappe-bench/sites", \
  "--bind=0.0.0.0:8000", \
  "--threads=4", \
  "--workers=16", \
  "--worker-class=gthread", \
  "--worker-tmp-dir=/dev/shm", \
  "--timeout=120", \
  "--preload", \
  "frappe.app:application" \
]
EOF
  echo "Temporary Dockerfile created."
fi

# 4. Create resources directory and files if they don't exist
mkdir -p resources
if [ ! -f "resources/nginx-template.conf" ]; then
  echo "Creating nginx-template.conf..."
  cat > resources/nginx-template.conf << 'EOF'
upstream backend {
    server ${BACKEND} fail_timeout=0;
}

upstream socketio {
    server ${SOCKETIO} fail_timeout=0;
}

server {
    listen 8080;
    server_name $FRAPPE_SITE_NAME_HEADER;
    root /home/frappe/frappe-bench/sites;

    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "same-origin, strict-origin-when-cross-origin";

    location /assets {
        try_files $uri =404;
    }

    location ~ ^/protected/(.*) {
        internal;
        try_files /sites/$http_host/$1 =404;
    }

    location /socket.io {
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Frappe-Site-Name $host;
        proxy_set_header Origin $scheme://$http_host;
        proxy_set_header Host $host;

        proxy_pass http://socketio;
    }

    location / {
        rewrite ^(.+)/$ $1 permanent;
        rewrite ^(.+)/index\.html$ $1 permanent;
        rewrite ^(.+)\.html$ $1 permanent;

        location ~ ^/files/.*.(htm|html|svg|xml) {
            add_header Content-disposition "attachment";
            try_files /sites/$http_host/public/$uri @webserver;
        }

        try_files /sites/$http_host/public/$uri @webserver;
    }

    location @webserver {
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Frappe-Site-Name $host;
        proxy_set_header Host $host;
        proxy_set_header X-Use-X-Accel-Redirect True;
        proxy_read_timeout ${PROXY_READ_TIMEOUT};
        proxy_redirect off;

        proxy_pass http://backend;
    }

    # error pages
    error_page 502 /502.html;
    location /502.html {
        root /home/frappe/frappe-bench/sites/assets;
        internal;
    }

    # optimizations
    sendfile on;
    keepalive_timeout 15;
    client_max_body_size ${CLIENT_MAX_BODY_SIZE};
    client_body_buffer_size 16K;
    client_header_buffer_size 1k;

    # enable gzip compresion
    gzip on;
    gzip_http_version 1.1;
    gzip_comp_level 5;
    gzip_min_length 256;
    gzip_proxied any;
    gzip_vary on;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/rss+xml
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/font-woff
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/svg+xml
        image/x-icon
        text/css
        text/plain
        text/x-component;
        # text/html is always compressed by HttpGzipModule
}
EOF
fi

if [ ! -f "resources/nginx-entrypoint.sh" ]; then
  echo "Creating nginx-entrypoint.sh..."
  cat > resources/nginx-entrypoint.sh << 'EOF'
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
EOF
  chmod +x resources/nginx-entrypoint.sh
fi

# 5. Build the Docker image with the APPS_JSON_BASE64
echo "Building Docker image with your apps..."
docker build --build-arg APPS_JSON_BASE64="$APPS_JSON_BASE64" -t frappe-app:latest .

# 6. Save the Docker image to a tar file
echo "Saving frappe-app:latest to a tar file..."
docker save frappe-app:latest -o frappe-app.tar

# 7. Import the image into k3s containerd
echo "Importing image into k3s..."
sudo k3s ctr images import frappe-app.tar

# 8. Verify the image is now available in k3s
echo "Verifying image import..."
sudo k3s ctr images ls | grep frappe-app

# 9. Delete the failed pods to trigger a restart
echo "Deleting the failed configurator job..."
kubectl delete job frappe-configurator -n frappe-men

# 10. Reapply the configurator job
echo "Reapplying the configurator job..."
kubectl apply -f configurator.yaml

echo "Done! Check the status with: kubectl get pods -n frappe-men"
echo "Note: Building the image with ERPNext may take some time. Please be patient."
