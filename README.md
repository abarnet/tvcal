tvcal
=====
Make sure to add credentials.yaml file before running


deploy
======
Using capistrano 3

server dependencies
------------
rvm
rethinkdb

adduser deploy
passwd -l deploy
adduser deploy sudo

exec su -l $USER # may have to force relogin or login to get sudo group change to be respected

# need java jre for yui-compiler
sudo apt-get install openjdk-7-jre

# install rethinkdb (had to upgrade to 13.10 from 13.04 to be able to use package)
sudo add-apt-repository ppa:rethinkdb/ppa   && \
sudo apt-get update                         && \
sudo apt-get install rethinkdb
sudo cp /etc/rethinkdb/default.conf.sample /etc/rethinkdb/instances.d/instance1.conf
sudo service rethinkdb start