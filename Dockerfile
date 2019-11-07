FROM centos:centos7

LABEL maintainer="Vipul Meehnia vipulmeehnia@gmail.com"

# Let the container know that there is no tty
ENV CENTOS_FRONTEND noninteractive
ENV NGINX_VERSION 1.16.1
ENV PHP_VERSION remi-php73
ENV php_conf /etc/php.ini
ENV fpm_conf /etc/php-fpm.d/www.conf
ENV php_fpm_conf /etc/php-fpm.conf

# Install Basic Requirements
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
RUN yum -y install deltarpm
RUN yum -y update \
    && yum -y install epel-release yum-utils vim nano zip unzip \
    && yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && yum -y update
RUN yum -y install python2-pip \
        python-setuptools \
        git \
        supervisor \
    && pip install wheel \
    && pip install supervisor-stdout

# Install Nginx
RUN yum -y install nginx-${NGINX_VERSION} \
    && rm -f /etc/nginx/conf.d/default.conf \
    && rm -f /etc/nginx/nginx.conf \
    && rm -Rf /usr/share/nginx/html

# Install PHP 7.3
RUN yum -y --enablerepo=${PHP_VERSION} install php-cli \
        php-common \
        php-curl \
        php-fpm \
        php-gd \
        php-intl \
        php-igbinary \
        php-imagick \
        php-json \
        php-mbstring \
        php-mcrypt \
        php-mongodb \
        php-msgpack \
        php-mysqlnd \
        php-opcache \
        php-pdo \
        php-redis \
        php-xml \
        php-xmlrpc \
        php-zip \
        php-pear

# Default configurations for Nginx and PHP-FPM
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} \
    && sed -i -e "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" ${php_conf} 
    && sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 10M/g" ${php_conf} 
    && sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} 
    && sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} 
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" ${php_fpm_conf} 
    && sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} 
    && sed -i -e "s|listen = 127.0.0.1:9000|listen = /var/run/php-fpm/php-fpm.sock|g" ${fpm_conf} 
    && sed -i -e "s/^;listen.mode\s*=\s*0660/listen.mode = 0660/g" ${fpm_conf} 
    && sed -i -e "s/pm = dynamic/pm = ondemand/g" ${fpm_conf} 
    && sed -i -e "s/pm.max_children = 5/pm.max_children = 15/g" ${fpm_conf} 
    && sed -i -e "s/pm.start_servers = 5/pm.start_servers = 20/g" ${fpm_conf} 
    && sed -i -e "s/pm.min_spare_servers = 5/pm.min_spare_servers = 20/g" ${fpm_conf} 
    && sed -i -e "s/pm.max_spare_servers = 5/pm.max_spare_servers = 50/g" ${fpm_conf} 
    && sed -i -e "s/^;pm.process_idle_timeout = 10/pm.process_idle_timeout = 5/g" ${fpm_conf} 
    && sed -i -e "s/www-data/nginx/g" ${fpm_conf}
    && sed -i -e "s/apache/nginx/g" ${fpm_conf} 
    && sed -i -e "s/^;clear_env = no$/clear_env = no/g" ${fpm_conf}
    && mkdir -p /var/run/php-fpm

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
  && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer \
  && rm -rf /tmp/composer-setup.*

# Clean up
RUN rm -rf /tmp/pear \
    && yum clean all

# Supervisor config
ADD ./supervisord.conf /etc/supervisord.conf

# Override nginx's default config
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./default.conf /etc/nginx/conf.d/default.conf

# Override default nginx welcome page
COPY html /usr/share/nginx/html

# Add Scripts
ADD ./start.sh /start.sh

EXPOSE 80

CMD ["/start.sh"]
