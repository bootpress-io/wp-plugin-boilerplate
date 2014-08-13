# Variables
wphost=$(hostname)
wpname="Bootpress Plugin Development"
wplang="en_US"
wpemail="your.email@here.com"

dbname="wp"
dbuser="wp_user"
dbpass=$(uuidgen)
dbhost="localhost"
dbrootpass="password"

# Clean up composer
rm -rf /vagrant/{vendor,composer.lock}

# Update repositores
apt-get update -y

# Set Postfix settings (sendmail)
debconf-set-selections <<< 'postfix postfix/mailname string '$wphost''
debconf-set-selections <<< 'postfix postfix/main_mailer_type string "Internet Site"'

# Set MySQL root password
debconf-set-selections <<< 'mysql-server mysql-server/root_password password '$dbrootpass''
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$dbrootpass''

# Install dependencies
echo "============> Installing dependencies"
apt-get install -y \
	curl \
	apache2 \
	mysql-server \
	git-core \
	php5 \
	php5-curl \
	php5-cli \
	php5-mysql \
	php5-xdebug \
	php-apc \
	avahi-daemon \
	postfix \
	subversion

# Unmount shared folders
echo "============> Unmounting shared folders"
umount /var/www/wp-content/plugins/bootpress-plugin

# Install composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Wordpress cli
echo "============> Installing Wordpress cli"
curl -sS -o /usr/local/bin/wp -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /usr/local/bin/wp

echo 'WP_CLI_CONFIG_PATH="/etc/wp-cli.yml"' >> /etc/environment
export WP_CLI_CONFIG_PATH="/etc/wp-cli.yml"

cat > /etc/wp-cli.yml <<-EOF
path: /var/www
apache_modules:
 - mod_rewrite
EOF

# Install tab completions
# echo "============> Installing tab completions"
# curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash

# Remove FQDN message notice when restarting Apache
echo "============> Installing Wordpress"
echo "ServerName localhost" > /etc/apache2/conf.d/fqdn

# Restart Apache
echo "============> Activating Rewrite module and restarting Apache"
cat > /etc/apache2/sites-available/bootpress <<-EOF
<VirtualHost *:80>
	ServerAdmin $wpemail
	DocumentRoot /var/www/
	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>
	<Directory /var/www/>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
		Order allow,deny
		allow from all
	</Directory>
</VirtualHost>
EOF

a2dissite default
a2ensite bootpress
a2enmod rewrite
service apache2 restart

# Create database and user
echo "============> Creating database"
mysql -uroot -p$dbrootpass <<-EOF
CREATE DATABASE $dbname;
GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'$dbhost' IDENTIFIED BY '$dbpass';
FLUSH PRIVILEGES;
EOF

# Clean www folder
rm -rf /var/www/*

# Change owner for www folder to www-data
echo "============> Installing Wordpress"
chown -R www-data:www-data /var/www

su www-data <<-EOF
wp core download --locale="$wplang"
wp core config --dbname="$dbname" --dbuser="$dbuser" --dbpass="$dbpass" --dbhost="$dbhost"
wp core install --url="http://$wphost.local/" --title="$wpname" --admin_user="admin" --admin_password="admin" --admin_email="$wpemail"
wp rewrite structure '/%postname%/' --hard
EOF

# Mount shared folders again
echo "============> Mounting shared folders"
mkdir -p /var/www/wp-content/plugins/bootpress-plugin
mount -t vboxsf -o uid=`id -u www-data`,gid=`id -g www-data` var_www_wp-content_plugins_bootpress-plugin /var/www/wp-content/plugins/bootpress-plugin

# Fix permissions
find /var/www -type d -exec chmod 755 {} \;
find /var/www -type f -exec chmod 644 {} \;
