### This is only for testing purposes, do NOT use for production
FROM alpine 

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/http\:\/\/mirror.clarkson.edu/g' /etc/apk/repositories

ADD dist/ /root/dist/

RUN apk update

# Install packages
RUN apk -U --no-cache add \
    build-base \
    coreutils \
    git \
    libffi \
    libffi-dev \
    py-gevent \
    py-pip \
    python \
    python-dev \
    sqlite

RUN pip install aiorun && \
    # Install php sandbox from git
    git clone https://github.com/rep/hpfeeds /opt/hpfeeds && \
    cd /opt/hpfeeds/hpfeeds/scripts && python broker.py || : && \
    cp /root/dist/adduser.sql . && \
    sqlite3 db.sqlite3 < adduser.sql
#python setup.py build && \
#python setup.py install && \

# Clean up
RUN apk del --purge autoconf \
    build-base \
    coreutils \
    libffi-dev \
    python-dev && \
    rm -rf /root/* && \
    rm -rf /var/cache/apk/*

# Set workdir and start glastopf
WORKDIR /opt/hpfeeds/broker
CMD python broker.py
