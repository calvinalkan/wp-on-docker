## Dependencies

- GNU MAKE 4+
- Docker Engine
- [Mkcert](https://github.com/FiloSottile/mkcert) (For local SSL)

## Setup

```shell
make init && make up
```

Add `wp-on-docker.test` to `/etc/hosts` , then visit https://wp-on-docker.test
where you should have a WordPress installation.

- Username: admin
- Password: admin

## All commands

```shell
make
```