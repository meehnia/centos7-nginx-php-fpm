FROM centos:centos7

LABEL maintainer="Vipul Meehnia vipulmeehnia@gmail.com"

# Let the container know that there is no tty
ENV CENTOS_FRONTEND noninteractive
ENV NGINX_VERSION 1.17.2-1~buster
ENV php_conf /etc/php/7.3/fpm/php.ini
ENV fpm_conf /etc/php/7.3/fpm/pool.d/www.conf
ENV COMPOSER_VERSION 1.9.0
