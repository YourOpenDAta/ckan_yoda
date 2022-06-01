#!/bin/bash
path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
parent_path=$(dirname $path)
cd $parent_path
source ./.env


# configure datastore
docker exec ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini datastore set-permissions | docker exec -i db_yoda psql -U ckan

# create sysadmin account
docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini sysadmin add $ADMIN_USER_CKAN email=$ADMIN_USER_CKAN_EMAIL name=$ADMIN_USER_CKAN_NAME password=$ADMIN_USER_CKAN_PASS

# update production.ini
docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.plugins= stats text_view image_view recline_view datastore dcat dcat_rdf_harvester dcat_json_harvester dcat_json_interface structured_data harvest ckan_harvester oaipmh_edp yoda_theme' 'ckanext.dcat.rdf.profiles = euro_dcat_ap edp_dcat_ap' 'ckanext.dcat.base_uri = http://example.com' 'ckan.harvest.mq.type = redis'

# configure ckanext-harvest extension
docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini harvester initdb

# configure ckan front-end settings
docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.site_title = YODA' 'ckan.site_logo = /images/logo_yoda.png' 'ckan.favicon = /images/favicon_yoda.png' 'ckan.site_description = Portal de Datos en Abierto del Proyecto YODA (Your Open DAta)'

# configure ckan internationalisation Settings
docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.locale_default = es'


docker compose -f ./docker-compose.yml restart ckan


