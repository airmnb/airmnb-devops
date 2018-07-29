# airmnb-devops

This is a CD script to deploy Airmnb API server and Web server on Ubuntu.

## How to use
Navigate to some work directory (any place can be fine), and run below command.
```
sudo git fetch && sudo git checkout -B master -f origin/master && sudo chmod +x *.sh
```

Create an `~/env` file and paste the secret environment variable configuration in prodduction. 
Make sure:
- `AMB_DOMAIN_NAME` is either `www.airmombaby.com` or `www.airmnb.com`;
- `AMB_DATABASE_URI` is the correct database conneciton string to the prod database;
- `AMB_RUNTIME_ENVIRONMENT` is constantly `production`.
```
vi ~/env 
```

Execute below shell command to kick off the deployment process. We need to explicitly specify the `AMB_DOMAIN_NAME` (again) is to link the SSL cert file correctly. (Worth improving later)
```
sudo AMB_DOMAIN_NAME=www.airmombaby.com -s ./deploy.sh
# sudo AMB_DOMAIN_NAME=www.airmnb.com -s ./deploy.sh

curl -X GET https://${AMB_DOMAIN_NAME}/sys/health_check
```

## What does the script do
1. Install system level dependencies, like apache, pip...
2. Determine if this is the first time to deploy, by checking if the symblink `/var/www/airmnb/current` exists.
    1. [First time] Install nodejs, yarn and typescript.
    2. Fetch `airmnb-devops` repo if first time.
    3. Symlink ssl certificates to `/var/www/airmnb/certs` for apache
    4. Enable apache features `cgi`, `ssl`, `rewrite`.
    5. Disable apache default sites.
    6. Enable airmnb site with `/etc/apache2/sites-available/airmnb.conf`
3. Fetch `airmnb-app` (to `/var/www/airmnb/assets/assets_$(date +%Y%m%d_%H%M%S)/app`) and install its dependencies.
4. Fetch `airmnb-web` (to `/var/www/airmnb/assets/assets_$(date +%Y%m%d_%H%M%S)/web`) and install its dependencies.
5. Symlink `airmnb-web`'s build folder to `airmnb-app`
6. Switch symlink `/var/www/airmnb/current` to the latest asset folder.
7. Restart apache.

## Information Required Env Vars

### Env var

```
AMB_DOMAIN_NAME=www.airmombaby.com
AMB_DOMAIN_NAME=www.airmnb.com
DATABASE_URI=postgres://qstqzkzu:wIRQ-yASKMaE7hEdABZCD7cSKUuC40DA@stampy.db.elephantsql.com:5432/qstqzkzu
```

### Related Directories

* Each deployment will download the code into
  `/var/www/airmnb/assets/assets_$(date +%Y%m%d_%H%M%S)`
* The symlink serving apache, usually pointing to the latest asset folder.
  `/var/www/airmnb/current`
* Apache site config
  `/etc/apache2/sites-available/airmnb.conf` (a symlink to the one in `airmnb-devops`)
  `/etc/apache2/sites-enabled/airmnb.conf`
* SSL certificates for Apache
  `/var/www/airmnb/certs` (a symlink to the one in `airmnb-devops`)

### Force to deploy from scratch
The script checks the existence of the symblink `/var/www/airmnb/current` to determine whether to skip some steps. You can clear it and force the script to run from scratch, like

```
git fetch && git checkout -B master -f origin/master && sudo chmod +x *.sh

sudo ./clear.sh

sudo AMB_DOMAIN_NAME=www.airmombaby.com -s ./deploy.sh
```
Or, you can define an alias like below. Everything logged in, just type `deploy` and it should kick off the deployment process.
```
alias deploy='cd ~/airmnb-devops; sudo AMB_DOMAIN_NAME=www.airmnb.com -s ./deploy.sh'
```
