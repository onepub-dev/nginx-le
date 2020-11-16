# Nginx-LE

Nginx-LE provides a docker container and tools to create an Nginx web server that automatically acquires and renews HTTPS certificates.

Nginx-LE uses the LetsEncrypt cli tool, Certbot, to acquire and renew certificates. 

Nginx-LE ships as a Docker image which you can use with Docker or Docker Compose.

You can optionally use Nginx-LE cli tooling which allows you to configure and build Nginx-LE containers in a couple of seconds.

Nginx-LE is suitable for production systems, internal infrastructure and even when a developer needs a web server on their local machine.

This documentation tends to use the terms LetsEncrypt and Certbot somewhat interchangeably.

Nginx-LE supports both public facing web servers and private (internal) web servers such as those used by individual developers.

The key advantages of Nginx-LE are:
* automatic certificate acquisition and renewal
* no down time when renewing certificates
* for Public facing servers, works with any DNS server
* support for wildcard certificates
* makes it easy for a developer to acquire a live certificate.

# Prerequisites
To obtain a Lets Encrypt certificate you must have a public DNS record for your host.

For a production web server this isn't a problem as it will already meet the prerequisites.

For an internal private web server such as those used for running internal infrastructure or an individual developers PC this can be a little tricker.

For a private web server you will still need to create a public DNS A record.

For a private web server we need to do DNS authentication which means that you need to be using a DNS provider from list of DNS providers that Nginx-LE supports.

The simplest way to do this is to acquire the cheapest domain name that you can find.
Host the domain name with Cloudflare (host is free for the volumes involved).

For each developer or internal web server create a DNS A record. The IP address you use in the DNS A record does NOT have to be a public IP address. You can just use any private IP address. I would suggest that you don't use any of your real internal ip addresses to avoid exposing information about your internal network.

Now that you have a DNS A record are ready to acquire live certificates.

## Automatic renewal

Nginx-LE supports the automatic renewal of both Public and  Private Web Servers.

## No down time.
Nginx-LE is able to renew a certificate WITHOUT taking your web server offline. 

Nginx-LE leaves your web server fully operational whilst it acquires or renews a certificate.
After acquiring or renewing a certificate Nginx-LE performs an Nginx `reload` command which 
is close to instantaneous.

# Quick Start

The following guide takes you through building an Nginx-LE server on your local machine.

To complete this process you will need 

# Public Web Server

A Public Web Servers is where the Web Server exposes port 80 and 443 on a public IP address with a public DNS A record (e.g. host.mydomain.com resolves to the web server's IP address).

For Public Web Servers Nginx-LE uses the standard Certbot HTTP01Auth mechanism.

Lets Encrypt certificates are automatically acquired and renewed.

A public web server may be behind a NAT however it MUST have port 80 and 43 open to the world to allow certbot to validate the server.

Unfortunately you can't restrict the IP range that your web server takes requests from as Certbot does not publish the IP addresses it uses.

If this is a problem for you then you should use one of DNS Auth methods as these do not require your web server to expose any ports.


# Private Web Server

For a Private web server (one with no public internet access) Nginx-LE using the certbot DNS auth method.

Nginx-LE will need to make an `outbound` connection (TCP port 443) to the `Lets Encrypt` servers and the hoster of your DNS servers. No inbound connection is required.

# Deploying Nginx-LE

Nginx-LE is designed to be flexible in how you go about building and deploying your container.

| Method | Use case | Notes
| ---- | ---- | ----
|nginx-le config | Fastest way to get a server running | Prompts you for all the core information required to build a web server and then creates a Nginx-LE container based on your responses. Use `nginx-le start` to start your web server.
| docker-compose | Configure you container via environment variables | A natural fit if you are currently using docker-compose for deployment.
| docker create | The hard way| Manually set up all of the required environment variables and then create your container.
| Customise Image | When you need to modify the Nginx-LE docker image | Allows you to customise your image and add additional tools into the container.|
| Build | You need to modify the source or detailed Nginx configuration | This is the DIY route. Get the big hammer out.

# Nginx-LE cli tooling

Nginx-LE provides optional cli tooling to manage your Nginx-LE instance.

The cli tooling is based on dart and the DCli library.

To install the cli tooling:

(If you already have dart installed you can go straight to step 3.)

1) Install dcli  [install guide](https://github.com/bsutton/dcli/wiki/Installing-DCli)

2) Restart your terminal

3) activate Nginx-LE

`pub global activate nginx_le`

On linux this amounts to:
```
sudo apt-get update
sudo apt-get install --no-install-recommends -y wget ca-certificates gnupg2
wget https://github.com/bsutton/dcli/releases/download/latest-linux/dcli_install -O dcli_install
chmod +x dcli_install
export PATH="$PATH":"$HOME/.pub-cache/bin":"$HOME/.dcli/bin"
./dcli_install
pub global activate nginx_le
```

The DCli installer also installs dart (if its not already installed).

## cli commands

The Nginx-LE cli exposes the following commands:

| Command | Description | Comment
| ------ |:------|:-----
| build| Builds the docker image. | Only required if you need to customise the code the image runs on.
| config | Configures nginx-le and creates the docker container.| You must run config before you can run any other commands (except build).
| start | Starts nginx-le | Starts the nginx-le docker container
| restart | Restarts nginx-le | Restarts the docker container
| stop | Stops nginx-le | Stops the docker container.
| acquire | Acquires or renews a Lets Encrypt certificate | The method used to acquire a certificate depends on the Auth Provider selected when you ran `nginx-le config`. If you are using the AUTO_ACQUIRE mode then this action happens automatically.
| revoke | Revokes the current Lets Encrypt certificate | Full certificate revocation. You need to run revoke/acquire if you change the type of certificate between production and staging.
| cli | Attaches you to the Docker container in a bash shell. | Play inside the nginx-le docker container.
| logs | Tails various logs in the container | 

Example of running Nginx-LE command

```bash
nginx-le config
```


# Building Nginx-LE

Most users of Nginx-LE will never need to run a build. The build tooling is primarily used by the Nginx-LE development team and if you need to customize the code that underpins the Nginx-LE docker image.

When do you need to use the build command?

| Method | Build Required | Usage| 
| :---- |:---- | :----
| Customise nginx or the Nginx-LE code| Yes| Get your hands dirty and modify the core of Nginx-LE.
| Extend the Image | Maybe| Create your own Dockerfile based on Nginx-LE. You can use the standard docker tools to build the image if you aren't modifying any of the Nginx-LE code.
| Serve static content | No | Mount a volume with your static content into /opt/nginx/wwwroot
| Configure your own Location(s) | No | Add nginx compatible `.location` files under /opt/nginx/include
| Configure as Proxy | No | Add nginx compatible `.location` and `.upstream` files under /opt/nginx/include
| Docker-compose | No | Add Nginx-LE as a service in a docker-compose.yaml file.

For details on creating or modifying the docker file see [Create aDockerfile](#create-a-dockerfile)

To build the Nginx-LE image run:
```
git clone https://github.com/bsutton/nginx-le.git
nginx-le build --image=<repo/image:version>
```

## Switches
The build command takes a number of switches.

### image
The required `--image` switch sets the docker image/tag name (repo/image:version) for the image.

e.g. --image=noojee/nginx-le:1.0.0

The switch can be abbreviated to `-i`.


### update-dcli
The optional flag `--update-dcli` causes the build to pull the latest version of dart/dcli rather than using the docker cache instance.

You only need to add this switch if you have an existing build and you need to update the dcli/dart version.

### debug
The optional flag `--debug` outputs additional build information.

The flag can be abbreviated to `-d`.

# Configure Nginx-LE
Use the `nginx-le config` command to configure you Nginx-LE container.

When you run config, Nginx-LE will destroy and create a new container with the new settings.


## Start Method
Select the method by which you are going to start Nginx-LE
| Method| Description |
| ---------------- | --- |
| nginx-le start| The simplest method. `nginx-le config` will create a container. Use `nginx-le start` and `nginx-le stop` to start/stop the container.
| docker start | `nginx-le config` will create a container. Use `docker start` and `docker stop` to start/stop the container.
| docker-compose up | `docker-compose up` will create and start the container. You must specify a number of environment variables and volumes in the docker-compose.yaml file to configure Nginx-LE. You must have started the container with `docker-compose` at least once before running `nginx-le config`. Use `docker-compose up` and `docker-compose down` to start/stop the container. Technically you don't need to run `nginx-le config` if you are using docker-compose. Running the config command is required if you want to use the other nginx-le commands but for many users this won't be necessary.

The `config` command saves each of the entered settings so that you don't have to pass them when running other commands.

## Content Provider
The configure command lets you set how the content is to be served. 

Nginx-LE supports four types of Content Providers

| Provider | Description  |
| ---- | ----- | ----- |
| Static | Serve static web content from a local folder.  |
| Generic Proxy | Pass requests through to a Web Application server that can respond to HTTP requests. This is normally on the same host as the Nginx-LE server as the connection is not encrypted.
| Tomcat Proxy | Pass requests to a local Tomcat web application server on port 8080.
| Custom | Allows you to configure your own Nginx location and upstream settings.
|


### Static Content Provider
The static Content Provider allows you to serve static content from a local directory (e.g. index.html)

The Static Content Provider will request the path to your static content and the default html file.

### Generic Proxy Content Provider
The Generic proxy Content Provider allows you to proxy requests through to a web application server.

The Nginx-LE container exposes the secure HTTPS connection and then passes all requests through to your web application server via HTTP.

Please note that normally you need to select a port other than 80 as Nginx-LE needs to accept requests on port 80 for certificate acquisition and renewals.

### Tomcat Proxy Content Provider
Designed to work with the java based Tomcat Web application Server.

The Tomcat proxy allows you to configure the port and context the Tomcat server operates on.

### Custom Content Provider
The Customer Content Provider allows you to configure your own Location and Upstream files as described below:

#### Locations
Nginx defines a location as a provider of content (web pages or a http/https endpoint). 

Nginx-le provides a number of default providers and also allows you to create your own custom location files.

By default Nginx-LE:
* configures Nginx to look for the location files (within the container) in: `/etc/nginx/include`.
* mounts the host path `/opt/nginx/include` into the container path `/etc/nginx/include`.

If you use a Custom Content Provider you get to create your own Location and Upstream files and choose the path to the host directory where the location and upstream files are stored.

You can place any number of nginx location files in the host directory and they will be mounted the next time that the Nginx-LE container is started or nginx is reloaded.

This is an example location file for proxying the java Tomcat server.

This location file requires an upstream file (see the example below) to be functional.

```
location / {
        #try_files $uri $uri/ =404;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_redirect off;
        proxy_max_temp_file_size 0;
        proxy_pass http://tomcat/mycontext/;
        proxy_read_timeout 300;
}

location /mycontext {
        #try_files $uri $uri/ =404;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_redirect off;
        proxy_max_temp_file_size 0;
        proxy_pass http://tomcat/mycontext/;
        proxy_read_timeout 300;
}
```

#### Upstream servers

If you are using Nginx-LE as a proxy server for an application server then you will need to provide one or more `.upstream` files to configure the connection to those servers.

Nginx-LE supports a number of common application server configurations (see Content Providers) and for the supported application servers will automatically create the necessary `.upstream` files.


By default Nginx-LE:
* configures Nginx to look for the upstream files (within the container) in: `/etc/nginx/include`.
* mounts the host path `/opt/nginx/include` into the container path `/etc/nginx/include`.


Nginx-LE will include any `*.upstream` files from the host system.

You can place any number of nginx upstream files in this directory and they will be mounted the next time that the Nginx-LE container is started or nginx is reloaded.

This is an example upstream file for proxying the java Tomcat server
```
upstream tomcat {
    server 127.0.0.1:8080 fail_timeout=0;
}
```

## Auth Providers
To acquire a LetsEncrypt certificate you must be able to prove that you own the domain for which the certificate is being issued.

Nginx-LE supports a number of Certbot Authentication methods.

| Auth Provider | Usage Case | Description
| ----| ---- |----
| HTTP01Auth | For a public web server using a FQDN certificate. | Your web server must be accessible on a public ip address.  This is the simplest form of validation as it works with any DNS provider.
| cloudflare | For public and private web servers. Supports FQDN and wildcard certificates. | The most flexible auth provider, your DNS must be hosted with Cloudflare.
| namecheap| For public and private web servers. Supports FQDN and wildcard certificates. | Not recommended. The namecheap api is dangerous and currently limited to domains that have no more than 10 A records.

## Start Paused
The start paused option is mainly used by the Nginx-LE team for diagnosing startup issues.

When you place Nginx-LE into start paused mode it will not start the nginx server nor attempt to acquire a certificate.

Once you start Nginx-LE in paused mode you can attach to the Nginx-LE docker container and explore its configuration. 

You can connect to the Nginx-LE container (even when not in paused mode) by running `nginx-le cli`.


# Start with docker-compose

May users deploy their docker containers using docker-compose. In these circumstances using the Nginx-LE cli tools may not be appropriate.

This is the case for most production systems, in which case you will just use the standard docker management tools.

Whilst it can be useful to run `nginx-le config` it is not required.

If you want to use any of the 'nginx-le' cli tooling (except for build) then you do need to run `nginx-le config`.

Note: 
If you do want to use `nginx-le config` then if you change your dock-compose configuration, docker-compose will recreate the container. 

When this occurs you MUST re-run `nginx-le config` and select the new container.

To start Nginx-LE with docker-compose you must provide a number of configuration settings:

The following is a sample configuration:

```
ginx-le:
    container_name: nginx-le
    image: noojee/nginx-le:1.0.5
    restart: on-failure
    ports:
      - "80:80"
      - "443:443"
    network_mode: "host"
    environment: 
      HOSTNAME: www
      DOMAIN: example.com.au
      TLD: com.au
      DOMAIN_WILD_CARD=false
      PRODUCTION=true
      EMAIL_ADDRESS: support@example.com
      AUTO_ACQUIRE=true
      DEBUG: "true"
      AUTH_PROVIDER=cloudflare
      AUTH_PROVIDER_TOKEN=XXXXXXX
      AUTH_PROVIDER_EMAIL_ADDRESS=XXX@XXXXX
      SMTP_SERVER=smtp.someserver.com
      SMTP_SERVER_PORT=25
    volumes:
      - certificates:/etc/letsencrypt
      - /opt/nginx/include:/etc/nginx/include
    logging:
      driver: "journald"
```

The environment variables for the Auth Provider will change based on which Auth Provider you have selected.


## Volumes
The `certificates` volume is used to store the certbot certificates between restarts.
The `/opt/nginx/include` host path is where you place the nginx `.location` and `.upstream` includes.

# Starting Nginx-LE

If you are using the Nginx-LE cli tools then before starting Nginx-LE you must first run `nginx-le config`.

If you are not using the Nginx-LE cli tools then follow the standard docker, docker-compose processes.

To start the Nginx-LE container run:
```bash
nginx-le start
```

However you start Nginx-LE, when you first start the Nginx-LE container it won't have a certificate.

If you have set AUTO_ACQUIRE=true then Nginx-Le will automatically acquire a certificate.

If you have set AUTO_ACQUIRE=false then when Nginx-LE detects that it doesn't have a valid certificate it will enter certificate acquisition mode.

In this mode it will display a default 'Certificate Acquisition Required' home page with instructions on obtaining a certificate.

You then need to run the `nginx-le acquire` command.


# Acquiring/Renewing certificates
## Public Mode

Public mode is only suitable for web servers which are directly accessible on the internet.

To be considered directly accessible it MUST:

* Be able to accept requests on a public IP address.

* Both port 80 and 443 must be exposed on the above public IP address.

The public access can be via a NAT, proxy or other suitable mechanism.

If your Nginx-LE web server is in public mode then you can use the HTTP01Auth Auth Provider method unless you need a wildcard.

If you need to acquire a wild card certificate (*.nginx.com) then you must use one of the DNS auth methods.

There is no specific setting required on the Nginx-LE container for public mode, it simply limits which Auth Providers you can choose from.

## Private Mode

Private mode is only suitable for any web servers but some Auth Providers don't support Private Mode servers.

A Private mode web server is one that doesn't isn't accessible from the public internet. A development, test or internal web server will typically be private.

A Private web server must still have port 443 open (but only visible locally -be that your dev PC or your office network) however port 80 is not required.

If your Nginx-LE web server is in private mode then you can NOT use the HTTP01Auth method. You must use one of the DNS Auth Providers.

You will still need to have a valid DNS entry for your web server on a public DNS provider that is supported by one of Nginx-LE's DNS Auth Providers.

The IP address of the DNS A record does not need to be valid and can be a private IP address. The IP address is not used.


### Acquire a certificate
If you set the environment variable AUTO_ACQUIRE=true then Nginx-LE will automatically acquire and renew certificates as required.

If you don't pass the AUTO_ACQUIRE environment variable or set it to false than you must manually acquire a certificate.

NOTE: we strongly recommend using AUTO_ACQUIRE and don't know of any valid reason why you would not.

If you are using the Nginx-LE cli tools then use:

To acquire a certificate use  `nginx-le acquire` command:

e.g.

`nginx-le acquire`


Note: The `acquire` command can take upto 5 minutes+ to acquire a certificate due to delays in DNS propagation.


If you have rolled your own Docker or docker-compose configuration then you can still use the cli tools if you first run `nginx-le config`. 

If you can't use the Nginx-LE cli tools then you can still use the 'in-container' tools.

To manually acquire a command first attached to the Nginx-LE container.

The run:

```
acquire
```

Once you have run `acquire` Nginx-LE will automatically renew certificates.


## Using a Staging certificate
Lets Encrypt puts fairly tight constraints on the number of times you can request a certificate for a given domain (5 per day).

During testing we recommend that you use a Lets Encrypt staging certificate as the limits are much higher.

The environment variable 'PRODUCTION' controls whether you are using a Staging or Production certificate.

Once you have run the `acquire` command Nginx-LE will be able to automatically renew certificates until you shutdown the server.


## Internals
Nginx-LE stores certificates on a persistent volume which by convention is called `certificates`. 

The `certificates` folder is mounted into the containers `/etc/letsencrypt/` folder.

It is critical that this is a persistent volume otherwise Nginx-LE will need to acquire a new certificate every time it starts. 

Lets Encrypt have hard limits (5 per day) on the no. of certificates you can acquire so if you don't have a persistant volume you will very quickly breach this limit.


# Customising the Dockerfile

In some circumstances it may be required that you modify the standard Dockerfile that Nginx-LE ships with.

This section details the internal structure of the docker image and what the hard requirements are.

By default the Nginx-LE ships with the following configuration files:

The base nginx configuration is defined by:

* /etc/nginx/nginx.conf
* /etc/nginx/custom/defaults.conf

The `nginx.conf` is the first configuration file that nginx loads which then chains the `default.conf` file which in turn loads our standard `.location` and `.upstream` files.

If you are happy with the standard configuration you can simply add `.location` and `.upstream`files under `/opt/nginx/include`.

Otherwise you can replace the `/etc/nginx/custom/default.conf` with your own customised defaults.

NOTE: if you replace `default.conf` you MUST include a `./well-known` location for lets-encrypt to work:
```
  # lets encrypt renewal path
    location ^~ /.well-known {
      allow all;
      root  /opt/letsencrypt/wwwroot;
    }
```    

The nginx-le container REQUIRES that you have a default.conf file in:

* /etc/nginx/custom/default.conf

If you need complete control over nginx then you can also replace the `nginx-conf` file.

If you modify the `nginx.conf` it must include the following lines:

* daemon off;
* user nginx;
* include /etc/nginx/live/default.conf 

Changing any of the above settings will cause nginx-le to fail.

## What's with this 'live' directory

The `nginx.conf` loads its configuration from the `/etc/nginx/live/defaults.conf` file.

However the above instructions dictate that you put your `default.conf`  in `/etc/nginx/custom/defaults.conf`

Note: the difference `custom` vs `live`.

At runtime Nginx-LE pulls its configuration from the `live` directory.

On startup, if you have a valid certificate, the `live` directory is symlinked to your `/etc/nginx/custom` directory.

If you don't have a valid certificate, the `live` directory is symlinked to the `acquire` folder and Nginx-LE is placed into acquisition mode.


The `acquire` path contains a single `index.html` page informing you that a certificate needs to be acquired. In this mode no other content will be served and only requests from certbot will be processed.

This allows `nginx` to start and then `nginx-le` can then you can run the `acquire` command to obtain a valid certificate.

Its important to note here that we do this because `nginx` will not start if you don't have a valid certificate and it has been configured to start a HTTPS service.

Once a valid certificate has been acquired `nginx-le` switches the `live` symlink back to `/etc/nginx/custom` and does a `nginx` reload and your site is online.


# Environment variables
Nginx-LE use the following environment variables to control the containers operation:

If you are using Docker Compose or creating your own Docker container then you will need to set the appropriate environment variables.

If you use `nginx-le config` to create the docker container then it automatically sets the required environment variables.

| Name | Type | Domain | Description |
| ----- | ---- | ---- | ---- |
| DEBUG | bool |  true\|false | Controls the logging level of Nginx-LE.
| HOSTNAME | String | A valid host name| The host name of the web server. e.g. www
| DOMAIN | String | A valid domain name | The domain name of the web server. e.g. microsoft.com.au
| TLD | String | Top level domain name | The top level domain name of the web server. e.g. com.au
| EMAIL_ADDRESS | String | valid email address| The email address that errors are sent to and also passed to Certbot which will use the email address to send renewal reminders to.
| PRODUCTION | bool | true\|false| True to use a 'production' certbot certificate. False will acquire a Staging (test) certificate. We recommend that you set this to false during testing.
| DOMAIN_WILDCARD|bool| true \|false| Controls whether we acquire a single FQDN certificate or a domain wildcard certificate. Set to true to obtain a wild card domain. If you use this option on a number of servers which use the same domain then you will quickly hit the Certbot rate limits.
| AUTO_ACQUIRE | bool| true\|false| Defaults to true. If true Nginx-LE will automatically acquire a certificate.
| AUTH_PROVIDER | String |  HTTP01Auth \| cloudflare \| namecheap| Select the Certbot Authentication method. 
| SMTP_SERVER| String | FQDN or IP| The FQDN or IP of the SMTP server Nginx-LE is to use to send error emails via. Currently we only support email servers that don't require authentication.
| SMTP_SERVER_PORT| int | Port no.| Defaults to 25, The tcp port no.of the SMTP server Nginx-LE is to use to send error emails via.
| START_PAUSED | bool | true \|false | If true then the docker container will start but it won't try to start nginx or acquire a certificate. This mode is intended to help diagnose startup problems. Use nginx-le cli to attach to the container.
| AUTH_PROVIDER_TOKEN | String | Auth Provider token | If the Auth Provider requires a TOKEN then this will be used to hold it.
| AUTH_PROVIDER_USERNAME| String | Auth Provider username | If the Auth Provider requires a username then this will be used to hold it.
| AUTH_PROVIDER_PASSWORD | String | Auth Provider password | If the Auth Provider requires a password then this will be used to hold it.
| AUTH_PROVIDER_EMAIL_ADDRESS | String | Auth Provider Email Address | If the Auth Provider requires an email address that differs from `EMAIL_ADDRESS` then this will be used to hold it.
| CERTBOT_IGNORE_BLOCK| bool | true\|false | If an error occurs when attempting to acquire a certificate, a flag file is written into /etc/letsencrypt to stop further auto acquistion attempts. This is done to avoid hitting Certbot rate limits which can occur if we keep retrying due to a permanent failure. If you are are sure you deployments never fail and don't want temporary errors to stop auto acquisition then you can pass this environment variable (with a value of true) in which case the normal auto acquistion will occure regardless of the existance of the flag. The block flag file automatically times out after 15 minutes.

## Internal environment variables
Nginx-LE uses a no. of internal environment variables primarily to communicate with Auth providers.
You do not normally need to worry about these as the Nginx-LE sets these as necessary based on the selected Auth Provider.

| Name | Type | Domain | Description |
| ----- | ---- | ---- | ---- |
| LOG_FILE | String | Path | The name of the logfile that certbot writes to. We also redirect the auth providers to write to this log file.
| CERTBOT_ROOT_PATH | String | Path | Path to the letsencrypt root directory which defaults to: `/etc/letsencrypt`. You don't normally need to alter this. Its primary purpose is for Unit Testing.
| CERTBOT_VERBOSE | String | true \| false | Used by the `acquire` command to control the log level of the Certbot Auth and Cleanup hooks.
| CERTBOT_AUTH_HOOK_PATH | String | Path | Path to the auth_hook script provided as part of nginx-le. The auth hook is called by certbot at the start of an attempt to acquire or renew a certificate.
| CERTBOT_CLEANUP_HOOK_PATH | String |Path | Path to the cleanup_hook script provided as part of nginx-le. The cleanup hook is called by certbot when completing an attempt to acquire or renew a certificate.
| CERTBOT_DEPLOY_HOOK| String | Path to the deploy_hook script provided as part of nginx-le. The deploy hook is called by certbot to deploy certificates into nginx. Its is only called when a certificate is sucessfully renewed or acquired.
| DNS_RETRIES | int | Integer |The number of times the DNS Auth Hook will check the DNS for the required TXT record.
| NGINX_CERT_ROOT_OVERWRITE | String | Path | Only used for Unit Testing. Sets the path where certbot saves certificates to.
| NGINX_ACCESS_LOG_PATH | String |Path | Path to the Nginx access.log file in the container.
| NGINX_ERROR_LOG_PATH | String | Path |Path to the Nginx error.log file in the container
| NGINX_LOCATION_INCLUDE_PATH | String |Path | Path of the .location and .upstream files.



## Certbot environment variables.
Certbot sets a number of environment variables during the auth process to communicate to the Auth and Cleanup hooks. You don't need to set this but if you are writing a custom auth or cleanup hook they are available to the hook.


| Name | Type | Domain | Description |
| ----- | ---- | ---- | ---- |
| CERTBOT_TOKEN | String | Filename | Used only by HTTP01Auth. This is the name of the file that the CERTBOT_VALIDATION string must be written into e.g. .well-known/acme-challenge/$CERTBOT_TOKEN
| CERTBOT_VALIDATION | String | Generated by Certbot|This is the validation string Certbot generates to verify ownership of your domain. For DNS Auth Providers this is written into a TXT record on your DNS server. For HTTP01Auth this is written int the CERTBOT_TOKEN file.
| CERTBOT_DOMAIN | String | Domain name |Will be the same as DOMAIN but required by Certbot


## Auth provider
Nginx-LE supports a number of auth providers. Each auth provider has its on method of configuration.

## HTTP01 Auth
This is the default Certbot authentication method and only works if your web server is exposed on a public IP address with ports 80 and 443 open.

HTTP01 Auth does not support wildcard certificates.

Set the following environment variables:

AUTH_PROVIDER=HTTP01Auth

DOMAIN_WILDCARD=false


## Namecheap
We don't recommend using this provider.

The Namecheap API is very crappy and requires that we update EVERY dns record to just modify a single record.

It is also currently limited to domains that have no more than 10 A records. This could be fixed by changing the request from a HTTP GET to a POST but unfortunately Namecheap hasn't documented the POST method.

AUTH_PROVIDER=namecheap

AUTH_PROVIDER_TOKEN=name cheap Api Key

AUTH_PROVIDER_USERNAME=name cheap username

DOMAIN_WILDCARD=true|false


## Cloudflare

This is the most versatile auth provider as it supports public and private websites as well as Wildcard and single FQDN certificates.

NOTE: currently we only support using a cloudflare global access token.  A restricted API token will NOT WORK.
This is due to ubuntu 20.04 using an old version of certbot. When a newer version is available we will upgrade to support the restricted access token.

AUTH_PROVIDER=cloudflare

AUTH_PROVIDER_TOKEN=api token for cloudflare

AUTH_PROVIDER_EMAIL_ADDRESS=email address used to acquire api token

DOMAIN_WILDCARD=true|false



# Releasing Nginx-le
If you are involved in developing Nginx-LE you will get to the point where you need to make a release.

The easiest way to release Nginx-LE is to use the release-all.dart script in cli/tools

```
cd cli
tool/release_all.dart
```

Select the appropriate version no. when prompted and the release_all script will do the rest.

## release details 

There are four components that need to be released

The three dart components:
nginx-le/cli
nginx-le/container
nginx-le/shared

You must update the version no.s so that they all match.

You must also publish nginx-le/shared first as the other two packages can't be published until the `shared` package is released.

Finally you need to publish the Nginx-LE docker image using:

docker push 

# Implementing Auth Providers

Currently Nginx-LE ships with a limited no. of Auth Providers.

We would welcome contributions of additional Auth Providers.

Certbot currentlyt supports a number of DNS Auth Providers that could be added to Nginx-LE with a fairly low effort.

You can see the list of Certbot Auth Providers here:

https://certbot.eff.org/docs/using.html#dns-plugins

To add a new Auth Providers the following changes would need to be made:

1) Update Dockerfile

Modify the Nginx-LE docker file by changing the `apt install` command to include the additional packages required to support the selected Certbot Auth provider.

Find the following section.

```docker
RUN apt  update && apt install --no-install-recommends -y \
    ca-certificates \
    certbot \
    dnsutils \
    gnupg \
    nginx \
    openssl \
    python3-certbot-dns-cloudflare \
    python3-certbot-nginx \
    software-properties-common \
    tzdata \
    vim
```    

Additional packages as required.


2) Implement an Auth Provider

We provide a base class AuthProvider. Your new Auth Provider should be derived from this class.

```
shared/lib/src/auth_provider.dart
```

The shared/lib/src/auth_providers/dns_auth_providers/cloudlfare/cloudflare_provider.dart provider should be a good example to work from.

3) Register your new Auth Provider

Add you new auth provider to the AuthProviders class:

shared/lib/src/auth_providers/auth_providers.dart

Find this section:

```dart
  /// Add new auth providers to this list.
  var providers = <AuthProvider>[
    HTTPAuthProvider(),
    NameCheapAuthProvider(),
    CloudFlareProvider()
  ];
```

4) Build Nginx-LE

`nginx-le build --image=repo/image:version`

5) Run config

Run `nginx-le config` to confirm that you new provider is listed.

6) Raise a PR on our github page.

job done.


