ARG DRACO_VERSION

FROM ging/fiware-draco:${DRACO_VERSION} as base

RUN rm nifi-ngsi-nar-*.nar; rm ./lib/nifi-ngsi-nar-*.nar
COPY ./processors/*.nar ./
COPY ./processors/*.nar ./lib/
COPY ./templates/*.xml ./conf/templates/

FROM base as prod
COPY ./conf/logback.xml /opt/nifi/nifi-current/conf/logback.xml

FROM base as dev