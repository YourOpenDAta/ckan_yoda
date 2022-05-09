#!/bin/bash

path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
parent_path=$(dirname $path)
cd $parent_path
source ./.env

# Build and start environment
# list of containers: ckan_yoda, redis_yoda, solr_yoda, db_yoda
# list of volumes: ckan_yoda_ckan_config, ckan_yoda_ckan_home, ckan_yoda_ckan_storage, ckan_yoda_pg_data, ckan_yoda_solr_data

# Find the path to a named volume
docker volume inspect ckan_yoda_ckan_home | jq -c '.[] | .Mountpoint'
# "/var/lib/docker/volumes/docker_ckan_config/_data"

export VOL_CKAN_HOME=`docker volume inspect ckan_yoda_ckan_home | jq -r -c '.[] | .Mountpoint'`
echo $VOL_CKAN_HOME

export VOL_CKAN_CONFIG=`docker volume inspect ckan_yoda_ckan_config | jq -r -c '.[] | .Mountpoint'`
echo $VOL_CKAN_CONFIG

export VOL_CKAN_STORAGE=`docker volume inspect ckan_yoda_ckan_storage | jq -r -c '.[] | .Mountpoint'`
echo $VOL_CKAN_STORAGE

# configure datastore
docker exec ckan_yoda /usr/local/bin/ckan-paster --plugin=ckan datastore set-permissions -c /etc/ckan/production.ini | docker exec -i db_yoda psql -U ckan

# create sysadmin account
docker exec -it ckan_yoda /usr/local/bin/ckan-paster --plugin=ckan sysadmin -c /etc/ckan/production.ini add $ADMIN_USER_CKAN email=$ADMIN_USER_CKAN_EMAIL name=$ADMIN_USER_CKAN_NAME password=$ADMIN_USER_CKAN_PASS

# configure ckanext-harvest extension
docker exec -it ckan_yoda /usr/local/bin/ckan-paster --plugin=ckanext-harvest harvester initdb --config=/etc/ckan/production.ini

# update production.ini
docker exec -it ckan_yoda /usr/local/bin/ckan-paster --plugin=ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.plugins= stats text_view image_view recline_view datastore dcat dcat_rdf_harvester dcat_json_harvester dcat_json_interface structured_data harvest ckan_harvester oaipmh_edp' 'ckanext.dcat.rdf.profiles = euro_dcat_ap edp_dcat_ap' 'ckanext.dcat.base_uri = http://example.com' 'ckan.harvest.mq.type = redis'


docker-compose -f ./docker-compose.yml restart ckan


# docker exec -it ckan_yoda /usr/local/bin/ckan-paster --plugin=ckan create-test-data -c /etc/ckan/production.ini


#http://localhost:5000/

