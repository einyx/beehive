FROM alpine 

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/http\:\/\/mirror.clarkson.edu/g' /etc/apk/repositories:3.9

LABEL Name=nginx \
    Version=edge

# Include dist
ADD dist/ /root/dist/

# Get and install dependencies & packages
RUN apk -U --no-cache add \
    nginx \
    nginx-mod-http-headers-more && \
    # Setup configs
    mkdir -p /run/nginx && \
    rm -rf /etc/nginx/conf.d/* /usr/share/nginx/html/* && \
    cp /root/dist/conf/nginx.conf /etc/nginx/ && \
    cp -R /root/dist/conf/ssl /etc/nginx/ && \
    cp /root/dist/conf/beehive.conf /etc/nginx/conf.d/ && \
    cp -R /root/dist/html/ /var/lib/nginx/ && \
    # Clean up
    rm -rf /root/* && \
    rm -rf /var/cache/apk/*

# Start nginx
CMD ["nginx", "-g", "daemon off;"]