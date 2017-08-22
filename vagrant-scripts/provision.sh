#!/usr/bin/env bash

yum upgrade -y
yum install -y libxslt-devel libxml2-devel mariadb-devel
RUBY_VERSION=2.1.2

gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable
gpasswd -a vagrant rvm
sudo -u vagrant /home/vagrant/jbot/vagrant-scripts/ruby.setup.sh

echo "============================================================"
echo "Great Success! Your jbot dev env is ready to hack on."
echo "Read and understand the README!"
echo "https://github.com/rikai/Showbot/blob/master/README.md"
echo ""
echo "REMEMBER: Before you get started:"
echo "1) cp cinchize.yml.example to cinchize.yml and customize"
echo "   Make sure to setup the irc bot settings, identity, pass etc."
echo "2) cp .env.example to .env and customize"
echo "3) cp public/data.json.example to public/data.json and customize"
echo "NOTE: You only need to do this once"
echo ""
echo "Starting the server and making changes:"
echo " -> vagrant ssh"
echo " -> cd jbot"
echo " -> bundle exec foreman start -f Procfile.local"
echo ""
echo "All else fails, yell at us in irc.geekshed.net #jupiterdev"
echo "============================================================"
