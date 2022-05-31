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
docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.plugins= stats text_view image_view recline_view datastore dcat dcat_rdf_harvester dcat_json_harvester dcat_json_interface structured_data harvest ckan_harvester oaipmh_edp' 'ckanext.dcat.rdf.profiles = euro_dcat_ap edp_dcat_ap' 'ckanext.dcat.base_uri = http://example.com' 'ckan.harvest.mq.type = redis'

# configure ckanext-harvest extension
docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini harvester initdb


docker compose -f ./docker-compose.yml restart ckan


