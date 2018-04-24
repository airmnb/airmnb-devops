# airmnb-devops

1. Install `python 2.7`
1. Install `Apache` by ``

AMB_HOST_NAME=www.airmombaby.com
AMB_HOST_NAME=www.airmnb.com

sudo rm -f /etc/apache2/sites-available/airmnb.conf
sudo rm /var/www/airmnb/current
sudo rm /var/www/airmnb/certs

sudo chmod +x *.sh
sudo AMB_HOST_NAME=www.airmombaby.com -s ./deploy.sh
