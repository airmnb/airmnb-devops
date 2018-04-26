#!/bin/bash
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m▣ '
NC='\033[0m'

if [ -z "$AMB_DOMAIN_NAME" ]
then
  echo -e "${RED}AMB_DOMAIN_NAME isn't specified (either 'www.airmnb.com' or 'www.airmombaby.com')${NC}"
  exit
fi

echo -e "${ORANGE}AMB_DOMAIN_NAME = $AMB_DOMAIN_NAME${NC}"

# 1. Install middlewares
echo -e "${GREEN}Installing middlewares${NC}"
apt-get install -y python3.6 python3-pip apache2 libapache2-mod-wsgi-py3 apache2-utils libexpat1 ssl-cert yarn
# The pip installed by apt-get is buggy
# easy_install pip

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
  git clone --depth 1 --progress -b master https://github.com/airmnb/airmnb-devops.git devops

  ln -fs $assetdir/devops/certs/$AMB_DOMAIN_NAME /var/www/airmnb/certs
  echo -e "${GREEN}Creating symlink $currentdir pointing $assetdir${NC}"
  ln "$assetdir" $currentdir

  # Config apache enn var
  grep "airmnb" /etc/apache2/envvars || tee -a /etc/apache2/envvars << END
AMB_ROOT=/var/www/airmnb/current/app
AMB_ENV=${AMB_ROOT}/env
if [ -f "${AMB_APP_ENV}" ]; then
    . "${AMB_APP_ENV}"
fi
END

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
git clone --depth 1 --progress -b master https://github.com/airmnb/airmnb-app.git app
cd $assetdir/app
virtualenv venv
. venv/bin/activate
pip install -r requirements.txt
# python manage.py runserver &

# Setup web assets
echo -e "${GREEN}Building airmnb-web in $assetdir${NC}"
cd $assetdir
git clone --depth 1 --progress -b master https://github.com/airmnb/airmnb-web.git web
cd $assetdir/web
# yarn install
npm install
CI=true npm run test
npm run build

# Marry app and web
echo -e "${GREEN}Marry app and web${NC}"
ln -s $assetdir/web/build/index.html $assetdir/app/app/index.html
ln -s $assetdir/web/build/favicon.ico $assetdir/app/app/favicon.ico
ln -s $assetdir/web/build/manifest.json $assetdir/app/app/manifest.json
ln -s $assetdir/web/build/service-worker.js $assetdir/app/app/service-worker.js
ln -s $assetdir/web/build/static $assetdir/app/app/static

# Switch symlink
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
