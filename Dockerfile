# Discourse
# maintainer Tobias Bradtke <webwurst@gmail.com>

from webwurst/ubuntu:saucy
run apt-get update && apt-get -y upgrade

# helper
run apt-get -y install git vim less gzip curl

# circus
run apt-get -y install python-pip python-dev pkg-config libevent-dev libzmq-dev python-zmq python-iowait python-psutil python-markupsafe python-anyjson python-gevent python-mako python-beaker python-bottle
# python-tornado
run pip install circus circus-web

# rails
run apt-get -y install ruby2.0 build-essential ruby2.0-dev zlib1g-dev libssl-dev libreadline-dev libdevil-dev libsqlite3-dev libmysqlclient-dev freetds-dev libxslt1-dev libxml2-dev libffi-dev

# bundler
# run gem install bundler --no-document
run gem install bundler --no-document -v 1.5.0.rc.1

# postgres
run apt-get -y install postgresql postgresql-contrib libpq-dev
run service postgresql start &&\
	su postgres --command "createuser --superuser root && createdb discourse_prod && createdb discourse_development"

# redis
run apt-get -y install redis-server

# discourse
run git clone https://github.com/discourse/discourse.git /docker/discourse

run cd /docker/discourse &&\
	bundle install --without test --clean --system --jobs 4
	# --deployment ?

# the place to be..
add . /docker

run cp /docker/pg_hba.conf /etc/postgresql/9.1/main/
run cp /docker/discourse/config/database.yml.development-sample /docker/discourse/config/database.yml
run cp /docker/discourse/config/redis.yml.sample /docker/discourse/config/redis.yml

run service postgresql start &&\
	service redis-server start &&\
	cd /docker/discourse &&\
	rake db:migrate db:seed_fu assets:precompile

run sed -i 's/[[:space:]]production\.localhost[[:space:]]/ localhost /' /docker/discourse/config/database.yml

run apt-get clean
workdir /docker
cmd ["circusd", "/docker/circus.ini"]
expose 3000 5500 9001