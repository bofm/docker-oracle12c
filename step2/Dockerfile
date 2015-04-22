FROM bofm/oracle12c:installed
MAINTAINER bofm

RUN mkdir /data && chmod 777 /data
COPY db_template.dbc /tmp/
COPY colorecho /bin/
COPY entrypoint.sh /bin/
COPY entrypoint_oracle.sh /bin/
COPY create_database.sh /tmp/
EXPOSE 1521
ENTRYPOINT ["entrypoint.sh"]
CMD ["database", "--shm"]
