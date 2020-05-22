# CI4-magic

## Apakah  CI4-magic itu?

CI4-magic adalah script bash yang digunakan untuk membangun sebuah apliakasi berbasis  [CodeIgniter 4](http://codeigniter.com).

## Persyaratan

- Sistem operasi linux
- Sudah terinstall aplikasi CodeIgniter 4 menggunakan composer
- webserver nginx
- php 7.2+
- MySql atau MariaDb
- mkcert  

## Setup

- Salin atau unduh `createApp.sh` di direktori project CI Anda. Pastikan File `createApp.sh` berada dalam satu folder dengan vendor

- Ubah mode dari file `createApp.sh` menjadi accessable dengan perintah : `chmod +x createApp.sh`

- silahkan buka file `createApp.sh` lakukan penyesuaian seperlunya, sebagai contoh pada pengaturan php-fpm pada baris 95: `echo -e "\t\tfastcgi_pass unix:/run/php/php7.4-fpm.sock;" | tee -a $conf` 

- domain lokal yang digunakan adalah `.lokal` dan Anda bisa mengantinya sesuai yang anda inginkan dengan mengubah baris 50: `domain="$app.lokal"`

- pada paket instalasi ini kami mengatur permission dari directori `writable` dengan mode 777, untuk keamanan silahkan atur ownership sesuai dengan user php dan ubah menjadi mode `755`, yaitu pada baris 47: `chmod 777 "$app/writable/" -R`