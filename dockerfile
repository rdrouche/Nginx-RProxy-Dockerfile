# Debian 13 (Trixie)
FROM debian:trixie-slim

# Métadonnées
LABEL maintainer="admin@votre-domaine.com"
LABEL description="Nginx Reverse Proxy - Debian 13 - Sury Repository"

# Éviter les interactions lors de l'installation
ENV DEBIAN_FRONTEND=noninteractive

# Installation des dépendances de base
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    ca-certificates \
    lsb-release \
    --no-install-recommends

RUN curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb \
    && dpkg -i /tmp/debsuryorg-archive-keyring.deb \
    && sh -c 'echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/nginx/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/nginx.list' \
    && apt-get update

# Ajout de la clé GPG et du dépôt Nginx d'Ondřej Surý
#RUN curl -sSLo /usr/share/keyrings/deb.sury.org-nginx.gpg https://packages.sury.org/nginx/apt.gpg \
#    && echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-nginx.gpg] https://packages.sury.org/nginx/trixie main" \
#    > /etc/apt/sources.list.d/nginx.list

# Installation de Nginx et nettoyage
RUN apt-get update && apt-get install -y \
    nginx \
    libnginx-mod-http-geoip2 \
    libnginx-mod-http-headers-more-filter \
    libnginx-mod-http-subs-filter \
    libnginx-mod-stream \
    libnginx-mod-stream-geoip2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Redirection des logs Nginx vers la sortie standard (Docker best practice)
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Exposition des ports HTTP et HTTPS
EXPOSE 80 443

ENTRYPOINT ["docker-entrypoint.sh"]
# Lancement de Nginx en premier plan
CMD ["nginx", "-g", "daemon off;"]