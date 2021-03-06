FROM alpine 

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/http\:\/\/mirror.clarkson.edu/g' /etc/apk/repositories

# Include dist
ADD dist/ /root/dist/

# Install packages
RUN apk -U --no-cache add \
    build-base \
    git \
    libffi-dev \
    libssl1.1 \
    openssl-dev \
    python-dev \
    py-cffi \
    py-ipaddress \
    py-lxml \
    py-mysqldb \
    py-pip \
    py-pysqlite \
    py-requests \
    py-setuptools && \
    pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir pyOpenSSL xmljson

# Setup ewsposter
RUN git clone --depth=1 https://github.com/rep/hpfeeds /opt/hpfeeds && \
    cd /opt/hpfeeds && \
    python setup.py install && \
    git clone --depth=1 https://github.com/vorband/ewsposter /opt/ewsposter && \
    mkdir -p /opt/ewsposter/spool /opt/ewsposter/log

# Setup user and groups
RUN addgroup -g 2000 ews && \
    adduser -S -H -u 2000 -D -g 2000 ews && \
    chown -R ews:ews /opt/ewsposter

# Supply configs
RUN mv /root/dist/ews.cfg /opt/ewsposter/

# Clean up
RUN apk del build-base \
    git \
    openssl-dev \
    python-dev \
    py-pip \
    py-setuptools && \
    rm -rf /root/* && \
    rm -rf /var/cache/apk/*

# Run ewsposter
USER ews:ews

ADD run.sh /run.sh
CMD sleep 10 && exec /usr/bin/python -u /opt/ewsposter/ews.py -l 60