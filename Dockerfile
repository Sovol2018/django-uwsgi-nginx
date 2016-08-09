# Copyright 2013 Thatcher Peskens
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ubuntu:14.04

MAINTAINER Dockerfiles

# Install required packages and remove the apt packages cache when done.

RUN apt-get update && apt-get install -y \
	git \
	python3 \
	python3-dev \
	python3-pip \
	nginx \
	supervisor \
	sqlite3 \
	vim-nox \
	emacs24-nox emacs24-el \
	curl telnet dnsutils \
	libtiff5-dev libjpeg8-dev zlib1g-dev \
	libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk \
  && rm -rf /var/lib/apt/lists/*

# Make sure `env python` points to python3 in a login shell
RUN echo "alias python='python3'" >> /root/.bashrc

# Specify py3 lib path, pip3 will install libs into the dir.
# XXX: It's lame to hardcode 'python3.4'
RUN echo 'export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.4/dist-packages' >> /root/.bashrc

RUN mkdir /root/bin
RUN echo 'export PATH=$PATH:/root/bin' >> /root/.bashrc
COPY bin/* /root/bin/
RUN chmod +x /root/bin/*

# install uwsgi now because it takes a little while
RUN pip3 install uwsgi

# setup all the configfiles
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
COPY nginx-app.conf /etc/nginx/sites-available/default
COPY supervisor-app.conf /etc/supervisor/conf.d/

# Create Self-signed SSL cert
RUN mkdir /etc/nginx/ssl
RUN openssl genrsa -out key.pem 2048
RUN openssl req -new -key key.pem -subj '/C=JP/ST=Tokyo/L=Tokyo-to/O=Interlink/OU=interlink/CN=sovolo.local' -out csr.pem
RUN openssl x509 -days 3650 -req -signkey key.pem < csr.pem > cert.pem
RUN mv key.pem /etc/nginx/ssl/
RUN mv cert.pem /etc/nginx/ssl/
RUN rm csr.pem

# add (the rest of) our code
COPY . /home/docker/code/

# install django, normally you would remove this step because your project would already
# be installed in the code/app/ directory
# RUN django-admin.py startproject website /home/docker/code/app/ 


EXPOSE 80 443 8000
CMD ["supervisord", "-n"]
