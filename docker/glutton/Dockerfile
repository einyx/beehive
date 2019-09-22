FROM alpine

# Include dist
ADD dist/ /root/dist/
  
# Setup apk
RUN apk -U --no-cache add \
                   build-base \
                   git \
                   go \
                   g++ \
                   iptables-dev \
                   libnetfilter_queue-dev \
                   libcap \
                   libpcap-dev && \

# Setup go, glutton
    export GOPATH=/opt/go/ && \
    go get -d github.com/mushorg/glutton && \
    cd /opt/go/src/github.com/satori/ && \
    rm -rf go.uuid && \ 
    git clone https://github.com/satori/go.uuid && \
    cd go.uuid && \
    git checkout v1.2.0 && \
    mv /root/dist/system.go /opt/go/src/github.com/mushorg/glutton/ && \
    cd /opt/go/src/github.com/mushorg/glutton/ && \
    make build && \
    cd / && \
    mkdir -p /opt/glutton && \
    mv /opt/go/src/github.com/mushorg/glutton/bin /opt/glutton/ && \
    mv /opt/go/src/github.com/mushorg/glutton/config /opt/glutton/ && \
    mv /opt/go/src/github.com/mushorg/glutton/rules /opt/glutton/ && \
    setcap cap_net_admin,cap_net_raw=+ep /opt/glutton/bin/server && \
    setcap cap_net_admin,cap_net_raw=+ep /sbin/xtables-multi && \

# Setup user, groups and configs
    addgroup -g 2000 glutton && \
    adduser -S -s /bin/ash -u 2000 -D -g 2000 glutton && \
    mkdir -p /var/log/glutton && \
    mv /root/dist/rules.yaml /opt/glutton/rules/ && \

# Clean up
    apk del --purge build-base \
                    git \
                    go \
                    g++ && \
    rm -rf /var/cache/apk/* \
           /opt/go \
           /root/dist

# Start glutton 
WORKDIR /opt/glutton
USER glutton:glutton
CMD exec bin/server -i $(/sbin/ip address | grep '^2: ' | awk '{ print $2 }' | tr -d [:punct:]) -l /var/log/glutton/glutton.log
