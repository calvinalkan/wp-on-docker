ARG DOCKER_NGINX_VERSION

FROM nginx:${DOCKER_NGINX_VERSION}-alpine as base

#
# =================================================================
# Copy self signed certificates
# =================================================================
#
# These certificates a generated with a make command on setup.
# mkcert is needed locally to trust these certificates.
#
# @see https://github.com/FiloSottile/mkcert
#
COPY ./ssl-certs /etc/nginx/certs/self-signed
COPY ./default.conf /etc/nginx/conf.d/default.conf

#
# =================================================================
# Set NGINX web root
# =================================================================
#
# The WordPress files are mapped as a volume in docker-compose.yml
# to the value of APP_CODE_PATH.
# We just need to point our default nginx config to that directory.
#
ARG DOCKER_WORDPRESS_PATH
ARG DOCKER_WORDPRESS_SITE_HOST

RUN mkdir -p $DOCKER_WORDPRESS_PATH && \
    sed -i "s#root __NGINX_ROOT;#root $DOCKER_WORDPRESS_PATH;#" /etc/nginx/conf.d/default.conf && \
    sed -i "s#__NGINX_SERVER_NAME#$DOCKER_WORDPRESS_SITE_HOST#" /etc/nginx/conf.d/default.conf;


