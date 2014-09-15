##
# Shell provisioner for magego
##

# Vars
case "$1" in
        "true")
                SAMPLE_DATA=true
                ;;
        "false")
                SAMPLE_DATA=false
                ;;
        *)
                SAMPLE_DATA=false
                ;;
esac

# Detect environment
VERSION=$(sed 's/\..*//' /etc/debian_version)
#source /etc/os-release

# Set non-interactive mode
export DEBIAN_FRONTEND=noninteractive

# Package cache if you are doing a lot of rip and burn. Install apt-cacher-ng and point to that machine.
#cat > /etc/apt/apt.conf.d/01proxy <<'EOF'
#Acquire::http::Proxy "http://naas.io:3142";
#EOF

# Create skeleton dirs to avoid error for services who can't find logfile
if [ ! -d /vagrant ]
    then
        mkdir -p /vagrant
        chown vagrant:vagrant /vagrant
fi
if [ ! -d /vagrant/logs ]
    then
        mkdir -p /vagrant/logs
        chown vagrant:vagrant /vagrant/logs
fi
if [ ! -d /vagrant/public ]
    then
        mkdir -p /vagrant/public
        chown vagrant:vagrant /vagrant/public
fi
if [ ! -d /vagrant/db ]
    then
        mkdir -p /vagrant/db
        chown vagrant:vagrant /vagrant/db
fi

# Update package mirrors and update base system
apt-get update
apt-get -y dist-upgrade

# Enter /vagrant directory when accessing ssh
if ! grep -Fxq "cd /vagrant" /home/vagrant/.bashrc
    then
        echo "cd /vagrant" >> /home/vagrant/.bashrc
fi

# Add composer binarys to PATH
if ! grep -Fxq 'PATH="/vagrant/vendor/bin:$PATH"' /home/vagrant/.profile
    then
        echo 'PATH="/vagrant/vendor/bin:$PATH"' >> /home/vagrant/.profile
fi

# Set upp mirrors
if [ $VERSION == "7" ] 
    then
        DISTRIB_CODENAME="wheezy"
        OS_CODENAME="debian"
        printf "\n\n"
        echo "Setting nginx mirrors to use packages for Debian Wheezy"
        printf "\n\n"
    elif [ $VERSION == "6" ]
    then
        DISTRIB_CODENAME="squeeze"
        OS_CODENAME="debian"
        printf "\n\n"
        echo "Setting nginx mirrors to use packages for Debian Squeeze"
        printf "\n\n"
    else
        printf "\n\n" >&2
        echo "Can not detect OS type for nginx mirrors. Aborting!" >&2
        echo "Debug: VERSION: $VERSION" >&2
        exit
fi

# Nginx mirrors, @todo use dotdeb mirrors instead?
echo "deb http://nginx.org/packages/$OS_CODENAME/ $DISTRIB_CODENAME nginx" > /etc/apt/sources.list.d/nginx.list
echo "deb-src http://nginx.org/packages/$OS_CODENAME/ $DISTRIB_CODENAME nginx" >> /etc/apt/sources.list.d/nginx.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62

# Backport mirrors
if [ $VERSION == "7" ]
    then
        echo "deb http://http.debian.net/debian $DISTRIB_CODENAME-backports main" > /etc/apt/sources.list.d/backports.list
    else
        echo "deb http://http.debian.net/debian-backports $DISTRIB_CODENAME-backports main" > /etc/apt/sources.list.d/backports.list
fi

# Dotdeb mirros
echo "deb http://dotdeb.netmirror.org/ $DISTRIB_CODENAME all" > /etc/apt/sources.list.d/dotdeb.list
echo "deb-src http://dotdeb.netmirror.org/ $DISTRIB_CODENAME all" >> /etc/apt/sources.list.d/dotdeb.list
gpg --keyserver keys.gnupg.net --recv-key 89DF5277
gpg -a --export 89DF5277 | sudo apt-key add -

# Percona mirrors
echo "deb http://repo.percona.com/apt $DISTRIB_CODENAME main" > /etc/apt/sources.list.d/percona.list
echo "deb-src http://repo.percona.com/apt $DISTRIB_CODENAME main" >> /etc/apt/sources.list.d/percona.list
apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
apt-get update

# Install packages
apt-get -y install build-essential
apt-get -y install php5-fpm php5-cli php5-curl php-soap php5-imagick php5-gd php5-mcrypt php5-mysql php5-xmlrpc php5-xsl php5-xdebug
apt-get -y install nginx git tree curl readahead
apt-get -y install mysql-server
#apt-get -y install percona-server-server-5.5 percona-server-client-5.5

# Install Node.js and varius tools
curl -sL https://deb.nodesource.com/setup | bash -
apt-get -y install nodejs
npm install gulp -g
npm install grunt -g

# Install ruby
if [ $VERSION == "7" ]
    then
        apt-get -y install ruby ruby-dev
    else
        apt-get -y install ruby1.9.1 ruby1.9.1-dev
fi

# Set up readahead scan
if [ $VERSION == "7" ]
    then
        if [ ! -d /etc/readahead ]
            then
                mkdir /etc/readahead
        fi
        touch /etc/readahead/profile-once
    elif [ $VERSION == "6" ]
    then
        touch /.readahead_collect
fi

# Install sass-gem. This can take a minute so lets put out a notice.
printf "\n\n"
echo "Installing sass and mailcatcher via gem.. this can take a minute.."
apt-get -y install libsqlite3-dev
gem install --no-rdoc --no-ri sass mailcatcher

cat > /etc/php5/fpm/pool.d/www.conf <<'EOF'
[magego]
user = vagrant
group = vagrant
listen = 127.0.0.1:9000
pm = dynamic
pm.max_children = 5
pm.start_servers = 3
pm.min_spare_servers = 2
pm.max_spare_servers = 4
request_slowlog_timeout = 5s
slowlog = /vagrant/logs/php-slowlog.log
chdir = /
catch_workers_output = yes
env[HOSTNAME] = $HOSTNAME
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
php_flag[display_errors] = on
php_admin_value[memory_limit] = 512M
php_admin_value[max_execution_time] = 1800
php_admin_value[error_log] = /vagrant/logs/php-error.log
php_admin_value[sendmail_path] = /usr/local/bin/catchmail -f mail@magego.dev
EOF

# PHP configuration
if [ $VERSION == "7" ]
    then 
        XDEBUG_FILENAME="20-xdebug.ini"
        XDEBUG_PATH=$(find /usr/lib/php5/ -name xdebug.so | head -1)
    else
        XDEBUG_FILENAME="xdebug.ini"
        XDEBUG_PATH=$(find /usr/lib/php5/ -name xdebug.so | head -1)
fi
echo "zend_extension=$XDEBUG_PATH" > /etc/php5/conf.d/$XDEBUG_FILENAME
cat >> /etc/php5/conf.d/$XDEBUG_FILENAME <<'EOF'
xdebug.profiler_enable_trigger=On
xdebug.idekey=vagrant
xdebug.remote_enable=1
xdebug.remote_autostart=0
xdebug.remote_port=9000
xdebug.remote_handler=dbgp
xdebug.remote_log=/vagrant/tmp/xdebug_remotelog
xdebug.remote_host=192.168.98.1
EOF

#@TODO: Move this to php5-fpm php_admin_value.
sed -i 's/display_errors = Off/display_errors = On/g' /etc/php5/fpm/php.ini
sed -i 's/display_startup_errors = Off/display_startup_errors = On/g' /etc/php5/fpm/php.ini
sed -i 's/error_reporting = E_ALL & ~E_DEPRECATED/error_reporting = E_ALL/g' /etc/php5/fpm/php.ini
sed -i 's/track_errors = Off/track_errors = On/g' /etc/php5/fpm/php.ini
sed -i 's/html_errors = Off/html_errors = On/g' /etc/php5/fpm/php.ini

rm /etc/nginx/conf.d/*.conf
cat > /etc/nginx/conf.d/magego.conf <<'EOF'
server {
	listen 			80;
	server_name 		_; 
	root        		/vagrant/public;
	access_log  		/vagrant/logs/nginx-access.log;
	error_log   		/vagrant/logs/nginx-error.log;
	fastcgi_send_timeout 	1800;
	fastcgi_read_timeout 	1800;
	fastcgi_connect_timeout 1800;
	location / {
		index index.html index.php;
		try_files $uri $uri/ @handler; 
		expires 30d;
	}
	location /api {
		rewrite ^/api/rest /api.php?type=rest last;
	}
	location  /. { 
		return 404;
	}
	location @handler { 
		rewrite / /index.php;
	}
	location ~ .php/ { 
		rewrite ^(.*.php)/ $1 last;
	}
	location ~ .php$ {
		if (!-e $request_filename) { rewrite / /index.php last; } 
		expires        off;
		fastcgi_pass   127.0.0.1:9000;
		fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
		fastcgi_param  MAGE_RUN_CODE default; 
		fastcgi_param  MAGE_RUN_TYPE store;
		include        fastcgi_params; 
	}
}
EOF

service nginx restart
service php5-fpm restart

# Create database
if [ -z `mysql -uroot --skip-column-names --batch -e "SHOW DATABASES  LIKE 'magego'"` ]
    then 
        mysql -uroot -e "create database magego"
        EMPTY_DB=true
fi

# Look for existing Magento
if [ ! "$(ls -A /vagrant/public)" ]
    then
            echo "Not Magento copy detected, fetching one!"
            wget -qO /tmp/magento.tar.gz ftp://ftp.welovecloud.se/pub/magento/1.9/magento-1901.tar.gz
            cd /tmp && tar -xf magento.tar.gz && cd magento/ && mv * /vagrant/public
            echo "Done fetching magento files.."
            MAGE_NEW=true
    else
            MAGE_NEW=false
fi

# If this is a fresh copy lets grab a post-intall database also. 
if [ $MAGE_NEW == true ] && [ ! -e /vagrant/public/app/etc/local.xml ] && [ ! -e /vagrant/db/db.sql ]
    then
        echo "Detected fresh magento copy, we will import post-install database."
        wget -qO /tmp/magento.sql ftp://ftp.welovecloud.se/pub/magento/1.9/post-install-1901.sql 
        mysql -uroot magego < /tmp/magento.sql
fi

echo "Checking for database in /vagrant/db/db.sql"
# Check if we have a database to import. This will overwrite the  This i dangerous stuff so lets put out a notice.
if [ -e /vagrant/db/db.sql ] && [ -n $EMPTY_DB ]
    then
        printf "\n\n"
        echo "(!!) Importing database dump from /vagrant/db/db.sql"
        echo "All other Magento data will be overwritten!"
        mysql -uroot magego < /vagrant/db/db.sql
    else
        echo "No database found at /vagrant/db/db.sql"
fi

# Create local.xml for Magento
if [ $MAGE_NEW == true ] || [ ! -e /vagrant/public/app/etc/local.xml ]
    then
        echo "Creating local.xml"
        cat > /vagrant/public/app/etc/local.xml <<'EOF'
<?xml version="1.0"?>
<config>
    <global>
        <install>
            <date><![CDATA[Tue, 02 Sep 2014 21:27:42 +0000]]></date>
        </install>
        <crypt>
            <key><![CDATA[4df184db9fe31e4deaa55b90d7bd10d3]]></key>
        </crypt>
        <disable_local_modules>false</disable_local_modules>
        <resources>
            <db>
                <table_prefix><![CDATA[]]></table_prefix>
            </db>
            <default_setup>
                <connection>
                    <host><![CDATA[/var/run/mysqld/mysqld.sock]]></host>
                    <username><![CDATA[root]]></username>
                    <password><![CDATA[]]></password>
                    <dbname><![CDATA[magego]]></dbname>
                    <initStatements><![CDATA[SET NAMES utf8]]></initStatements>
                    <model><![CDATA[mysql4]]></model>
                    <type><![CDATA[pdo_mysql]]></type>
                    <pdoType><![CDATA[]]></pdoType>
                    <active>1</active>
                </connection>
            </default_setup>
        </resources>
        <session_save><![CDATA[files]]></session_save>
    </global>
    <admin>
        <routers>
            <adminhtml>
                <args>
                    <frontName><![CDATA[admin]]></frontName>
                </args>
            </adminhtml>
        </routers>
    </admin>
</config>
EOF
fi

# Set right premissions to Magento
echo "Fixing premissions.."
chown -R vagrant:vagrant /vagrant/public
chmod -R 755 /vagrant/public

##
# Special stuff for importing sample data.
# This feature is sort of experimental at the moment.
##
if [ $SAMPLE_DATA == true ]
    then
        echo "(!!) Importing Magento with sample data" >&2
        echo "Downloading package.. It's about 500 MB so be patient"
        wget -qO /tmp/public.tar.gz ftp://ftp.welovecloud.se/pub/magento/1.9/sample-data/public.tar.gz
        wget -qO /tmp/sample-data.sql ftp://ftp.welovecloud.se/pub/magento/1.9/sample-data/sample-data.sql
        echo "Extracting files.."
        cd /tmp && tar xf public.tar.gz
        if [ -d /vagrant/public ]
            then
                echo "Found /vagrant/public! Creating backup!" >&2
                NOW_DT=`date +%Y%m%d%H%M%S`
                mv /vagrant/public /vagrant/public.$NOW_DT.bak
        fi
        mv /tmp/public /vagrant/public
        echo "Importing database.."
        mysql -uroot magego < /tmp/sample-data.sql
        rm /tmp/sample-data.sql
        echo "Done!"
        echo "Finishing by setting premissions"
        chown -R vagrant:vagrant /vagrant/public
        chmod -R 755 /vagrant/public
        printf "\n\n"
        echo "Go to http://127.0.0.1:8080/index.php/admin"
        echo "Username: magego"
        echo "Password: magego123"
fi

# Install/update composer
cd /usr/local/bin && curl -sS https://getcomposer.org/installer | php
if [ ! -L /usr/local/bin/composer ]
    then
        cd /usr/local/bin && ln -s composer.phar composer
fi
chmod a+x /usr/local/bin/composer.phar

# Install/update modman
wget -q -O /usr/local/bin/modman https://raw.github.com/colinmollenhour/modman/master/modman
chmod a+x /usr/local/bin/modman

# Start mailcatcher
mailcatcher --ip 0.0.0.0

# Clean APT cache
apt-get clean

printf "\n\n"
echo "Provisioning complete!"
printf "\n\n"
echo "Head over to http://127.0.0.1:8080/"
printf "\n\n"
printf "\n\n"
