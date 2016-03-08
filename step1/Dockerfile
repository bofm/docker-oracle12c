FROM oraclelinux
MAINTAINER bofm

RUN yum -y install oracle-rdbms-server-12cR1-preinstall.x86_64 && \
    yum clean all && \
    rm -rf /var/lib/{cache,log} /var/log/lastlog

# Install gosu
RUN curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64' \
    && chmod +x /usr/local/bin/gosu

COPY sysctl.conf oraInst.loc /etc/
COPY limits.conf /tmp/
RUN cat /tmp/limits.conf >> /etc/security/limits.conf

ENV ORACLE_BASE=/app/oracle
ENV ORACLE_HOME=$ORACLE_BASE/product/12.1.0/dbhome_1
ENV PATH=$ORACLE_HOME/bin:$PATH
ENV NLS_DATE_FORMAT=YYYY-MM-DD\ HH24:MI:SS \
    ORACLE_DATA=/data/oracle \
    ORACLE_SID=ORCL \
    ORACLE_HOME_LISTNER=$ORACLE_HOME

COPY *.rsp install.sh install_rlwrap.sh /tmp/install/

RUN mkdir -p $ORACLE_BASE && chown -R oracle:oinstall $ORACLE_BASE && \
    chmod -R 775 $ORACLE_BASE && \
    mkdir -p /app/oraInventory && \
    chown -R oracle:oinstall /app/oraInventory && \
    chmod -R 775 /app/oraInventory && \
    chmod 664 /etc/oraInst.loc && \
    chmod a+x /tmp/install/install.sh


