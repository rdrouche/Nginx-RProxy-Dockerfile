#!/bin/bash
set -e

# Variables
NGINX_WORKER_PROCESSES="${NGINX_WORKER_PROCESSES:-auto}"
NGINX_WORKER_CONNECTIONS="${NGINX_WORKER_CONNECTIONS:-768}"
NGINX_ENABLE_DEFAULT_VHOST="${NGINX_ENABLE_DEFAULT_VHOST:-0}"
NGINX_START_SHOW_CONFIG="${NGINX_START_SHOW_CONFIG:-0}"
NGINX_START_SHOW_VERSION="${NGINX_START_SHOW_VERSION:-0}"
NGINX_GOOD_BOT_ENABLE="${NGINX_GOOD_BOT_ENABLE:-0}"
NGINX_GOOD_BOT_URL="${NGINX_GOOD_BOT_URL}"

# --- FUNCTIONS ---
use_defaut_good_bot() {
	echo "[INFO] 🔧 Generate file : /etc/nginx/conf.d/good-bots.conf"
	rm -f /etc/nginx/conf.d/good-bots.conf
	tee /etc/nginx/conf.d/good-bots.conf > /dev/null <<EOF
# Bot definitions
# Only the following crawlers are allowed.

map \$http_user_agent \$is_good_bot {
        default 0;

        # Google & Bing
        "~*googlebot" 1;
        "~*bingbot" 1;
        "~*adidxbot" 1;
        
        # Other search bots
        "~*duckduckbot" 1;
        "~*qwantify" 1;
        "~*baiduspider" 1;
        "~*yandexbot" 1;
        "~*yeti" 1;
        
        # Social Networks
        "~*facebookexternalhit" 1;
        "~*twitterbot" 1;
        "~*pinterestbot" 1;
}
EOF
}

generate_nginx_conf() {

	echo "[INFO] ⚙️ Generate file : /etc/nginx/nginx.conf"

	# Deletion of existing files
	rm -f /etc/nginx/nginx.conf
	rm -f /etc/nginx/nginx.conf.default

	# Rename default config
	echo "[INFO] Rename default file"
	mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.default

	echo "[INFO] Write file"
	tee /etc/nginx/nginx.conf > /dev/null <<EOF
user www-data;
worker_processes ${NGINX_WORKER_PROCESSES};
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;

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
    include /etc/nginx/modules/*.conf;
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

# Generate config file
generate_nginx_conf

if [ "$NGINX_ENABLE_DEFAULT_VHOST" = "1" ]; then
    echo "[INFO] Enable default virtualhost"
    cp /etc/nginx/sites-available/default /etc/nginx/sites/default.conf
else
    echo "[INFO] Disable default virtualhost"
    rm -f /etc/nginx/sites/default.conf
fi

if [ "$NGINX_GOOD_BOT_ENABLE" = "1" ]; then
	echo "[INFO] 🤖 Enable list Good Bots"
	if [[ -z  "${NGINX_GOOD_BOT_URL}" ]]; then
	  echo "[INFO] ⛔ No URL configured for the bot list, using the default file"
	  use_defaut_good_bot
	else
	  # Test if can Download File
	  STATUS_CODE=$(curl -o /dev/null -s -w "%{http_code}" -L ${NGINX_GOOD_BOT_URL})
	  if [ $STATUS_CODE -eq 200 ]; then
		echo "[INFO] 📃 Download file from URL : ${NGINX_GOOD_BOT_URL}"
		curl -sL ${NGINX_GOOD_BOT_URL} -o /etc/nginx/conf.d/good-bots.conf
	  else
	    echo "[WARN] ⚠️ URL unreachable (Code: $STATUS_CODE), using default configuration"
		use_defaut_good_bot
	  fi
	fi
else
	# Delete file for disable config
	rm -f /etc/nginx/conf.d/good-bots.conf
fi

if [ "$NGINX_START_SHOW_CONFIG" = "1" ]; then
    nginx -T
    echo ""
    echo ""
    sleep 1
fi

if [ "$NGINX_START_SHOW_VERSION" = "1" ]; then
    nginx -V
    echo ""
    echo ""
    sleep 1
fi

echo ""
nginx -v
echo ""

if nginx -t; then
	echo "[OK] ✅ Valid configuration"
	echo ""
	echo "🚀 Starting the container..."
	exec "$@"
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