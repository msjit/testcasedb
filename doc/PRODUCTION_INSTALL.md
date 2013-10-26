# Production Install

This describes how to perform a production install of TestCaseDB. If you have issues or you need additional assistance, please use the administrator guide available on our website http://www.testcasedb.com/.

## Install required packages

These instructions are for Ubuntu. For detailed CentOS and Ubuntu instructions, download the administration guide.

1. Update the packages 'sudo apt-get update'
2. Install required packages 'sudo apt-get install openssh-server ruby1.9.1-full build-essential libopenssl-ruby1.9.1 imagemagick libxml2 libxml2-dev libxslt1-dev libssl-dev apache2 apache2-threaded-dev libapache2-mod-xsendfile nodejs mysql-server mysql-client libmysql-ruby1.9.1 libmysqlclient-dev apache2-dev libapr1-dev libaprutil1-dev libcurl4-openssl-dev'
3. Update Ruby Gems 'sudo gem install rubygems-update'
4. Install Phusion Passenger 'sudo gem install passenger'
5. Compile Passenger and follow its instructions 'sudo passenger-install-apache2-module'
6. Create a database in MySQL
    * Open MySQL 'mysql -u root -p'
    * Create a database 'create database tcdb_production;'
    * Create a user (replacing the <> items) "GRANT ALL ON \<database_name\>.* TO ‘\<database_username\>’@’localhost’ IDENTIFIED BY ‘\<database_password\>’;"
7. Uncompress the download tarball or download the Git Repo.
8. Configure the database values in config/database.yml to match step 6 for the production section.
9. Run the install script 'script/setup -p'
10. Compile the assets 'rake assets:precompile RAILS_ENV=production'
11. Add a site configuration for Apache
    * Create a site file 'sudo vi /etc/apache2/sites-available/qa.yourdomain.com'
    * Add and edit config as appropriate
        ```
        <VirtualHost *:80>
          ServerName <server_name.. ex. qa.yourcompany.com>
          Redirect / <SS site URL.. ex. https://qa.yourcompany.com>
        </VirtualHost>
        <VirtualHost *:443>
          ServerName <server_name.. ex. qa.yourcompany.com>
          DocumentRoot /home/tcdb/tcdb/public
          SetEnv SERVER_NAME <server_name>
          RailsEnv production
          XSendFile On
          XSendFilePath /home/tcdb
          <Directory /home/tcdb/tcdb/public>
            Allow from all
            Options FollowSymLinks
            Options -MultiViews
          </Directory>
        </VirtualHost>
        ```
11. Enable the Apache config 'sudo a2ensite qa.yourdomain.com'
12. Restart apache 'sudo apachectl2 restart'
13. Visit your site and login with default user admin/ChangeMe
14. Change the default password for the administrator!

## Postgres Support
If you plan on using Postgres in place of MySQL please use these notes below.

1. Create a DB in you Postgres for the application
2. In the config folder, copy the file database.yml.postgres to database.yml in order to configure your database.