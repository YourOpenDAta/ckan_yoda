# ckan_yoda

- [ckan_yoda](#ckan_yoda)
  - [Versions](#versions)
    - [CKAN extensions](#ckan-extensions)
  - [Set-up](#set-up)
    - [Configure services](#configure-services)
    - [Create data samples (for testing)](#create-data-samples-for-testing)
    - [DRACO templates](#draco-templates)
      - [AEMET](#aemet)
  - [Architecture](#architecture)
    - [Containers and volumes](#containers-and-volumes)
  - [Links](#links)
  - [Todo](#todo)

## Versions
- CKAN 2.9.5

### CKAN extensions



## Set-up

### Configure services

1. Copy `template.env` to `.env`.
2. Set-up `.env` file.
3. Create the ckan_yoda docker network
```
docker network create ckan_yoda
```
4. Create or copy the ckan.crt, ckan.key, orion.crt, orion.key inside `proxy/ssl`
    - In development you can generate them by:
  ```
  openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout ckan.key -out ckan.crt
  openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout orion.key -out orion.crt
  ``` 
5. Build and run containers


```
# ckan and fiware
docker-compose --file docker-compose.yml --file docker-compose.fiware.yml up -d --build

# only ckan
docker-compose --file docker-compose.yml up -d --build

# only fiware
docker-compose --file docker-compose.fiware.yml up -d --build
```

6. Only the first time, configure ckan extensions

```
./ckan_{CKAN_VERSION}/configure_ckan.sh
```

7. Start reverse-proxy
```
cd proxy
docker-compose up -d --build
```
If you make any change in the proxy you have to restart it:
```
docker-compose restart proxy
```

In development you have to modify `/etc/hosts` adding the mapping of the services to the reverse proxy:
```
127.0.0.1 ckan.yoda
127.0.0.1 orion.yoda
```

8. Access to ckan or orion

```
http://ckan.yoda/
https://ckan.yoda/
http://orion.yoda/version
https://orion.yoda/version

```

### Create data samples (for testing)

```
docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini seed basic
docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini seed family
docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini seed gov
docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini seed hierarchy
docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini seed search
docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini seed translations
docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini seed user
docker exec -it ckan_yoda /usr/local/bin/ckan -c /etc/ckan/production.ini seed vocabs
```

### DRACO templates

#### AEMET

1. Load `aemet_template_orion`
2. Load `aemet_template_ckan`
   1. Add CKAN API key in `NGSIToCKANProcessor` to enable the creation of datasets, organizations and resources
3. Create subscription in `orion-ld`
```
curl -L -X POST 'http://localhost:1026/ngsi-ld/v1/subscriptions/' \
-H 'Content-Type: application/ld+json' \
--data-raw '{
  "description": "Notify me when WeatherObserved appears",
  "type": "Subscription",
  "entities": [{"type": "WeatherObserved"}],
  "watchedAttributes": ["stationCode"],
  "notification": {
    "endpoint": {
      "uri": "http://draco:5050/ld/notify/weatherObserved",
      "accept": "application/json"
    }
  },
    "@context": [
        "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
        "https://smart-data-models.github.io/dataModel.Weather/context.jsonld"
    ]
}'
```
4. Run draco processors

## Architecture

### Containers and volumes

- general   
  - environment
     - container
       - volume
  
  <br/>
Architecture elements: 
- Network: ckan_yoda
  - Proxy:
    - Maps ckan.yoda to ckan
    - Maps orion.yoda to orion (TODO)
    - CKAN environment
      - ckan_yoda (*container*)
        - /var/lib/ckan
        - /usr/lib/ckan
        - /etc/ckan
      - db_yoda (*container*)
        - /var/lib/postgresql/data
      - redis_yoda (*container*)
        - /data
      - solr_yoda (*container*)
        - /opt/solr/server/solr/ckan/data
    - FIWARE environment
      - draco_yoda (*container*)
        - /opt/nifi/nifi-current/state
        - /opt/nifi/nifi-current/conf
        - /opt/nifi/nifi-current/content_repository
        - /opt/nifi/nifi-current/database_repository
        - /opt/nifi/nifi-current/flowfile_repository
        - /opt/nifi/nifi-current/logs
        - /opt/nifi/nifi-current/provenance_repository
      - orion_yoda (*container*)
      - mongo_yoda (*container*)
        - /data/db
        - /data/configdb




## Links

Database management: [https://docs.ckan.org/en/2.9/maintaining/database-management.html](https://docs.ckan.org/en/2.9/maintaining/database-management.html)

## Todo

- [ ] Select name for the portal -> YODA  
- [ ] Select url for the portal and orion -> 
- [ ] Securization of the portal
- [ ] Test pagination in catalogue
- [ ] Improve css of the portal