#!/bin/bash

clear
read -p "Nama Aplikasi (ex: MyApp): " app
read -p "User aplikasi (ex: Tito): " usr
read -p "Database aplikasi (ex: Tito): " db
read -p "Password aplikasi (ex: 123456): " psw


dir=$PWD;

echo "Menyiapkan Directory kerja $app ..."
if [ -e $app ]; then
    echo "Directory $app sudah tersedia ... Silahkan pilih nama yang lain..."
    exit;
else

    mkdir $app
    echo "Menyalin directory app ke dalam directory $app ..."
    rsync -az "app/" "$app/app/"

    echo "Menyalin directory writable ke dalam directory $app ..."
    rsync -az "writable/" "$app/writable/"

    echo "Menyalin directory public ke dalam directory $app ..."
    rsync -az "public/" "$app/public/"

    echo "Menyalin berkas env ke dalam directory $app ..."
    rsync -az ".env" "$app/.env"

    sed -i 's/# CI_ENVIRONMENT = production/CI_ENVIRONMENT = development/g' "${app}/.env"
    sed -i 's/# app./app./g' "${app}/.env"

    sed -i "s/app.baseURL = ''/app.baseURL = 'https:\/\/$domain.ano/g" "${app}/.env"
    sed -i "s/ci4/${db}/g" "${app}/.env"

    sed -i 's/# database./database./g' "${app}/.env"
    sed -i "s/username = root/username = ${usr}/g" "${app}/.env"
    sed -i "s/password = root/password = ${psw}/g" "${app}/.env"
    sed -i "s/ci_session/${app}_session/g" "${app}/.env"


    echo "Mengatur ulang path vendor di $app/app/Config/Constants.php"
    sed -i "s/'vendor\/autoload.php'/'..\/vendor\/autoload.php'/" "$app/app/Config/Constants.php"
    sed -i "s/..\/vendor/..\/..\/vendor/" "$app/app/Config/Paths.php"

    chmod 777 "$app/writable/" -R
    echo " Directory kerja $app sudah siap..."

    domain="$app.lokal"

    echo "Sedang mensetting SSL untuk domain https://$domain ..."
    cd /etc/ssl/

    if test -f "$domain.pem"; then
        echo "SSL sudah diset"
    else
        mkcert "$domain"
    fi

    if grep -q "$domain" "/etc/hosts" ;then
        echo "/etc/hosts sudah diset"
    else
        echo "127.0.0.1  $domain" >> /etc/hosts
    fi

    echo "Setting virtual host untuk $domain ..."
    conf="${domain}.conf"

    if test -f "/etc/nginx/conf.d/${conf}"; then
        echo "Virtual host sudah diset sudah diset"
    else
        cd "/etc/nginx/conf.d/"
        touch ${conf}
        echo -e "server {" | tee -a $conf
        echo -e "\tlisten\t80;" | tee -a $conf
        echo -e "\tserver_name $domain;" | tee -a $conf
        echo -e "\trewrite ^ https://\$server_name\$request_uri? permanent;" | tee -a $conf
        echo -e "}\n" | tee -a $conf
        echo -e "server {" | tee -a $conf
        echo -e "\tlisten *:443 ssl http2;" | tee -a $conf
        echo -e "\tserver_name $domain;" | tee -a $conf
        echo -e "\troot $dir/$app/public/;" | tee -a $conf
        echo -e "\tindex index.php;\n" | tee -a $conf
        echo -e "\tssl_certificate /etc/ssl/$domain.pem;" | tee -a $conf
        echo -e "\tssl_certificate_key  /etc/ssl/$domain-key.pem;" | tee -a $conf
	    echo -e "\tclient_max_body_size 10M;\n" | tee -a $conf
        echo -e "\tlocation  ~ /\\\. {" | tee -a $conf
        echo -e "\t\tdeny all;" | tee -a $conf
        echo -e "\t}\n" | tee -a $conf
        echo -e "\tlocation / {" | tee -a $conf
        echo -e "\t\ttry_files \$uri \$uri/ /index.php?r=\$request_uri;" | tee -a $conf
        echo -e "\t}\n" | tee -a $conf
        echo -e "\tlocation ~ \\\.php\$ {" | tee -a $conf
        echo -e "\t\tfastcgi_pass unix:/run/php/php7.4-fpm.sock;" | tee -a $conf
        echo -e "\t\tinclude snippets/fastcgi-php.conf;" | tee -a $conf
        echo -e "\t\tfastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;" | tee -a $conf
        echo -e "\t}" | tee -a $conf
        echo -e "}" | tee -a $conf

        systemctl restart nginx
    fi
fi
clear

echo "menyiapkan database  ..."
echo "Note: password tidak ditampilkan saat diketik"
read -p "User Database (ex: root): " usrdb
read -sp "Input password MySQL untuk user root: " rootpasswd
mysql -u${usrdb} -p${rootpasswd} -e "CREATE DATABASE  IF NOT EXISTS  ${db} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -u${usrdb} -p${rootpasswd} -e "CREATE USER  IF NOT EXISTS  ${usr}@localhost IDENTIFIED BY '${psw}';"
mysql -u${usrdb} -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${app}.* TO '${usr}'@'localhost';"
mysql -u${usrdb} -p${rootpasswd} -e "FLUSH PRIVILEGES;"

echo "Apliaksi $app sudah siap. Silahkan akses dengan alamat https://$domain"