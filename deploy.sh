#!/bin/bash
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m▣ '
NC='\033[0m'


echo -e "${ORANGE}AMB_HOST_NAME = $AMB_HOST_NAME${NC}"
# if [ -z "$AMB_HOST_NAME" ]
# then
#   echo "AMB_HOST_NAME must be set"
#   exit
# fi

# 1. Install middlewares
echo -e "${GREEN}Installing middlewares${NC}"
apt-get install -y python2.7 python-pip apache2 libapache2-mod-wsgi apache2-utils libexpat1 ssl-cert

# 2. Create folder
assetdir=/var/www/airmnb/assets/assets_$(date +%Y%m%d_%H%M%S)
currentdir=/var/www/airmnb/current
echo -e "${ORANGE}assetdir = $assetdir${NC}"
echo -e "${ORANGE}currentdir = $currentdir${NC}"
firsttime=0
echo -e "${GREEN}Creating directory $assetdir${NC}"
mkdir -p $assetdir

if [ ! -L $currentdir ]; then
  firsttime=1
  echo -e "${GREEN}First time to setup the enviroment${NC}"

  # 3.1 Clone devops
  echo -e "${GREEN}Cloning devops repo${NC}"  
  cd $assetdir
  git clone --progress -b master https://github.com/airmnb/airmnb-devops.git devops

  ln -s $assetdir/devops/certs/$AMB_HOST_NAME /var/www/airmnb/certs
  echo -e "${GREEN}Creating symlink $currentdir pointing $assetdir${NC}"  
  ln -s "$assetdir" $currentdir

  echo -e "${GREEN}Configuring Apache mods/confs/sites${NC}"  
  a2enmod cgi ssl rewrite
  # a2enconf wsgi
  # a2enmod/a2dismod, a2ensite/a2dissite and a2enconf/a2disconf

  rm -f /etc/apache2/sites-available/airmnb.conf
  ln -s $assetdir/devops/sites-available/airmnb.conf /etc/apache2/sites-available/airmnb.conf
  a2dissite 000-default default-ssl
  a2ensite airmnb
else
  echo -e "${GREEN}The environment of Airmnb has been configured${NC}"
fi

# Setup app server
echo -e "${GREEN}Cloning app repo to $assetdir${NC}"
cd $assetdir
git clone --progress -b master https://github.com/airmnb/airmnb-app.git app
cd $assetdir/app
pip install -r requirements.txt
# python manage.py runserver &

# Setup web assets
echo -e "${GREEN}Cloning web repo to $assetdir${NC}"
cd $assetdir
git clone --progress -b master https://github.com/airmnb/airmnb-web.git web
cd $assetdir/web
yarn install

# Switch symlink

# Restart Apache
service apache2 restart
