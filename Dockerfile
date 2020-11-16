# builder
# compiles the dart scripts.
FROM ubuntu:20.04 as builder


RUN apt update  && apt install --no-install-recommends -y \
    ca-certificates \
    git \
    gnupg2 \
    openssh-client \
    wget 


# install dcli
# The `nginx-le build -u` command updates this file to force an upgrade of dcli
COPY update-dcli.txt  /dev/nul
RUN wget https://github.com/bsutton/dcli/releases/download/latest-linux/dcli_install
RUN chmod +x dcli_install
RUN ./dcli_install
ENV PATH="${PATH}:/usr/lib/dart/bin:/root/.pub-cache/bin"

RUN dcli version


RUN mkdir -p /home/build/container/bin/cerbot_hooks
RUN mkdir -p /home/build/container/lib

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
    nginx \
    openssl \
    software-properties-common \
    tzdata \
    vim \
    certbot \
    python3-certbot-dns-cloudflare \
    logrotate \
    gzip


# config nginx 
RUN useradd nginx

# setup nginx log files.
RUN mkdir -p /var/nginx
# make certain the log file exists so the LogsCommand works without errors.
RUN touch /var/nginx/error.log
RUN touch /var/nginx/access.log

# we have two alternate configurations. 
# custom where a user of this container places the content they wish to serve.
# acquire used when we don't have a cert and need to place the server it aquisition mode.
RUN mkdir /etc/nginx/custom
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

RUN mkdir -p /etc/letsencrypt/config/live

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
COPY container/nginx_config/etc/nginx/custom/ /etc/nginx/custom
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

