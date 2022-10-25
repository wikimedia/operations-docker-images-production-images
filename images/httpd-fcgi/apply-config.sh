#!/bin/bash
set -e
SRC="/tmp/config"
. /etc/apache2/envvars
# cleanup the directories
rm -f /etc/apache2/{conf,sites,mods}-enabled/*

enable_site() {
    conf=$1
    site=$(basename $conf)
    docroot=$(grep -F DocumentRoot $conf | sed s/DocumentRoot// | tr -d ' ')
    echo "enabling $conf with docroot $docroot"
    mkdir -p $docroot
    touch $docroot/index.php
    cp $conf /etc/apache2/sites-available/$site
    chown -R ${APACHE_RUN_USER}:${APACHE_RUN_GROUP} $docroot
    a2ensite $site
}


# Copy the base configurations
for conf in $SRC/conf/*; do
    conf_name=$(basename $conf)
    cp "$conf" "/etc/apache2/conf-available/$conf_name"
    a2enconf "$conf_name"
done

# Copy the base module configurations, and enable the modules
for mod in $(cat $SRC/installed-modules); do
    if [ -f $SRC/mod-conf/$mod.conf ]; then
        cp $SRC/mod-conf/$mod.conf /etc/apache2/mods-available/$mod.conf;
    fi;
    a2enmod "$mod"
done

# Now add our default vhosts
for site in $SRC/sites/*; do
    enable_site $site
done

# Create the /run/shared directory where we'll expect to find the php socket in case we use it
install -d -o www-data -g www-data -m 0750 /run/shared

# Finally add our env variables to ENVVARS
cat << EOF >> /etc/apache2/envvars

## fcgi-enabled image
export FCGI_MODE FCGI_URL SERVER_SIGNATURE SERVERGROUP DEBUG LOG_FORMAT LOG_SKIP_SYSTEM
EOF
echo "Reconfiguration done. Verifying."
apache2ctl configtest
