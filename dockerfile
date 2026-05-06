# Stable
FROM nginx:1.29.8-trixie AS builder

ARG NGINX_VERSION=1.29.8

RUN apt-get update && apt-get install -y \
    build-essential \
    libpcre2-dev \
    libssl-dev \
    zlib1g-dev \
    libmaxminddb-dev \
    libgeoip-dev \
    libxml2-dev \
    libxslt1-dev \
    libperl-dev \
    git \
    wget

RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && tar zxvf nginx-${NGINX_VERSION}.tar.gz

WORKDIR /modules

RUN git clone --depth 1 https://github.com/openresty/headers-more-nginx-module.git && \
    git clone --depth 1 https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git && \
    git clone --depth 1 https://github.com/leev/ngx_http_geoip2_module.git && \
    # Include nginx-module-vts
    git clone --depth 1 https://github.com/vozlt/nginx-module-vts.git

WORKDIR /nginx-${NGINX_VERSION}

RUN ./configure --with-compat \
    --with-stream \
    --with-stream_ssl_module \
    --add-dynamic-module=/modules/headers-more-nginx-module \
    --add-dynamic-module=/modules/ngx_http_substitutions_filter_module \
    --add-dynamic-module=/modules/ngx_http_geoip2_module \
    --add-dynamic-module=/modules/nginx-module-vts \
    # On ajoute les flags de ton binaire actuel pour éviter les erreurs de format binaire
    # --with-cc-opt='-g -O2 -fstack-protector-strong -fPIC' \
    # --with-ld-opt='-Wl,-z,relro -Wl,-z,now -fPIC' \
    --with-cc-opt='-g -O2 -fstack-protector-strong -fstack-clash-protection -fcf-protection -fPIC' \
    --with-ld-opt='-Wl,-z,relro -Wl,-z,now -fPIC' \
    && make modules

FROM nginx:1.29.8-trixie

ARG NGINX_VERSION=1.29.8

RUN apt-get update && apt-get install -y libmaxminddb0 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /nginx-${NGINX_VERSION}/objs/ngx_http_headers_more_filter_module.so /usr/lib/nginx/modules/
COPY --from=builder /nginx-${NGINX_VERSION}/objs/ngx_http_subs_filter_module.so /usr/lib/nginx/modules/
COPY --from=builder /nginx-${NGINX_VERSION}/objs/ngx_http_geoip2_module.so /usr/lib/nginx/modules/
COPY --from=builder /nginx-${NGINX_VERSION}/objs/ngx_stream_geoip2_module.so /usr/lib/nginx/modules/
COPY --from=builder /nginx-${NGINX_VERSION}/objs/ngx_http_vhost_traffic_status_module.so /usr/lib/nginx/modules/

COPY nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /etc/nginx/sites-available && \
    mkdir -p /etc/nginx/sites-enabled && \
    mkdir -p /etc/nginx/sites && \
    mkdir -p /etc/nginx/streams && \
    mkdir -p /etc/nginx/conf.d && \
    mkdir -p /etc/nginx/modules-enabled && \
    # Remove symlink
    rm /etc/nginx/modules

# Création des fichiers de config que tu cherchais
RUN mkdir -p /usr/share/nginx/modules-available/ && \
    echo "load_module /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so;" > /usr/share/nginx/modules-available/mod-http-headers-more-filter.conf && \
    echo "load_module /usr/lib/nginx/modules/ngx_http_subs_filter_module.so;" > /usr/share/nginx/modules-available/mod-http-subs-filter.conf && \
    echo "load_module /usr/lib/nginx/modules/ngx_http_geoip2_module.so;" > /usr/share/nginx/modules-available/mod-http-geoip2.conf && \
    echo "load_module /usr/lib/nginx/modules/ngx_stream_geoip2_module.so;" > /usr/share/nginx/modules-available/mod-stream-geoip2.conf && \
    echo "load_module /usr/lib/nginx/modules/ngx_http_vhost_traffic_status_module.so;" > /usr/share/nginx/modules-available/mod-nginx-vts.conf

# Lien vers modules-enabled (pour que NGINX les charge)
RUN mkdir -p /etc/nginx/modules-enabled/ && \
    ln -s /usr/share/nginx/modules-available/mod-http-headers-more-filter.conf /etc/nginx/modules-enabled/50-mod-http-headers-more-filter.conf && \
    ln -s /usr/share/nginx/modules-available/mod-http-subs-filter.conf /etc/nginx/modules-enabled/50-mod-http-subs-filter.conf && \
    ln -s /usr/share/nginx/modules-available/mod-http-geoip2.conf /etc/nginx/modules-enabled/70-mod-http-geoip2.conf && \
    ln -s /usr/share/nginx/modules-available/mod-stream-geoip2.conf /etc/nginx/modules-enabled/70-mod-stream-geoip2.conf && \
    ln -s /usr/share/nginx/modules-available/mod-nginx-vts.conf /etc/nginx/modules-enabled/mod-nginx-vts.conf

COPY 05-generate-config.sh /docker-entrypoint.d
RUN chmod +x /docker-entrypoint.d/05-generate-config.sh