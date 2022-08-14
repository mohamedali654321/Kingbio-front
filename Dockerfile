##last_update: 24-04-2022

FROM ubuntu:20.04

#Configure time zone variable:
ENV TZ=Asia/Riyadh

#Configure NODE_OPTIONS:
ENV NODE_OPTIONS="--max-old-space-size=8192"

#Set Pre dspace Info ARGs ,so you can pass dspace info at build time(when to build an image):
ARG DS_UI_HOST=0.0.0.0
ARG DS_UI_PORT=4000
ARG DS_UI_SSL=false
ARG DS_REST_HOST=localhost
ARG DS_REST_PORT=6060
ARG DS_REST_SSL=false
ARG DEFAULT_LANGUAGE=ar

#Set Pre Dspace Info ENVs ,so you can pass dspace info at a run time(when to run a container):
ENV DS_UI_HOST=${DS_UI_HOST}
ENV DS_UI_PORT=${DS_UI_PORT}
ENV DS_UI_SSL=${DS_UI_SSL}
ENV DS_REST_HOST=${DS_REST_HOST}
ENV DS_REST_PORT=${DS_REST_PORT}
ENV DS_REST_SSL=${DS_REST_SSL}
ENV DEFAULT_LANGUAGE=${DEFAULT_LANGUAGE}

#Install time zone(useful for installing postgresql):
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
 && apt update \
 && apt install -y tzdata

#Install general packages and dependencies:
RUN apt-get update && apt-get -y install gettext nginx nano supervisor git wget software-properties-common curl nodejs npm \
    && apt-get update && npm install n -g && n lts

#Install Yarn:
RUN wget --quiet -O - https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && add-apt-repository "deb https://dl.yarnpkg.com/debian/ stable main" \
    && apt-get update \
    && apt-get -y install yarn \
    && npm install -g cross-env

#Create defualt working directories:
RUN mkdir -p /usr/local/dspace7 /dspace_build_files /var/log/supervisor /etc/supervisor/conf.d

#Set defualt working directory:
WORKDIR /usr/local/dspace7

#Add config files to working directory:
ADD . /usr/local/dspace7

WORKDIR /usr/local/dspace7/source
RUN envsubst < "/usr/local/dspace7/pre_config_files/config.prod.yml" > "/usr/local/dspace7/source/config/config.prod.yml"
RUN yarn install \
    && yarn add @blueprintjs/icons url url.js \
    && npm list html-webpack-plugin || npm install html-webpack-plugin \
    && yarn run build:mirador \
    && yarn run build:prod

##After mounting dspace root dir to a volume which is the empty folder at the first time##
## so we need to copy the installed files agin into the root dir##
RUN cp -R /usr/local/dspace7/source/* /dspace_build_files \
    #Copy supervisor config file:
    && cp /usr/local/dspace7/pre_config_files/supervisor.conf /etc/supervisor.conf

#Expose app port:
EXPOSE 4000

#RUN dspace-angular ui && dspace pre-configuration scripts from supervisord:
CMD ["supervisord", "-c", "/etc/supervisor.conf"]
