FROM redis:alpine

LABEL Name=redis \
    Version=edge

# Include dist
ADD dist/ /root/dist/

# Setup apt
RUN apk -U --no-cache add redis && \ 

    cp /root/dist/redis.conf /etc && \
    rm -rf /root/* && \
    rm -rf /tmp/* /var/tmp/* && \
    rm -rf /var/cache/apk/*

# Start conpot
STOPSIGNAL SIGKILL
EXPOSE 0

USER nobody

CMD redis-server /etc/redis.conf