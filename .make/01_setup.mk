##@ [Project setup]

#
# =================================================================
# Setup the repository locally
# =================================================================
#
.PHONY: init
init: .make/.mk.env .docker/.env mkcert _create_dirs ## Initializes the project.

#
# =================================================================
# Create the .env file for make
# =================================================================
#
# This target will create the .make/.mk.env file on the first run
# Otherwise it will warn you if the contents of .make/.mk.env.dist
# and .make/.mk.env have diverged.
#
.make/.mk.env: .make/.mk.env.dist
	@if [ -f .make/.mk.env ]; \
		then\
			printf "$(YELLOW)[WARNING] The .env.dist make file has changed. Please check your .make/.mk.env file and adjust the modified values (This message will not be displayed again).$(NO_COLOR)\n";\
			touch .make/.mk.env;\
			exit 1;\
		else\
  			cp .make/.mk.env.dist .make/.mk.env;\
			printf "$(GREEN)[OK] Created new make .env file.$(NO_COLOR)\n";\
	fi

#
# =================================================================
# Create the .env file for docker
# =================================================================
#
# This target will create the .docker/.env file on the first run
# Otherwise it will warn you if the contents of .docker/.env.dist
# and .docker/.env have diverged.
#
.docker/.env: .docker/.env.dist
	@if [ -f .docker/.env ]; \
		then\
			printf "$(YELLOW)[WARNING] The .env.dist docker file has changed. Please check your .env docker file and adjust the modified values (This message will not be displayed again).$(NO_COLOR)";\
			touch .docker/.env;\
			exit 1;\
		else\
  			cp .docker/.env.dist .docker/.env;\
			printf "$(GREEN)[OK] Created new docker .env file.$(NO_COLOR)\n";\
	fi

#
# =================================================================
# Install mkcert
# =================================================================
#
# We need to install mkcert so that the SSL certificates
# in this repository are trusted locally.
#
# Mkcert needs to be installed locally.
#
# @see https://github.com/FiloSottile/mkcert
#
.PHONY: mkcert
mkcert:
	mkcert -install
	cd $(DOCKER_DIR)/images/nginx/ssl-certs && mkcert $(SITE_HOST)

.PHONY: _create_dirs
_create_dirs:
	#mkdir wp
	printf "$(GREEN)[OK] Directories created$(NO_COLOR)\n"