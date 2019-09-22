FROM alpine

# Include dist
ADD dist/ /root/dist/

# Setup apt
RUN apk -U add \
             build-base \
             file \
             git \
             libev \
             libtool \
             libcap \
             libxslt \
             libxslt-dev \
             mariadb-dev \
             pkgconfig \
             python3 \
             python3-dev \
             py-cffi \
             py-cryptography \
             tcpdump \
             wget && \

# Setup ConPot
    git clone --depth=1 https://github.com/mushorg/conpot /opt/conpot && \
    cd /opt/conpot/ && \
    # Patch to accept ENV for MIB path
    sed -i "s/tmp_mib_dir = tempfile.mkdtemp()/tmp_mib_dir = tempfile.mkdtemp(dir=os.environ['CONPOT_TMP'])/" /opt/conpot/conpot/protocols/snmp/snmp_server.py && \
    # Change template default ports if <1024
    sed -i 's/port="2121"/port="21"/' /opt/conpot/conpot/templates/default/ftp/ftp.xml && \ 
    sed -i 's/port="8800"/port="80"/' /opt/conpot/conpot/templates/default/http/http.xml && \ 
    sed -i 's/port="6230"/port="623"/' /opt/conpot/conpot/templates/default/ipmi/ipmi.xml && \ 
    sed -i 's/port="5020"/port="502"/' /opt/conpot/conpot/templates/default/modbus/modbus.xml && \ 
    sed -i 's/port="10201"/port="102"/' /opt/conpot/conpot/templates/default/s7comm/s7comm.xml && \ 
    sed -i 's/port="16100"/port="161"/' /opt/conpot/conpot/templates/default/snmp/snmp.xml && \ 
    sed -i 's/port="6969"/port="69"/' /opt/conpot/conpot/templates/default/tftp/tftp.xml && \ 
    sed -i 's/port="16100"/port="161"/' /opt/conpot/conpot/templates/IEC104/snmp/snmp.xml && \ 
    sed -i 's/port="6230"/port="623"/' /opt/conpot/conpot/templates/ipmi/ipmi/ipmi.xml && \ 
    pip3 install --no-cache-dir -U pip setuptools && \
    pip3 install --no-cache-dir . && \
    cd / && \
    rm -rf /opt/conpot /tmp/* /var/tmp/* && \
    setcap cap_net_bind_service=+ep /usr/bin/python3.6 && \
    
# Get wireshark manuf db for scapy, setup configs, user, groups
    mkdir -p /etc/conpot /var/log/conpot /usr/share/wireshark && \
    wget https://github.com/wireshark/wireshark/raw/master/manuf -o /usr/share/wireshark/manuf && \
    cp /root/dist/conpot.cfg /etc/conpot/conpot.cfg && \
    cp -R /root/dist/templates /usr/lib/python3.6/site-packages/conpot/ && \
    addgroup -g 2000 conpot && \
    adduser -S -s /bin/ash -u 2000 -D -g 2000 conpot && \

# Clean up
    apk del --purge \
            build-base \
            cython-dev \
            file \
            git \
            libev \
            libtool \
            libxslt-dev \
            mariadb-dev \
            pkgconfig \
            python3-dev \
            py-cffi \
            wget && \
    rm -rf /root/* && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/*

# Start conpot
STOPSIGNAL SIGINT
USER conpot:conpot
CMD exec /usr/bin/conpot --temp_dir $CONPOT_TMP --template $CONPOT_TEMPLATE --logfile $CONPOT_LOG --config $CONPOT_CONFIG
