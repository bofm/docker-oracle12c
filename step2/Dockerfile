FROM bofm/oracle12c:installed
MAINTAINER bofm

RUN mkdir /data && chmod 777 /data
COPY db_template.dbt /tmp/
COPY colorecho /bin/
COPY entrypoint_oracle.sh /bin/
COPY create_database.sh ora_env /tmp/
RUN chmod +x /bin/entrypoint_oracle.sh /tmp/create_database.sh /tmp/ora_env /bin/colorecho
ENV PATH=$PATH:/usr/bin:/usr/local/bin
EXPOSE 1521
USER oracle
ENTRYPOINT ["entrypoint_oracle.sh"]
CMD ["database"]
