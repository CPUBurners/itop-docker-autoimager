# use ubuntu 20.04 as base image
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris
ENV ITOP_URL=https://kumisystems.dl.sourceforge.net/project/itop/itop/2.7.10/iTop-2.7.10-12681.zip
ENV PHP_VERSION=7.4

# Install required packages
RUN apt-get update -y
RUN apt-get install -y apache2 mysql-client
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:ondrej/php -y
RUN apt-get update -y
RUN apt-get install -y php${PHP_VERSION} php${PHP_VERSION}-mysql php${PHP_VERSION}-ldap php${PHP_VERSION}-cli php${PHP_VERSION}-soap graphviz
RUN apt-get install -y php${PHP_VERSION}-xml php${PHP_VERSION}-gd php${PHP_VERSION}-zip libapache2-mod-php${PHP_VERSION} php${PHP_VERSION}-mbstring
RUN apt-get install -y unzip wget

RUN apt-get install -y php${PHP_VERSION}-redis
RUN apt-get install -y php${PHP_VERSION}-apcu
# Itop performance tuning
RUN echo "apc.shm_size=128M" >> /etc/php/${PHP_VERSION}/apache2/php.ini
RUN echo "apc.ttl=7200" >> /etc/php/${PHP_VERSION}/apache2/php.ini
RUN a2enmod expires
RUN a2enmod headers
RUN echo '<IfModule mod_expires.c>\n\
    ExpiresActive On\n\
    ExpiresByType image/gif  A172800\n\
    ExpiresByType image/jpeg A172800\n\
    ExpiresByType image/png  A172800\n\
    ExpiresByType text/css   A172800\n\
    ExpiresByType text/javascript A172800\n\
    ExpiresByType application/x-javascript A172800\n\
    </IfModule>\n\
    <IfModule mod_headers.c>\n\
    <FilesMatch "\\\.(gif|jpe?g|png|css|swf|js)$">\n\
    Header set Cache-Control "max-age=2592000, public"\n\
    </FilesMatch>\n\
    </IfModule>' >> /etc/apache2/apache2.conf

# Download and install iTop
RUN wget -c ${ITOP_URL} -O /tmp/itop.zip
RUN unzip /tmp/itop.zip -d /tmp/itop
RUN mkdir /var/www/html/itop
RUN mv /tmp/itop/web/* /var/www/html/itop
RUN rm -rf /tmp/itop.zip /tmp/itop

#  Add itop toolkit
RUN mkdir /var/www/html/itop/toolkit
RUN wget -c https://github.com/Combodo/itop-toolkit-community/archive/refs/tags/3.0.0.zip -O /tmp/itop-toolkit.zip
RUN unzip /tmp/itop-toolkit.zip -d /tmp/itop-toolkit
RUN mv /tmp/itop-toolkit/itop-toolkit-community-3.0.0/* /var/www/html/itop/toolkit
RUN rm -rf /tmp/itop-toolkit.zip /tmp/itop-toolkit

RUN apt-get update -y
RUN apt-get install -y php${PHP_VERSION}-curl php${PHP_VERSION}-xdebug -y

RUN chown -R www-data:www-data /var/www/html/itop

# modify apache configuration to /itop
RUN sed -i 's/\/var\/www\/html/\/var\/www\/html\/itop/g' /etc/apache2/sites-available/000-default.conf

# Init iTop crontab
RUN apt-get install -y cron
RUN echo "*/5 * * * * www-data /usr/bin/php /var/www/html/itop/webservices/cron.php --param_file=/etc/itop/cron/params >>/etc/itop/cron/cron.log 2>&1" > /etc/cron.d/itop

CMD ["apachectl", "-D", "FOREGROUND"]