<?php

/*
 * We use a modified version of the wp-config-docker.php file of the official docker image.
 * (@see https://github.com/docker-library/wordpress/blob/master/latest/php7.4/fpm-alpine/wp-config-docker.php)
 *
 * The official one is ok, but we need to be able to change DB_NAME based on the current scenario (dev,e2e tests).
 * Its not easily possible to achieve this with environment variables because we run e2e tests
 * from the "app" container but the env values need to be set in the "nginx" container.
 *
 * This file needs to stay in-sync with https://github.com/WordPress/WordPress/blob/master/wp-config-sample.php
 * (It gets parsed by the upstream wizard in https://github.com/WordPress/WordPress/blob/f27cb65e1ef25d11b535695a660e7282b98eb742/wp-admin/setup-config.php#L356-L392)
 *
 * Attention: Dont remove the comments in this file.
 */

// a helper function to lookup "env_FILE", "env", then fallback
if (!function_exists('getenv_docker')) {
    // https://github.com/docker-library/wordpress/issues/588 (WP-CLI will load this file 2x)
    function getenv_docker($env, $default) {
        if ($fileEnv = getenv($env . '_FILE')) {
            return rtrim(file_get_contents($fileEnv), "\r\n");
        }
        else if (($val = getenv($env)) !== false) {
            return $val;
        }
        else {
            return $default;
        }
    }
}

define( 'DB_NAME', getenv_docker('DOCKER_WORDPRESS_DB_NAME', 'wordpresss'));
define( 'DB_USER', getenv_docker('DOCKER_WORDPRESS_DB_USER', 'example username') );
define( 'DB_PASSWORD', getenv_docker('DOCKER_WORDPRESS_DB_PASSWORD', 'example password') );
define( 'DB_HOST', getenv_docker('DOCKER_WORDPRESS_DB_HOST', 'mysql') );
define( 'DB_CHARSET', getenv_docker('DOCKER_WORDPRESS_DB_CHARSET', 'utf8') );
define( 'DB_COLLATE', getenv_docker('DOCKER_WORDPRESS_DB_COLLATE', '') );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         getenv_docker('DOCKER_WORDPRESS_AUTH_KEY',         'lw,,x$vlpHa>W%*or^0]/p<^hy9<DWDIJd4Q+%MSt[BI^D}eI5I?lVW~>FR#bw:+') );
define( 'SECURE_AUTH_KEY',  getenv_docker('DOCKER_WORDPRESS_SECURE_AUTH_KEY',  'n-Ojxso</}`mx2Kzp9.VV|$p%hT(; C?,MvpFP7w#)GmUM0j$$N}Ou{j:`?]BP$') );
define( 'LOGGED_IN_KEY',    getenv_docker('DOCKER_WORDPRESS_LOGGED_IN_KEY',    'I03p+HAX{~[g={X+VUJ~Jf3ju$v#K.8a(_rzf }U n@|t;Qt74s;l1=ny]:=>z0]') );
define( 'NONCE_KEY',        getenv_docker('DOCKER_WORDPRESS_NONCE_KEY',        '+cF~ ch[{@sRA`)+F(+--~q4dTWzarKga+`P>4Lw*blX*FqczbFRv)t!;8(;_)[s') );
define( 'AUTH_SALT',        getenv_docker('DOCKER_WORDPRESS_AUTH_SALT',        '?yxx<6c{LEg6<PN(3Vg4ssM-!^O}K+S/}T+1~[]@E(!!)+fCI|H+X<LNeVk=Jq%1') );
define( 'SECURE_AUTH_SALT', getenv_docker('DOCKER_WORDPRESS_SECURE_AUTH_SALT', 'e5 H4&$h<@C.UK|o@z?3RJ|@y%+rtv3o+.i7YgK(e!vo#w;4b|MH.{)W8O0Abcu-') );
define( 'LOGGED_IN_SALT',   getenv_docker('DOCKER_WORDPRESS_LOGGED_IN_SALT',   'Mq}b9DWtNH W||b0k1-mi/E&aw9}k>T?7/F AvAT^6G;FDil&E#{&u@Rh#e|~eC5') );
define( 'NONCE_SALT',       getenv_docker('DOCKER_WORDPRESS_NONCE_SALT',       'hHyA6Au?~] PuJAAy+17oEp2h@Z+6Uo.3u^1-}]8--b^~Txib||hFlii(#Xidda+') );

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = getenv_docker('DOCKER_WORDPRESS_TABLE_PREFIX', 'wp_');

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', (bool) getenv_docker('DOCKER_WORDPRESS_DEBUG', '') );
define('WP_DEBUG_LOG', getenv_docker('DOCKER_WORDPRESS_ERROR_LOG_PATH', true));

if ($configExtra = getenv_docker('DOCKER_WORDPRESS_CONFIG_EXTRA', '')) {
    eval($configExtra);
}

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';