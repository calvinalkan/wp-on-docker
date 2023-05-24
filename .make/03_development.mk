##@ [Development]

#
# =================================================================
# Development commands
# =================================================================
#
# This makefile contains commands that are for local development.
#

#
# =================================================================
# Run WP-CLI commands
# =================================================================
#
# Run WP-CLI commands in the php-fpm container.
#
.PHONY: wp
wp: CMD?=cli version
wp: ## Run a wp-cli command in the wp container. Usage: make wp CMD="plugin list" ARGS=<args...>
	$(MAYBE_EXEC_PHP_FPM_IN_DOCKER) wp $(CMD) $(ARGS)

#
# =================================================================
# Xdebug management
# =================================================================
#
#
.PHONY: xdebug-on
xdebug-on: LOCAL_USER_NAME=root
xdebug-on: ## Enable xdebug in the a container. Usage: make xdebug-on
	$(MAYBE_EXEC_IN_WP_SERVICE) sed -i 's/.*zend_extension=xdebug/zend_extension=xdebug/' '/usr/local/etc/php/conf.d/zz-custom.ini'
	@printf "$(GREEN)[OK] XDebug is now enabled in the wp container.$(NO_COLOR)\n"
	$(MAKE) restart-php-fpm --no-print-directory

.PHONY: xdebug-off
xdebug-off: LOCAL_USER_NAME=root
xdebug-off: ## Disable xdebug in a container.
	$(MAYBE_EXEC_IN_WP_SERVICE) sed -i 's/.*zend_extension=xdebug/;zend_extension=xdebug/' '/usr/local/etc/php/conf.d/zz-custom.ini'
	@printf "$(GREEN)[OK] XDebug is now disabled in the wp container.$(NO_COLOR)\n"
	$(MAKE) restart-php-fpm --no-print-directory

.PHONY: xdebug-path
xdebug-path: ## Get the path to the xdebug extension in the app container.
	@$(MAYBE_EXEC_APP_IN_DOCKER) bash -c 'echo "$$(php-config --extension-dir)/xdebug.so"'

.PHONY: restart-php-fpm
restart-php-fpm: ## Restart php-fpm without killing the container.
	@$(MAYBE_EXEC_IN_WP_SERVICE) kill -USR2 1 # (@see https://stackoverflow.com/a/43076457)
	@printf "$(GREEN)[OK] PHP-FPM restarted.$(NO_COLOR)\n"
