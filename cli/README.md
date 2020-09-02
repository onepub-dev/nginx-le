# Nginx-LE

Nginx-LE provides a docker container and tools to create an Nginx web server with Lets Encrypt built in.

LetsEncrypt uses the cli tool Certbot to acquire certificates.  Nginx-LE automates the configuration and running of Certbot and Nginx.
This documenation tends to use the terms LetsEncrypt and Certbot somewhat interchangably.

Nginx-LE supports both public facing web servers and private (internal) web servers such as those used by individual developers.

The key advantages of Nginx-LE are:
* automatical certificate acquisition and renewal
* no down time when renewing certificates
* for Public facing servers, works with any DNS server

## Automatic renewal

Both Public facing and internal Private Web Servers wiil have their certificates automatically renewed.

## No down time.
Nginx-LE is able to renew a certificate WITHOUT taking your web server offline. 

Nginx-LE leaves your web server fully operational whilst it acquires or renews a certificate.
Once a new certificate is available it perform an Nginx `reload` command which 
is close to instantaneous.


# Public Web Server

A Public Web Servers is where the Web Server exposes port 80 and 443 on a public IP address with a public DNS A record (e.g. host.mydomain.com resolves to the webservers IP address).

For Public Web Servers Nginx-LE uses the standard Certbot HTTP auth mechanism.

Lets Encrypt certificates are automatically acquired and renewed.

A public web server may be behind a NAT however it MUST have port 80 open to the world to allow certbot to validate the server.

# Private Web Server

For a Private web server (one with no public internet access) Nginx-LE using the certbot DNS auth method.

Nginx-LE will need to make an `outbound` connection (TCP port 443) to the `Lets Encrypt` and the hoster of your DNS servers but no inbound connection is required.

Note: At this point the `private` mode only works with a `NameCheap` dns server as that is the only api we currently support.

# Nginx-LE cli tooling

Nginx-LE provides cli tooling to manage your Nginx-LE instance.

The cli tooling is based on dart and the DCli library.

To install the cli tooling:

1) Install dcli

(install guide)[https://github.com/bsutton/dcli/wiki/Installing-DCli]

2) activate Nginx-LE

`pub global activate nginx_le`

On linux this amounts to:
```
sudo apt-get update
sudo apt-get install --no-install-recommends -y wget ca-certificates gnupg2
wget https://raw.githubusercontent.com/bsutton/dcli/master/bin/linux/dcli_install
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
| build| Builds the docker image. | Only required if you need to customise the image.
| config | Configures nginx-le and creates the docker container.| You must run config before you can run any other commands (except build).
| start | Starts nginx-le | Starts the nginx-le docker container
| restart | Restarts nginx-le | Restarts the docker container
| stop | Stops nginx-le | Stops the docker container.
| acquire | Acquires or renews a Lets Encrypt certificate | The method use depends on the mode selected when you ran `nginx-le config`
| revoke | Revokes the current Lets Encrypt certificate | Full certificate revocation. You need to run revoke/acquire if you change the type of certificate between production and staging.
| cli | Attaches you to the Docker container in a bash shell. | Play inside the nginx-le docker container.
| logs | Tails various logs in the container | 


# Building Nginx-LE

Most users of Nginx-LE will never need to run a build. The build tooling is primarily used by the Nginx-LE development team and if you need to customize the Nginx-LE Dockerfile.


However if you want to customise the Nginx-LE Dockerfile then you m

To build Nginx-LE install the Nginx-LE cli tools as noted above.

You can use the Nginx-LE image in a number of ways.

| Method | Usage|
| :---- |:----
| Serve static content | Mount a volume with your static content into /opt/nginx/wwwroot
| Configure your own Location(s) | Add nginx compatible `.location` files under /opt/nginx/include
| Configure as Proxy | Add nginx compatible `.location` and `.upstream` files under /opt/nginx/include
| Extend the Image | Create your own Dockerfile based on Nginx-LE.
| Docker-compose | Add Nginx-LE as a service in a docker-compose.yaml file.

Before you build your container you need to create your Dockerfile. See the section below on [Create a Dockerfile](#create-a-dockerfile)

To build the Nginx-LE image run:
```
git clone https://github.com/bsutton/nginx-le.git
nginx-le build --tag=<repo/image:version>
```

## Switches

### image
The requried `--image` switch sets the docker image/tag name (repo/image:version) for the image.

e.g. --image=noojee/nginx-le:1.0.0

The switch can be abbreviated to `-i`.


### update-dcli
The optonal flag `--update-dcli` causes the build to pull the latest version of dart/dcli rather than using the docker cache instance.

You only need to add this switch if you have an existing build and you need to update the dcli/dart version.

### debug
The optional flag `--debug` outputs additional build information.

The flag can be abbreviated to `-d`.

# Configure Nginx-LE
Use the `nginx-le config` command to configure you Nginx-LE container.

When you run config, Nginx-LE will destroy and create a new container with the new settings.


## Start Method
Select the method by which you are going to start Nginx-LE
| Method&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;| Description |
| :---------------- | ---|
| nginx-le start| The simplest method. `nginx-le config` will create a container. Use `nginx-le start` and `nginx-le stop` to start/stop the container.
| docker start | `nginx-le config` will create a container. Use `docker start` and `docker stop` to start/stop the container.
| docker-compose up | `docker-compose up` will create and start the container. You must specify a number of environment variables and volumes in the docker-compose.yaml file to configure Nginx-LE. You must have started the container with `docker-compose` at least once before running `nginx-le config`. Use `docker-compose up` and `docker-compose down` to start/stop the container.

The `config` command saves each of the entered settings so that you don't have to pass them when running other commands.

## Content Provider
The configure command also lets you setup how the content is to be served. 

Nginx-LE supports four types of Content Providers

| Provider | Description  |
| ----| ----- | ----- |
| Static | Serve static web content from a local folder.  |
| Generic Proxy | Pass requests through to a Web Application server that can respond to HTTP requests. This is normally on the same host as the Nginx-LE server as the connnection is not encrypted.
| Tomcat Proxy | Pass requests to a local Tomcat web application server on port 8080.
| Custom | Allows you to configure your own Nginx location and upstream settings.
|

## Auth Provider
To acquire a LetsEncrypt certificate you must be able to prove that you own the domain for which the certificate is being issued.

Nginx-LE supports a number of Certbot Authentication methods.

| Auth Provider | Usage Case | Description
| ----| ---- |----
| HTTP01Auth | For a public webserver using a FQDN certificate. | Your webserver must be accessible on a public ip address.  This the simpliest form of validation as it works with any DNS provider.
| cloudflare | For public and private webservers. Supports FQDN and wildcard certificates. | The most flexible auth provider your DNS must be hosted with Cloudflare.
| namecheap| For public and private webservers. Supports FQDN and wildcard certificates. | Not recommended. The namecheap api is dangerous and currently limited to domains that have no more than 10 A records.





## Mode
Nginx-LE supports to web server modes, public and private.

### public mode
If you are running in public mode the server will acquire a certificate using HTTP auth. This requires that nginx-le is exposed to the public internet on both port 80 and port 443.



## private mode
You need to run in private mode if you Nginx-LE server is not directly connected to the public internet.   

You can still use public mode if you are behind a NAT

When running in private mode you also need to run the [acquire](#acquire) command described below.


## Switches

### fqnd
The required `--fqdn` switch specifies the fully qualified domain name (FQDN) of the host that the certificate will be issued for.

The FQDN must much a valid DNS entry on a public facing DNS server.

### tld
The required `--tld` switch specifies top level domain name (TLD) of the host e.g. use `com.au` if your fqdn is `example.com.au`.


### mode
The required  `--mode` switch tells Nginx-LE whether your web server is access from the internet and therefore controls
how certificate renewal is performed.

There are two values supported by `--mode`

`private` - the server is not access from the internet and cerbot will use DNS validation.

`public` - the server is accessible from the internet and certbot will use HTTPS validation.

e.g. --mode=public

The switch can be abbreviated to `-m`.


### image
The required `--image` switch specifics which docker image to use. This should be the same name you passed to the `--image` switch when you ran the build.


### emailaddress
The required `--emailaddress` switch is used to send email notifications when errors occur.

e.g. --emailaddress=support@example.com

The switch can be abbreviated to `-e`.

### name
The optional `--name` switch allows you to name your container which will allow you to start it by name.

e.g. --name=examplengix

The switch can be abbreviated to `-n`.
## Content Source
When configuring Nginx-LE you will be prompted to choose the source of the content.

This may be a simple wwwroot mounted from a local host folder or you can provide location and upstream files if you need to process an application server or have serveral root folders.

### Simple wwwroot
During configuration select 'Simple wwwroot' when prompted for the `Content Source`.

Enter the path to the root folder.

By default Nginx-LE will create a location file on the host system at `/opt/nginx/include/wwwroot.location` on the `host` system and then mount that location into the Nginx-LE container.

You can modify the default file if it doesn't suit your requirements.

### Locations
During configuration select 'Locations' when prompted for the `Content Source`.

Nginx-LE will configure nginx to include location files from the host system at `/opt/nginx/include/*.location`. This directory is mounted into the container at the same location.

You can place any number of nginx location files in this directory and they will be mounted the next time that the Nginx-LE container is started or nginx is reloaded (you can do this from within the docker cli).

This is an example location file for proxying the java Tomcat server

```
location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_redirect off;
        proxy_max_temp_file_size 0;
        proxy_pass http://tomcat/;
    }
```

### Upstream servers

If you are using Nginx-LE as a proxy server for an application server then you will need to provide one or more `.upstream` files to configure the connection to those servers.

Nginx-LE will  include the upstream files from the host system at `/opt/nginx/include/*.upstream`. This directory is mounted into the container at the same location.

You can place any number of nginx upstream files in this directory and they will be mounted the next time that the Nginx-LE container is started or nginx is reloaded (you can do this from within the docker cli).

This is an example upstream file for proxying the java Tomcat server
```
upstream tomcat {
    server 127.0.0.1:8080 fail_timeout=0;
}
```

# Start with docker-compose

If you change your dock-compose configuration then docker-compose will recreate the container. When this occurs you MUST re-run `nginx-le config` and select the new container.

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
      MODE: public
      EMAIL_ADDRESS: support@example.com
      DEBUG: "true"
    volumes:
      - certificates:/etc/letsencrypt
      - /opt/nginx/include:/etc/nginx/include
    logging:
      driver: "journald"
```

The `Mode` must be `public` or `private`.  If `public` is selected then certbot uses http auth. if `private` is selected then certbot uses DNS auth.

## Volumes
The `certificates` volume is used to store the certbot certificates between restarts.
The `/opt/nginx/include` host path is where you place the nginx `.location` and `.upstream` includes.

# Starting Nginx-LE

Before starting Nginx-LE you must first run `nginx-le config`.

To start the Nginx-LE container run:
```bash
nginx-le start
```

When you first start your Nginx-LE container it won't have a certificate.

When Nginx-LE detects that it doesn't have a vaid certificate it will enter certificate acquistion mode.

In this mode it will display a default 'Certificate Acquistion Required' home page with instructions on obtaining a certificate.




# Acquiring/Renewing certificates
## Public Mode

For Nginx-LE containers that were built with the `--mode=public` switch certificate aquisition and renewal is automatic.

Simply start your Nginx-LE container and it will acquire a certificate and renew it as required.

Unlike `private` mode Nginx-LE `public` mode works with ANY dns provider.

Nginx-LE will check if a renew is required every 13 hours. Certbot will renew a certificate if its within 30 days of expiring.


## Private Mode

Note: Nginx-LE currently only supports the NameCheap DNS api for acquiring certificates in `private` mode.

WARNING: We would not recommend NameCheap for production DNS servers as their api requires us to replace EVERY DNS entry to create a single DSN entry.
A failure of Nginx-LE could result in your DNS becoming corrupted.
Additionally this method only supports DNS servers with no more than 10 Host entries. This is a limit of Nginx-LE as we haven't worked out how to use the NameCheap POST option for updating the DNS entries (as it doesn't appear to be documented).

As such we only recommend `private` mode for developer machines using a non-production domain.

> Just acquire a cheap random domain name for use by your development team and host it with NameCheap


### Acquire a certificate
When running in `private` mode you must run the `acquire` command to acquire a certificate.


To acquire a certificate using a NameCheap DNS server using the `acquire` command:

e.g.

`nginx-le acquire --containerid=XXXXX namecheap --ask`


Note: The `acquire` command can take 5 minutes+ to acquire a certificate due to delays in DNS propergation.


The NameCheap Api requires an apiKey and apiUsername. This need to be held securely
and as such can't be saved to disk.

## containerid switch
The docker containerid to attach to.

Either this switch or the --name switch must be passed.

e.g.
--containerid=XXXXX

## staging switch
Lets Encrypt puts fairly tight constraints on the number of times you can request a certificate for a given domain (5 per day).

During testing we recommend that you use there staging certificates as the limts are much higher

The optional `--staging` flag allows you to select the Lets Encrypt staging server.


## ask switch
The `--ask` will prompt you to enter the apikey and the apiusername.

## env switch
The `--env` switch requires you to place the `apikey` and `apiusername` into to environment variables:

```bash
export NAMECHEAP_API_KEY=xxxxxx
export NAMECHEAP_API_USERNAME=yyyy
```

Note: the namecheap api username is the same username you use to log in to the NameCheap admin console.

Nginx-LE will then acquire the certificate and then transition into standard operating mode (e.g. it will start serving your website).

Once you have run the `acquire` command Nginx-LE will be able to automatically renew certificates until you shutdown the server.

## Automating certificate renewal in Private Mode
You can run the `acquire` command after running the `start` command even if Nginx-LE already has a certificate. 

If you run the `acquire` command after ever `start` then Nginx-LE server can automaically renew certificates as required.

This command sequence starts the container and passes it the NameCheap credentials to allow it to renew as required.

```bash
export NAMECHEAP_API_KEY=xxxxxx
export NAMECHEAP_API_USERNAME=yyyy
nginx-le start 
nginx-le acquire 

```

During development you should probaly just use the start command as you don't want to be storing you creditials in a script.

On a daily bases use the `start` command and only use the `acquire namecheap --ask` option every few months when a renewal is required.

## Internals
Nginx-LE stores cerificates on a persisten volume which by convention is called `certificates`. 

The `certificates` folder is mounted into the containers `/etc/letsencrypt/` folder.


# Create a dockerfile

By default the Nginx-LE ships with the following configuration files:

The base nginx configuration is defined by:

* /etc/nginx/nginx.conf
* /etc/nginx/custom/defaults.conf

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

You can also modify the `nginx.conf` if you have specialised requirements.

If you modify `nginx.conf` there are several options that MUST not change.

* daemon off;
* user nginx;
* include /etc/nginx/live/default.conf

Changing any of the above settings will cause nginx-le to fail.

## Whats with this 'live' directory

The nginx.conf loads its configuration from the `/etc/nginx/live/defaults.conf` file.

However the above instructions dictate that you put your `default.conf`  in `/etc/nginx/custom/defaults.conf`

Note: the difference `custom` vs `live`.

At runtime Nginx-LE pulls its configuration from the `live` directory.

On startup, if you have a valid certificate, the `live` directory is symlinked to your `/etc/nginx/custom` directory.

If you don't have a valid certificate, the `live` directory is symlinked to to the `acquire` folder and Nginx-LE is placed into acquisition mode.



The `acquire` path contains a single `index.html` page informing you that a certificate needs to be acquired. In this mode no other content will be served and only requests from certbot will be processed.

This allows `nginx` to start and then `nginx-le` can then you can run the `acquire` command to obtain a valid certificate.

Once a valid certificate has been acquired `nginx-le` switches the `live` symlink back to `/etc/nginx/custom` and does a `nginx` reload and your site is online.


# Environment variables
Nginx-LE use the following environment variables to control the containers operation:

If you are using Docker Compose or creating your own Docker container then you will need to set the appropriate environement variables.

If you use `nginx-le config` to create the docker container then it automatically sets the environment variables.

| Name | Type | Domain | Description |
| ----- | ---- | ---- | ---- |
| DEBUG | bool |  true\|false | Controls the logging level of Nginx-LE.
| HOSTNAME | String | A valid host name| The host name of the web server. e.g. www
| DOMAIN | String | A valid domain name | The domain name of the web server. e.g. microsoft.com.au
| TLD | String | Top level domain name | The top level domain name of the web server. e.g. com.au
| EMAIL_ADDRESS | String | valid email address| The email address that errors are sent to and also passed to Certbot.
| MODE | String | public \| private | 
| STAGING | bool | true\|false| True to use a 'test' certbot certificate. Recommended during testing.
| DOMAIN_WILDCARD|bool| true \|false| Controls whether we acquire a single FQDN certificate or a domain wildcard certificate.
| AUTO_ACQUIRE | bool| true\|false| Defaults to true. If true Nginx-LE will automatically 
| CERTBOT_AUTH_PROVIDER | String |  HTTP01Auth \| cloudflare \| namecheap| Select the Certbot Authentication method. 
|SMTP_SERVER| String | FQDN or IP| The FQDN or IP of the SMTP server Nginx-LE is to use to send error emails via.
|SMTP_SERVER_PORT| int | Port no.| Defaults to 25, The tcp port no.of the SMTP server Nginx-LE is to use to send error emails via.

## Internal enviornment variables
Nginx-LE uses a no. of internal environmet variables primarily to communicate with Auth providers.
You do not normally need to worry about these as the Nginx-LE `acquire` command sets these as necessary based on the select Auth Provider.

| Name | Type | Domain | Description |
| ----- | ---- | ---- | ---- |
| LETSENCRYPT_ROOT_ENV | String | Path | Path to the letsencrypt root directory which defaults to: `/etc/letsencrypt`. You don't normally need to alter this. Its primary purpose is for Unit Testing.
| LOG_FILE | String | Path | The name of the logfile that certbot writes to. We also write our log messages to this 
| NGINX_CERT_ROOT_OVERWRITE | String | Path | Only used for Unit Testing. Sets the path where certbot saves certificates to.
| CERTBOT_VERBOSE | String | true \| false | Used by the `acquire` command to control the log level of the Certbot Auth and Cleanup hooks.
| CERTBOT_DNS_AUTH_HOOK_PATH | String | Path | Path to the DNS auth hook if we are using one of the DNS Auth providers. This is set by the `acquire` co
| CERTBOT_DNS_CLEANUP_HOOK_PATH | String |Path | Path to the DNS auth hook cleanup script.
| CERTBOT_HTTP_AUTH_HOOK_PATH | String | Path |Path to the HTTP auth hook
| CERTBOT_HTTP_CLEANUP_HOOK_PATH | String | Path |Path to the HTTP auth hook cleanup script.
| DNS_RETRIES | int | Integer |The number of times the DNS Auth Hook will check the DNS for the required TXT record.
| NGINX_ACCESS_LOG_ENV | String |Path | Path to the Nginx access.log file in the container.
| NGINX_ERROR_LOG_ENV | String | Path |Path to the Nginx error.log file in the container
| NGINX_LOCATION_INCLUDE_PATH | String |Path | Path of the .location and .upstream files.



## Certbot environment variables.
Certbot sets a number of environment variables during the auth process to communicate to the Auth and Cleanup hooks. You don't need to set this but if you are writing a custom auth or cleanup hook they are available to the hook.


| Name | Type | Domain | Description |
| ----- | ---- | ---- | ---- |
| CERTBOT_TOKEN | String | Token | Generated by Certbot during the auth process for the Auth and Cleanup hooks. You do not need to set this.
| CERTBOT_VALIDATION | String
| CERTBOT_DOMAIN | String | Will be the same as DOMAIN but required by Certbot


## Auth provider
Nginx-LE supports a number of auth providers. Each auth provider has its on method of configuration.

## HTTP01 Auth
This is the default Certbot authentication method and only works if your web server is exposed on a public IP address with ports 80 and 443 open.

HTTP01 Auth does not support wildcard certificates.

Set the following environement variables

CERTBOT_AUTH_PROVIDER=HTTP01Auth
Mode=public
WILD_CARD=false


## Namecheap
We don't recommend using this provider.

The Namecheap API is very crappy and requires that we update EVERY dns record to just modifiy a single record.

It is also currently limited to domains that have no more than 10 A records. This could be fixed but changing the requst from a HTTP GET to a POST but unfortunately Namecheap haven't documented the POST method.

CERTBOT_AUTH_PROVIDER=namecheap
NAMECHEAP_API_KEY=<name cheap Api Key>
NAMECHEAP_API_USER=<name cheap user>
Mode=public|private
DOMAIN_WILDCARD=true|false


## Cloudflare

This is the most versitile auth provider as its supports public and private websites as well as Wildcard and single FQDN certificates.

CERTBOT_AUTH_PROVIDER=cloudflare
CLOUDFLARE_API_TOKEN=<api token for cloudflare>
EMAIL_ADDRESS=<email address used to acquire api token>
Mode=public|private
DOMAIN_WILDCARD=true|false



# Releasing Nginx-le
If you are involved in developing Nginx-LE you will get to the point where you need to make a release.

The easists way to release Nginx-LE is to use the release-all.dart script in cli/tools

```
cd cli
tool/release_all.dart
```

Select the appropriate version no. when prompted and the release_all script will do the reset.

## release details 

There are four components that need to be released

The three dart components:
nginx-le/cli
nginx-le/container
nginx-le/shared

You must update the version no.s so that they all match.

You must also publish nginx-le/shared first as the other to packages can't be published until the `shared` package is released.

Finally you need to publish the Nginx-LE docker image using:

docker push 
