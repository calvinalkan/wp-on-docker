ARG DOCKER_WP_VERSION
ARG DOCKER_PHP_VERSION
ARG DOCKER_WP_CLI_VERSION
ARG DOCKER_ALPINE_VERSION

#
# =================================================================
# Install the WordPress base image
# =================================================================
#
# The official docker WordPress image handles volumes and state
# in a way that is not suitable for the development of our
# onorepo. Once the image is first built the WordPress site
# is expected to be updated through the admin UI.
# This is obviously not what we want as we need to be able
# to switch between PHP and WP versions frequently during
# development and testing.
#
# @see https://github.com/docker-library/wordpress/issues/567
#
# We will instead leverage the official WordPress image
# as a convenient way to get the WordPress source files.
#
FROM wordpress:${DOCKER_WP_VERSION} as wordpress

#
# =================================================================
# Install the wp-cli base image
# =================================================================
#
# Again the official WP-Cli image does not play nicely with our
# setup for the same reasons as the WordPress image so we just
# use the WP-CLI binary that it provides.
#
FROM wordpress:cli-${DOCKER_WP_CLI_VERSION}-php${DOCKER_PHP_VERSION} as wp_cli

#
# =================================================================
# Install PHP-FPM
# =================================================================
#
FROM php:${DOCKER_PHP_VERSION}-fpm-alpine${DOCKER_ALPINE_VERSION} as base

#
# =================================================================
# Install required PHP extensions for WordPress
# =================================================================
#
# We dont use the defaul docker-php-ext-install commands
# because they do not handle installing system requirements for us.
#
# Installing PHP extensions is the first step we take
# since it takes quite a long time, so we want to presever
# the cache here for as long as possible.
#
# @see https://github.com/mlocati/docker-php-extension-installer
# @see https://de.wordpress.org/about/requirements/
#
ADD https://github.com/mlocati/docker-php-extension-installer/releases/download/1.5.29/install-php-extensions /usr/local/bin
RUN chmod a+x /usr/local/bin/install-php-extensions && \
    install-php-extensions  json \
                            mysqli \
                            curl \
                            dom \
                            exif \
                            fileinfo \
                            hash \
                            imagick \
                            mbstring \
                            openssl \
                            pcre \
                            xml \
                            zip \
                            filter \
                            iconv \
                            intl \
                            simplexml \
                            sodium \
                            xmlreader \
                            zlib \
                            bcmath \
                            xdebug-^3.1 \
                            # ensure that xdebug is not enabled by default
                            && rm /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

#
# =================================================================
# Install system dependencies
# =================================================================
#
# WP-CLI needs less and bash to work properly.
#
RUN apk add --update --no-cache \
        less \
        bash \
        # For convenience
        vim \
        jq \
        nano

#
# =================================================================
# Copy our custom entrypoint script
# =================================================================
#
# We need to copy our custom entrypoint script into the container.
# Make sure to reference it based on the full path (from the repo root)
# because this image has the entire monorepo has build context.
#
COPY ./entrypoint.sh /etc/entrypoint.sh

#
# =================================================================
# Copy custom php-ini configuration
# =================================================================
#
# We copy our custom php-ini configuration into the
# correct location in the app container.
#
# The zz prefix ensures it is loaded after the default configuration.
#
ARG DOCKER_LOG_DIR

COPY ./zz-wp.ini /usr/local/etc/php/conf.d/zz-custom.ini
RUN mkdir -p $DOCKER_LOG_DIR && \
    sed -i "s#__LOG_DIR#$DOCKER_LOG_DIR#" /usr/local/etc/php/conf.d/zz-custom.ini

#
# =================================================================
# Set user constants
# =================================================================
#
# Docker will invalidate all layers after the FIRST USAGE
# of a build argument which is why we want to separate
# steps that require the usage of build args from other steps.
#
# @see https://docs.docker.com/engine/reference/builder/#impact-on-build-caching
# 
ARG DOCKER_USER_ID
ARG DOCKER_GROUP_ID
ARG DOCKER_USER_NAME
ARG DOCKER_GROUP_NAME

#
# =================================================================
# Bash setup
# =================================================================
#
# We copy our custom bash_profile and make sure that
# bash is the default shell.
#
COPY ./.bashrc /home/${DOCKER_USER_NAME}/.bashrc
COPY ./.bashrc /root/.bashrc
RUN sed -e 's;/bin/ash$;/bin/bash;g' -i /etc/passwd

#
# =================================================================
# Set the current user in the PHP-FPM config
# =================================================================
#
# For now, instead of using a custom PHP-FPM file we just replace
# the values in the default configuration file.
#
RUN sed -i "s/user = www-data/user = ${DOCKER_USER_NAME}/g" /usr/local/etc/php-fpm.d/www.conf && \
    sed -i "s/group = www-data/group = ${DOCKER_GROUP_NAME}/g" /usr/local/etc/php-fpm.d/www.conf

#
# =================================================================
# Copy WordPress source code and WP-CLI binary
# =================================================================
#
# We leverage docker multi stage builds here to copy just what
# we need from the default WordPress image.
#
# We copy the WordPress source files to /tmp/wordpress.
# This directory will be used in our custom entrypoint
# to populate "WP_APPLICATION_PATH" and "WP_SRC_PATH"
# with new WordPress source files.
#
# These two directories are supplied in the docker-compose.yml
# file and are used to mount named volumes.
#
# We need to overwrite these named volumes each time this
# container is run. Otherwise we will not be able to switch
# between different WordPress versions.
#
ARG DOCKER_WORDPRESS_PATH
ARG DOCKER_WORDPRESSP_TMP_PATH=/tmp/wordpress

COPY --from=wordpress /usr/src/wordpress $DOCKER_WORDPRESSP_TMP_PATH
COPY --from=wp_cli /usr/local/bin/wp /usr/local/bin/wp

# Remove default WP junk
RUN rm -rf $DOCKER_WORDPRESSP_TMP_PATH/wp-content/plugins/akismet && \
    rm -rf $DOCKER_WORDPRESSP_TMP_PATH/wp-content/plugins/hello.php && \
    rm -rf $DOCKER_WORDPRESSP_TMP_PATH/wp-content/themes/twentytwenty && \
    rm -rf $DOCKER_WORDPRESSP_TMP_PATH/wp-content/themes/twentytwentyone && \
    rm -rf $DOCKER_WORDPRESSP_TMP_PATH/wp-confing-sampe.php $DOCKER_WORDPRESSP_TMP_PATH/wp-confing-docker.php && \
    chmod +x /usr/local/bin/wp


#
# =================================================================
# Create user group and file permissions.
# =================================================================
#
# Every single path in the docker container where volumes/bind-mounts
# needs to exist in the container and be own by the correct user
# before the container starts. Otherwise we will get all
# sorts of permission errors.
#
RUN addgroup -g $DOCKER_GROUP_ID $DOCKER_GROUP_NAME && \
    adduser -D -u $DOCKER_USER_ID -s /bin/bash $DOCKER_USER_NAME -G $DOCKER_GROUP_NAME && \
    mkdir -p $DOCKER_WORDPRESS_PATH/wp-content/plugins && \
    chown -R $DOCKER_USER_NAME:$DOCKER_GROUP_NAME $DOCKER_WORDPRESS_PATH && \
    chown -R $DOCKER_USER_NAME:$DOCKER_GROUP_NAME $DOCKER_WORDPRESSP_TMP_PATH && \
    chown -R $DOCKER_USER_NAME:$DOCKER_GROUP_NAME $DOCKER_LOG_DIR

#
# =================================================================
# Copy custom MU-Plugins
# =================================================================
#
COPY --chown=$DOCKER_USER_NAME:$DOCKER_GROUP_NAME ./mu-plugins $DOCKER_WORDPRESSP_TMP_PATH/wp-content/mu-plugins

#
# =================================================================
# Copy custom wp-config.php to WordPress application
# =================================================================
#
# We cant use the upstream wp-config from dockerhub
# because it does not allow us to change databases dynamically
# at runtime.
#
COPY --chown=$DOCKER_USER_NAME:$DOCKER_GROUP_NAME ./custom-wp-config.php $DOCKER_WORDPRESSP_TMP_PATH/wp-config.php

#
# =================================================================
# Expose environment variables
# =================================================================
#
# We need to transform docker build args to env variables.
# The /etc/entrypoint.sh entrypoint needs these variables
# and ENV vars are the only ways to give access to them outside
# the dockerfile.
#
ENV DOCKER_WORDPRESS_TMP_PATH=$DOCKER_WORDPRESSP_TMP_PATH
ENV DOCKER_WORDPRESS_PATH=$DOCKER_WORDPRESS_PATH

WORKDIR $DOCKER_WORDPRESS_PATH

USER $DOCKER_USER_NAME

ENTRYPOINT ["sh", "/etc/entrypoint.sh"]

CMD ["php-fpm", "-F"]