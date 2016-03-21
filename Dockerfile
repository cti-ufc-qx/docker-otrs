FROM ubuntu:14.04
MAINTAINER Tommaso Visconti <tommaso.visconti@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && apt-get install -y wget apache2 supervisor libcrypt-ssleay-perl libencode-hanextra-perl libgd-gd2-perl libgd-text-perl libgd-graph-perl libjson-xs-perl liblwp-useragent-determined-perl libmail-imapclient-perl libapache2-mod-perl2 libnet-dns-perl libnet-ldap-perl libpdf-api2-perl libtext-csv-xs-perl libxml-parser-perl libyaml-perl libcrypt-eksblowfish-perl libyaml-libyaml-perl libnet-ldap-perl mysql-server fetchmail

# Supervisor
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf


# OTRS
RUN wget http://ftp.otrs.org/pub/otrs/otrs-3.3.7.tar.bz2
RUN tar -C /opt -xjf otrs-3.3.7.tar.bz2 && rm otrs-3.3.7.tar.bz2 && mv /opt/otrs-3.3.7 /opt/otrs
RUN useradd -r -d /opt/otrs -c 'OTRS service user' otrsserviceuser
RUN usermod -G nogroup otrsserviceuser
ADD otrs/Config.pm /opt/otrs/Kernel/Config.pm
RUN cd /opt/otrs/Kernel/Config && cp GenericAgent.pm.dist GenericAgent.pm
RUN cd /opt/otrs/var/cron && for foo in *.dist; do cp $foo `basename $foo .dist`; done
RUN cd /opt/otrs/bin && ./otrs.SetPermissions.pl /opt/otrs --otrs-user=otrsserviceuser --otrs-group=nogroup --web-user=www-data --web-group=www-data
RUN ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/conf-enabled/otrs.conf


# Set OTRS cron jobs
su otrsserviceuser -c "/opt/otrs/bin/Cron.sh start"



RUN apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

EXPOSE 80

CMD ["/usr/bin/supervisord"]
