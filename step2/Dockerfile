FROM bofm/oracle12c:installed
MAINTAINER bofm

RUN mkdir /data && chmod 777 /data
COPY db_template.dbt /tmp/
COPY colorecho /bin/
COPY entrypoint.sh /bin/
COPY entrypoint_oracle.sh /bin/
COPY create_database.sh ora_env /tmp/
EXPOSE 1521
ENTRYPOINT ["entrypoint.sh"]
CMD ["database", "--shm"]
