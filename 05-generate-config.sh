#!/bin/bash
set -e

# Variables
NGINX_WORKER_PROCESSES="${NGINX_WORKER_PROCESSES:-auto}"
NGINX_WORKER_CONNECTIONS="${NGINX_WORKER_CONNECTIONS:-768}"
NGINX_START_SHOW_CONFIG="${NGINX_START_SHOW_CONFIG:-0}"
NGINX_START_SHOW_VERSION="${NGINX_START_SHOW_VERSION:-0}"
NGINX_HTTP_EXTRA_CONF="${NGINX_HTTP_EXTRA_CONF:-}"


# --- FUNCTIONS ---
generate_nginx_conf() {

        echo "[INFO] ⚙️ Generate file : /etc/nginx/nginx.conf"

        # Deletion of existing files
        rm -f /etc/nginx/nginx.conf.default

        # Rename default config
        echo "[INFO] Rename default file"
        mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.default

        echo "[INFO] Write file"
        tee /etc/nginx/nginx.conf > /dev/null <<EOF
user nginx;
worker_processes ${NGINX_WORKER_PROCESSES};
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
include /etc/nginx/modules/*.conf;
error_log /var/log/nginx/error.log;

events {
        worker_connections ${NGINX_WORKER_CONNECTIONS};
        # multi_accept on;
}

http {

        ##
        # Basic Settings
        ##

        sendfile on;
        tcp_nopush on;
        types_hash_max_size 2048;
        # server_tokens off;

        # server_names_hash_bucket_size 64;
        # server_name_in_redirect off;

        include /etc/nginx/mime.types;
        default_type application/octet-stream;

        ##
        # Custom Injection (Rate Limit, etc.)
        ##
        ${NGINX_HTTP_EXTRA_CONF}

        ##
        # SSL Settings
        ##

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
        ssl_prefer_server_ciphers on;

        ##
        # Logging Settings
        ##

        access_log /var/log/nginx/access.log;

        ##
        # Gzip Settings
        ##

        gzip on;

        # gzip_vary on;
        # gzip_proxied any;
        # gzip_comp_level 6;
        # gzip_buffers 16 8k;
        # gzip_http_version 1.1;
        # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

        ##
        # Virtual Host Configs
        ##

        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites/*.conf;
}

stream {
        log_format combined '\$time_iso8601 \$remote_addr '
        '\$protocol \$status \$bytes_sent \$bytes_received '
        '\$session_time \$upstream_addr '
        '"\$upstream_bytes_sent" "\$upstream_bytes_received" "\$upstream_connect_time"';

        access_log /var/log/nginx/stream.log combined;
        include /etc/nginx/streams/*.conf;
}
EOF
}

generate_proxy_params(){
        echo "[INFO] ⚙️ Generate file : /etc/nginx/proxy_params"
        tee /etc/nginx/proxy_params > /dev/null <<EOF
proxy_set_header Host \$http_host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$scheme;
EOF
}

# Generate config file
generate_nginx_conf
generate_proxy_params

if [ "$NGINX_START_SHOW_CONFIG" = "1" ]; then
    nginx -T
    echo ""
    echo ""
fi

if [ "$NGINX_START_SHOW_VERSION" = "1" ]; then
    nginx -V
    echo ""
    echo ""
else
  echo ""
  nginx -v
  echo ""
fi

if nginx -t; then
        echo "[OK] ✅ Valid configuration"
        echo ""
        echo "🚀 Starting the container..."
        #exec "$@"
else
        echo "[ERROR] 🚨 Invalid configuration, Nginx cannot start"
        echo ""
        echo "[DEBUG] Debugging information"
        echo ""
        echo "[CMD] nginx -t"
        nginx -t
        sleep 1
        echo "[CMD] nginx -T (Full config)"
        nginx -T
        sleep 1
        echo "[CMD] nginx -V (Full version informations)"
        nginx -V
        sleep 1
        exit 1
fi