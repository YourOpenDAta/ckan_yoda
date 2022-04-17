# See CKAN docs on installation from Docker Compose on usage
FROM ubuntu:focal

# Set timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set arg

ARG CKAN_VERSION
ARG CKAN_BASE_URL=https://github.com/ckan/ckan/archive/refs/tags
ARG CKAN_CODE_PATH=${CKAN_BASE_URL}/ckan-${CKAN_VERSION}.zip

# # Setting the locale
# ENV LC_ALL=en_US.UTF-8       
# RUN apt-get update
# RUN apt-get install --no-install-recommends -y locales
# RUN sed -i "/$LC_ALL/s/^# //g" /etc/locale.gen
# RUN dpkg-reconfigure --frontend=noninteractive locales 
# RUN update-locale LANG=${LC_ALL}

# Install required system packages
RUN apt-get -q -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade \
    && apt-get -q -y install \
        curl \
        unzip \
        python3.8 \
        python3-dev \
        python3-pip \
        python3-venv \
        python3-wheel \
        libpq-dev \
        libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
        postgresql-client \
        build-essential \
        git-core \
        vim \
        wget \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/*

# Define environment variables
ENV CKAN_HOME=/usr/lib/ckan
ENV CKAN_VENV=$CKAN_HOME/venv
ENV CKAN_CONFIG=/etc/ckan
ENV CKAN_STORAGE_PATH=/var/lib/ckan

# Build-time variables specified by docker-compose.yml / .env
ARG CKAN_SITE_URL

# Create ckan user
RUN useradd -r -u 900 -m -c "ckan account" -d $CKAN_HOME -s /bin/false ckan

# Setup virtual environment for CKAN
RUN mkdir -p $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH && \
    python3 -m venv $CKAN_VENV && \
    ln -s $CKAN_VENV/bin/pip3 /usr/local/bin/ckan-pip3 &&\
    ln -s $CKAN_VENV/bin/ckan /usr/local/bin/ckan

# Virtual environment binaries/scripts to be used first
ENV PATH=${CKAN_VENV}/bin:${PATH}

# Download CKAN
RUN mkdir $CKAN_VENV/src \
   && curl -fSL ${CKAN_CODE_PATH} -o $CKAN_VENV/src/ckan.zip \
    && unzip $CKAN_VENV/src/ckan.zip -d $CKAN_VENV/src \
    && rm $CKAN_VENV/src/ckan.zip \
   && mv $CKAN_VENV/src/ckan-ckan-${CKAN_VERSION} $CKAN_VENV/src/ckan

# Setup CKAN
RUN ckan-pip3 install -U pip && \
    ckan-pip3 install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirement-setuptools.txt && \
    ckan-pip3 install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirements.txt && \
    ckan-pip3 install -e $CKAN_VENV/src/ckan/ && \
    ln -s $CKAN_VENV/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini

# Download extensions
RUN cd $CKAN_VENV/src/ && \
    # ckanext-harvest
    ckan-pip3 install -e git+https://github.com/ckan/ckanext-harvest.git@v1.3.4#egg=ckanext-harvest && \
    ckan-pip3 install --upgrade --no-cache-dir -r ckanext-harvest/pip-requirements.txt && \
    # ckan-pip3 install --upgrade --no-cache-dir -r ckanext-harvest/dev-requirements.txt && \
    # ckanext-dcat
    ckan-pip3 install urllib3 && \
    ckan-pip3 install -e git+https://github.com/ckan/ckanext-dcat.git@v1.1.3#egg=ckanext-dcat && \
    ckan-pip3 install --upgrade --no-cache-dir -r ckanext-dcat/requirements.txt && \
    #ckan-pip3 install --upgrade --no-cache-dir -r ckanext-dcat/dev-requirements.txt && \
    #ckanext-dcatpapedp
    ckan-pip3 install -e git+https://github.com/YourOpenDAta/ckanext-dcatapedp.git@alpha#egg=ckanext-dcatapedp && \
    ckan-pip3 install --upgrade --no-cache-dir -r ckanext-dcatapedp/requirements.txt
    #ckan-pip3 install --upgrade --no-cache-dir -r ckanext-dcat/dev-requirements.txt && \

ADD ckan_${CKAN_VERSION}/ckan-entrypoint.sh /ckan-entrypoint.sh

RUN chmod +x /ckan-entrypoint.sh && \
    chown -R ckan:ckan $CKAN_HOME $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH

ENTRYPOINT ["/ckan-entrypoint.sh"]

USER ckan
EXPOSE 5000

#CMD sleep 300000
CMD ["ckan","-c","/etc/ckan/production.ini", "run", "--host", "0.0.0.0"]