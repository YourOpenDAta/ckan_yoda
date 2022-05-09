#!/bin/bash
path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
parent_path=$(dirname $path)
cd $parent_path
source ./.env

# Build and start environment
# list of containers: ckan_etsit, redis_etsit, solr_etsit, db_etsit
# list of volumes: ckan_etsit_ckan_config, ckan_etsit_ckan_home, ckan_etsit_ckan_storage, ckan_etsit_pg_data, ckan_etsit_solr_data

# Find the path to a named volume
docker volume inspect ckan_etsit_ckan_home | jq -c '.[] | .Mountpoint'
# "/var/lib/docker/volumes/docker_ckan_config/_data"

export VOL_CKAN_HOME=`docker volume inspect ckan_etsit_ckan_home | jq -r -c '.[] | .Mountpoint'`
echo $VOL_CKAN_HOME

export VOL_CKAN_CONFIG=`docker volume inspect ckan_etsit_ckan_config | jq -r -c '.[] | .Mountpoint'`
echo $VOL_CKAN_CONFIG

export VOL_CKAN_STORAGE=`docker volume inspect ckan_etsit_ckan_storage | jq -r -c '.[] | .Mountpoint'`
echo $VOL_CKAN_STORAGE

# configure datastore
docker exec ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini datastore set-permissions | docker exec -i db_etsit psql -U ckan

# create sysadmin account
docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini sysadmin add $ADMIN_USER_CKAN email=$ADMIN_USER_CKAN_EMAIL name=$ADMIN_USER_CKAN_NAME password=$ADMIN_USER_CKAN_PASS

# update production.ini
docker exec -it ckan_etsit /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.plugins= stats text_view image_view recline_view datastore dcat dcat_rdf_harvester dcat_json_harvester dcat_json_interface structured_data harvest ckan_harvester oaipmh_edp' 'ckanext.dcat.rdf.profiles = euro_dcat_ap edp_dcat_ap' 'ckanext.dcat.base_uri = http://example.com' 'ckan.harvest.mq.type = redis'

# configure ckanext-harvest extension
docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini harvester initdb


docker-compose -f ./docker-compose.yml restart ckan

#create test data but it does not save them in the database
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini seed basic
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini seed family
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini seed gov
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini seed hierarchy
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini seed search
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini seed translations
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini seed user
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini seed vocabs

## Dump database
## inside docker container (only dumps one database in this case ckan but not the datastore one)
# pg_dump -U ckan --format=custom -d ckan > ckan.dump

## Restore database
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini db clean
## inside db_etsit docker container
 
# pg_restore --clean --if-exists -d ckan < ckan.dump
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini search-index rebuild

## Clean database
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini db clean

## Init database from scratch
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini search-index rebuild
# docker exec -it ckan_etsit /usr/local/bin/ckan -c /etc/ckan/production.ini db init


#http://localhost:5000/