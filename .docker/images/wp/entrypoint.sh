#!/usr/bin/env bash

# Exit immediately, no undeclared variables, Use last exit code in pipes.
set -euo pipefail

#
# =================================================================
# Copy fresh WordPress source files
# =================================================================
#
# Since this container runs with a named volume (APP_CODE_PATH)
# we need to copy the installed WordPress files in entrypoint
# script to ensure that everything stays up to date.
#
# We can't run this code in the Dockerfile since it would
# only apply the first time the image is build.
# Subsequent builds would always use stale WordPress code
# and stuff like updating the WordPress version would not work
# properly.
#
#rm -rf "${DOCKER_WORDPRESS_PATH:?}/"*
tar cf - -C "$DOCKER_WORDPRESS_TMP_PATH" . | tar xpf - -C "$DOCKER_WORDPRESS_PATH"
echo "Copied fresh WordPress files from $DOCKER_WORDPRESS_TMP_PATH to $DOCKER_WORDPRESS_PATH"

#
# =================================================================
# Install and configure WordPress on first container startup
# =================================================================
#
# We use the WP-CLI to install WordPress the first time the wp
# container is started. Otherwise we would need to use the WP installer
# everytime which is not possible in CI anyway.
#
# Whether WordPress is installed or not is stored in the current database
# which is persisted in docker volumes locally. In CI, volumes are not persisted
# so that WP is installed on every CI run from scratch (good!).
#
# We need to install WordPress once for the default database used in local development
# and once for the database used in E2E tests.
#
if ! wp core is-installed; then

  wp core install --url="$DOCKER_WORDPRESS_SITE_URL" --title="WP-On-Docker" --admin_user=admin --admin_password=admin --admin_email="admin@$DOCKER_WORDPRESS_SITE_HOST"

  wp rewrite structure '/%postname%' --hard

fi

#
# =================================================================
# Run container
# =================================================================
#
# The value of "$@" is [php-fpm, -F] by default. But by not
# hard-coding this here we leave ourselves the option to pass
# a different command at runtime.
#
exec "$@"
