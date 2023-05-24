<?php

declare(strict_types=1);

use PHPMailer\PHPMailer\PHPMailer;

/*
 * Plugin Name: Docker MailHog
 * Description: Send all wp_mail() emails to the MailHog docker container.
 */
\add_action('phpmailer_init', function (PHPMailer $mailer): void {
    $mailer->Host = 'mailhog';
    $mailer->Port = 1025;
    $mailer->IsSMTP();
});

\add_filter('wp_mail_from', fn (): string => 'admin@wp-on-docker.test');
\add_filter('wp_mail_from_name', fn (): string => 'WP-On-Docker');
