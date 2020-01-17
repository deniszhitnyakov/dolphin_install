#!/bin/bash
echo '==================================='
echo '|                                 |'
echo '|             DOLPHIN             |'
echo '|                                 |'
echo '==================================='

echo 'Обновляю систему'
apt update > /dev/null 2>&1

echo 'Устанавливаю Unzip'
apt -y install unzip > /dev/null 2>&1

echo 'Устанавливаю CURL'
apt -y install curl > /dev/null 2>&1

echo 'Устанавливаю Apache2'
apt -y install apache2 > /dev/null 2>&1

echo 'Устанавливаю MariaDB'
apt -y install mariadb-server > /dev/null 2>&1

echo 'Устанавливаю PHP'
apt -y install php libapache2-mod-php php-mysql php-curl php-simplexml php-mbstring > /dev/null 2>&1
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.zip > /dev/null 2>&1
unzip ioncube_loaders_lin_x86-64.zip > /dev/null 2>&1
cp ioncube/ioncube_loader_lin_7.3.so /usr/lib/php/20180731/ioncube_loader_lin_7.3.so > /dev/null 2>&1
rm -rf ioncube
echo 'zend_extension = /usr/lib/php/20180731/ioncube_loader_lin_7.3.so' >> /etc/php/7.3/cli/php.ini

echo 'Перезагружаю Apache2'
service apache2 restart > /dev/null 2>&1

read -p 'Введите лицензию: ' lic
read -p 'Введите домен: ' domain

echo 'Запускаю установку DOLPHIN'
rm -f dolphin_install.php
curl https://raw.githubusercontent.com/deniszhitnyakov/dolphin_install/master/dolphin_install.php >> dolphin_install.php
php dolphin_install.php $lic $domain

echo 'Настраиваю Apache'
mv /var/www/html/apache2.conf /etc/apache2/apache2.conf
ln -sf /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load

echo 'Настраиваю MariaDB'
mv /var/www/html/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
service mariadb restart > /dev/null 2>&1

echo 'Настраиваю PHP'
mv /var/www/html/php.ini-apache /etc/php/7.3/apache2/php.ini
mv /var/www/html/php.ini-cli /etc/php/7.3/cli/php.ini
service apache2 restart > /dev/null 2>&1

# echo 'Пробую намутить SSL-сертификат для домена'
# apt -y install certbot python-certbot-apache > /dev/null 2>&1
# certbot --apache -n --agree-tos --email admin@$domain --redirect -d $domain > /dev/null 2>&1

echo 'Настраиваю скрипты'
crontab -l > mycron
echo "* * * * * php /var/www/html/index.php cron dispatch > /dev/null 2>&1" >> mycron
crontab mycron
rm mycron
crontab -l > mycron
echo "*/10 * * * * php /var/www/html/application/controllers/update.php > /dev/null 2>&1" >> mycron
crontab mycron
rm mycron


echo 'Настраиваю права доступа'
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

echo 'Очищаю ненужное'
rm -f /var/www/html/db.sql
rm -f /var/www/html/index.html
cd ~
rm -rf *

echo ''
echo '======================================='
echo 'Кажется, что все получилось :)'
echo 'Твой DOLPHIN готов к работе по адресу:'
echo http://$domain/welcome
echo ''
