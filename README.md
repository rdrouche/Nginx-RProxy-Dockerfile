# Nginx Reverse Proxy - Debian 13 (Trixie)

[![Docker Pulls](https://img.shields.io/docker/pulls/rdrit/nginx-rproxy?logo=docker&label=Docker%20Hub)](https://hub.docker.com/r/rdrit/nginx-rproxy) [![Docker Image Version](https://img.shields.io/docker/v/rdrit/nginx-rproxy/latest?logo=docker&label=version)](https://hub.docker.com/r/rdrit/nginx-rproxy) [![Docker Image Size](https://img.shields.io/docker/image-size/rdrit/nginx-rproxy/latest?logo=docker&label=image%20size)](https://hub.docker.com/r/rdrit/nginx-rproxy) [![Dockerfile](https://img.shields.io/badge/Dockerfile-View-blue?logo=docker)](https://git.rdr-it.com/dockerfile/nginx-reverse-proxy)

Ce dépôt contient un Dockerfile optimisé pour déployer un serveur Nginx sur Debian 13 (Trixie), utilisant les dépôts de Ondřej Surý pour bénéficier des dernières versions et modules. Il est conçu pour servir de Reverse Proxy robuste avec une configuration dynamique via variables d'environnement.

## 🚀 Caractéristiques

- Base : Debian 13 (Slim) - Ultra léger et à jour.
- Source : Dépôt Nginx d'Ondřej Surý (standard de l'industrie pour Debian/Ubuntu).
- Modules inclus :
  - `geoip2` (Filtrage géographique)
  - `headers-more` (Gestion avancée des headers)
  - `subs-filter` (Substitution de contenu à la volée)
  - `stream` (Support Proxy TCP/UDP)
- Vérification : Test automatique de la configuration au démarrage.

## 🛠️ Installation & Utilisation

Pour une utilisation optimale utiliser avec le fichier docker-compose.yml.

- [Gitlab](https://git.rdr-it.com/root/docker-compose/-/tree/main/Nginx-RProxy?ref_type=heads)
- [Github](https://github.com/rdrouche/Docker-Compose/tree/main/Nginx-RProxy)

## ⚙️ Configuration (Variables d'environnement)

Le conteneur utilise un script entrypoint.sh qui génère dynamiquement le fichier nginx.conf. Vous pouvez ajuster les performances via les variables suivantes :


| Variable | Description | Valeur par défaut |
| --- | --- | --- |
| `NGINX_WORKER_PROCESSES` | Nombre de processus workers | auto |
| `NGINX_WORKER_CONNECTIONS` | Nombre de connexions par worker | 768 |
| `NGINX_START_SHOW_CONFIG` | Affiche la config complète au log (Debug) | 0 (Désactivé) |
| `NGINX_START_SHOW_VERSION` | Affiche la version détaillée (Modules) | 0 (Désactivé) |

## 📂 Structure des fichiers & Volumes

Pour rendre ce proxy utile, vous devez monter vos propres fichiers de configuration. L'image est structurée pour inclure automatiquement les fichiers dans ces dossiers :

- HTTP Sites : `/etc/nginx/sites/*.conf` (Inclus dans le bloc http)
- Générique : `/etc/nginx/conf.d/*.conf` (Inclus dans le bloc http)
- Streams (TCP/UDP) : `/etc/nginx/streams/*.conf` (Inclus dans le bloc stream)

## 🔍 Aide au Débogage

Au démarrage, le script exécute systématiquement un `nginx -t`.

- Si la configuration est valide : Nginx démarre normalement.
- Si la configuration est invalide : Le conteneur s'arrête en affichant un dump complet de l'erreur, de la configuration générée et des informations de version pour vous aider à corriger le problème immédiatement.
