#!/bin/bash
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m▣ '
NC='\033[0m'

if [ -z "$AMB_HOST_NAME" ]
then
  echo -e "${RED}AMB_HOST_NAME isn't specified (either 'www.airmnb.com' or 'www.airmombaby.com')${NC}"
  exit
fi

echo -e "${ORANGE}AMB_HOST_NAME = $AMB_HOST_NAME${NC}"

# 1. Install middlewares
echo -e "${GREEN}Installing middlewares${NC}"
apt-get install -y python2.7 apache2 libapache2-mod-wsgi apache2-utils libexpat1 ssl-cert yarn
# The pip installed by apt-get is buggy
easy_install pip

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

  echo -e "${GREEN}Installing nodejs,typescript,yarn${NC}"
  curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  apt-get update
  apt-get install -y nodejs cmdtest yarn
  npm install typescript -g

  # 3.1 Clone devops
  echo -e "${GREEN}Cloning devops repo${NC}"  
  cd $assetdir
  git clone --progress -b master https://github.com/airmnb/airmnb-devops.git devops

  ln -fs $assetdir/devops/certs/$AMB_HOST_NAME /var/www/airmnb/certs
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
echo -e "${GREEN}Building airmnb-app in $assetdir${NC}"
cd $assetdir
git clone --progress -b master https://github.com/airmnb/airmnb-app.git app
cd $assetdir/app
virtualenv venv
. venv/bin/activate
pip install -r requirements.txt
# python manage.py runserver &

# Setup web assets
echo -e "${GREEN}Building airmnb-web in $assetdir${NC}"
cd $assetdir
git clone --progress -b master https://github.com/airmnb/airmnb-web.git web
cd $assetdir/web
# yarn install
npm install
npm run build

# Switch symlink
echo -e "${GREEN}Symlink $assetdir/app/web${NC} pointing $assetdir/web/build"
ln -s $assetdir/web/build $assetdir/app/web

readlink $currentdir
echo -e "${GREEN}Symlink $currentdir${NC}"
echo -e "${GREEN}Before${NC} `readlink $currentdir`"
ln -sfn $assetdir $currentdir
echo -e "${GREEN}After${NC} `readlink $currentdir`"
# Restart Apache
echo -e "${GREEN}Reloading apache${NC}"

tee -a $currentdir/app/application.wsgi << END
import sys

sys.path.append('/var/www/airmnb/current/app')
sys.path.append('/var/www/airmnb/current/app/venv/lib/python2.7')

from application import application as application
END

service apache2 restart
