#!/bin/bash
path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
parent_path=$(dirname $path)
cd $parent_path
source ./.env


# configure datastore
docker exec ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini datastore set-permissions | docker exec -i db_yoda psql -U ckan

# create sysadmin account
docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini sysadmin add $ADMIN_USER_CKAN email=$ADMIN_USER_CKAN_EMAIL name=$ADMIN_USER_CKAN_NAME password=$ADMIN_USER_CKAN_PASS

# extensions
docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.plugins= stats text_view image_view recline_view datastore'


if [[ ${TARGET} != "dev" ]]; then
    #production extensions
    docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.plugins= stats text_view image_view recline_view datastore dcat dcat_rdf_harvester dcat_json_harvester dcat_json_interface structured_data harvest ckan_harvester oaipmh_edp yoda_theme' 'ckanext.dcat.rdf.profiles = euro_dcat_ap dcat_ap_2.0.1' 'ckan.harvest.mq.type = redis'
    docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main ckanext.dcat.base_uri=$CKAN_SITE_URL
    # configure ckanext-harvest extension
    docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini harvester initdb
fi

# configure ckan front-end settings
docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.site_title = YODA' 'ckan.site_logo = /images/logo_yoda.png' 'ckan.favicon = /images/favicon_yoda.png' 'ckan.site_description = Portal de Datos en Abierto del Proyecto YODA (Your Open DAta)'

# configure ckan internationalisation Settings
docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.locale_default = es'


if [[ ${TARGET} != "dev" ]]; then
    # log level to warning
    docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  logger_ckan 'level = WARNING'
    docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  logger_ckanext 'level = WARNING'
fi

docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.auth.user_delete_groups = false'
docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.auth.user_delete_organizations = false'
docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.auth.create_user_via_web = false'
docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.auth.public_user_details = false'
docker exec -it ckan_yoda /usr/local/bin/ckan config-tool /etc/ckan/production.ini -s  app:main 'ckan.auth.public_activity_stream_detail = false'


docker compose -f ./docker-compose.yml restart ckan


