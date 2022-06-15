# builder
# compiles the dart scripts.
FROM ubuntu:20.04 as builder


RUN apt update  && apt install --no-install-recommends -y \
    ca-certificates \
    git \
    gnupg2 \
    openssh-client \
    wget 


# install dcli. 
# nginx-le build will update the '# flush-cache' to force a new download of dcli if the -u switch is passed
# to the build command
#RUN wget https://github.com/noojee/dcli/releases/download/latest.linux/dcli_install # flush-cache: 4a94d0b7-9d53-4f67-b5b9-56eebfd3d41c
RUN wget https://github.com/noojee/dcli/releases/download/1.18.1/dcli_install # flush-cache: 4a94d0b7-9d53-4f67-b5b9-56eebfd3d41c
RUN chmod +x dcli_install
ENV PATH="${PATH}:/usr/lib/dart/bin:/root/.pub-cache/bin"
RUN echo $PATH
RUN ./dcli_install

# looks like there is a problem with the dart archive
# not setting the execute bit on the utils which
# causes dcli compile to fail
RUN chmod +x /usr/lib/dart/bin/utils/*

RUN dcli version


RUN mkdir -p /home/build/container/bin/cerbot_hooks
RUN mkdir -p /home/build/container/lib

RUN echo 'forcing source update' # update-source: 1604d2c3-be4c-4933-871a-207857ef3212

COPY container/bin /home/build/container/bin/ 
COPY container/lib /home/build/container/lib/
COPY container/pubspec.yaml /home/build/container
COPY container/analysis_options.yaml /home/build/container

RUN mkdir -p /home/build/shared
COPY shared/bin /home/build/shared/bin/
COPY shared/lib /home/build/shared/lib/
COPY shared/pubspec.yaml /home/build/shared
COPY shared/analysis_options.yaml /home/build/shared


WORKDIR /home/build

# compile all the nginx-le tools.
RUN dcli compile container/bin/*.dart
RUN dcli compile container/bin/certbot_hooks/*.dart



# CMD ["/bin/bash"]

# Final image
FROM ubuntu:20.04

WORKDIR /

RUN mkdir -p /home
ENV HOME="/home"

# set the timezone
ENV TZ=Australia/Melbourne
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


RUN apt  update && apt install --no-install-recommends -y \
    ca-certificates \
    dnsutils \
    gnupg \
    pip \
    nginx \
    openssl \
    software-properties-common \
    tzdata \
    vim \
    python3 \
    python3-venv \
    libaugeas0 \
    logrotate \
    gzip

RUN python3 -m venv /opt/certbot/
RUN /opt/certbot/bin/pip install --upgrade pip
RUN /opt/certbot/bin/pip install certbot
RUN ln -s /opt/certbot/bin/certbot /usr/bin/certbot
RUN /opt/certbot/bin/pip install certbot-dns-cloudflare


# config nginx 
RUN useradd nginx

# setup nginx log files.
RUN mkdir -p /var/nginx
# make certain the log file exists so the LogsCommand works without errors.
RUN touch /var/nginx/error.log
RUN touch /var/nginx/access.log

# we have two alternate configurations. 
# operating where a user of this container places the content they wish to serve.
# acquire used when we don't have a cert and need to place the server it aquisition mode.
RUN mkdir /etc/nginx/operating
RUN mkdir /etc/nginx/acquire

# nginx looks here for our certs.
RUN mkdir /etc/nginx/certs

# nginx defaults.conf looks here for .location and .upstream files
# which need to be mounted via a volume mount.
RUN mkdir /etc/nginx/include

#
# install certbot 
#


ENV LETS_ENCRYPT_ROOT_PATH=/etc/letsencrypt

# root path for storing lets-encrypt certificates
# This needs to be mapped to a persistent volume
# so the certificates persist across sessions.
RUN mkdir -p /etc/letsencrypt


# create the log file so the logs command doesn't get upset.
RUN mkdir -p /etc/letsencrypt/logs
RUN touch /etc/letsencrypt/logs/letsencrypt.log

# per generate diffie helman key exchange parameters
RUN mkdir -p /etc/nginx/ssl/
RUN openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

# location for the .well-know folder certbot will interact with.
RUN mkdir -p /opt/letsencrypt/wwwroot/.well-known/acme-challenge

#
# Install the nginx-le components.
#

# create directory for nginx-le to save its runtime config.
RUN mkdir -p /etc/nginx-le

# copy the default nginx-le config in
COPY container/nginx_config/etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY container/nginx_config/etc/nginx/logrotate.conf /etc/nginx/logrotate.conf
COPY container/nginx_config/etc/nginx/operating/ /etc/nginx/operating
COPY container/nginx_config/etc/nginx/acquire/ /etc/nginx/acquire

# lograte requires group and other to not have write access.
RUN chmod 400  /etc/nginx/logrotate.conf


# copy in the nginx-le compiled tools
RUN mkdir -p /home/bin
COPY --from=builder /home/build/container/bin/service /home/bin/service
COPY --from=builder /home/build/container/bin/acquire /home/bin/acquire
COPY --from=builder /home/build/container/bin/revoke /home/bin/revoke
COPY --from=builder /home/build/container/bin/renew /home/bin/renew
COPY --from=builder /home/build/container/bin/logs /home/bin/logs
COPY --from=builder /home/build/container/bin/certificates /home/bin/certificates
COPY --from=builder /home/build/container/bin/certbot_hooks/auth_hook /home/bin/certbot_hooks/auth_hook
COPY --from=builder /home/build/container/bin/certbot_hooks/cleanup_hook /home/bin/certbot_hooks/cleanup_hook
COPY --from=builder /home/build/container/bin/certbot_hooks/deploy_hook /home/bin/certbot_hooks/deploy_hook



# define the location of the Certbot hooks
ENV CERTBOT_AUTH_HOOK_PATH="/home/bin/certbot_hooks/auth_hook"
ENV CERTBOT_CLEANUP_HOOK_PATH="/home/bin/certbot_hooks/cleanup_hook"
ENV CERTBOT_DEPLOY_HOOK_PATH="/home/bin/certbot_hooks/deploy_hook"


EXPOSE 80 443

CMD ["/home/bin/service"]

