#!/bin/bash
RUBY_VERSION=2.1.2
source /etc/profile.d/rvm.sh
rvm install $RUBY_VERSION
gem install bundler
cd /home/vagrant/jbot && bundle install
