ARG DRACO_VERSION

FROM ging/fiware-draco:${DRACO_VERSION}

#RUN rm nifi-ngsi-nar-1.3.6.nar; rm ./lib/nifi-ngsi-nar-1.3.6.nar
#COPY ./processors/*.nar ./
#COPY ./processors/*.nar ./lib/
COPY ./templates/*.xml ./conf/templates/
