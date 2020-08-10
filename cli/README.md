# Nginx-LE

Nginx-LE provides a docker container and tools to create an Nginx web server with Lets Encrypt built in.

Nginx-LE supports both public facing web servers and private (internal) web servers such as those used by individual developers.

The key advantages of Nginx-LE are:
* automatical certificate acquisition and renewal
* no down time when renewing certificates
* for Public facing servers, works with any DNS server


The key disadvantage
* for Private servers we only support NameCheap.
* currently supports a max of 10 Private servers

## Automatic renewal

Both Public facing and internal Private Web Servers wiil have their certificates automatically renewed.

## No down time.
Nginx-LE is able to renew certificate WITHOUT taking your web server offline. 

Nginx-LE leaves your web server fully operational whilst it acquires or renews a certificate.
Once a new certificate is available it perform an Nginx `reload` command which 
is close to instantaneous.


# Public Web Server

Public Web Servers is where the Web Server exposes port 80 and 443 on a public IP address.

For Public Web Servers Nginx-LE uses the standard Certbot HTTP auth mechanism.

Lets Encrypt certificates are automatically renewed.

A public web server may be behind a NAT however it MUST have port 80 open to the world to allow certbot to validate the server.

# Private Web Server

For a private web server (one with no public internet access) Nginx-LE using the certbot DNS auth method.

Nginx-LE will need to make an `outbound` connection to the `Lets Encrypt` server but no inbound connection is required.

Note: At this point the `private` mode only works with a `NameCheap` dns server as that is the only api we currently support.

# Nginx-LE cli tooling

Nginx-LE provides cli tooling to manage your Nginx-LE instance.

The cli tooling is based on dart and the DShell library.

To install the cli tooling:

1) Install dshell

(install guide)[https://github.com/bsutton/dshell/wiki/Installing-DShell]

2) activate Nginx-LE

`pub global activate nginx_le`




On linux this amounts to:
```
sudo apt-get update
sudo apt-get install --no-install-recommends -y wget ca-certificates gnupg2
wget https://raw.githubusercontent.com/bsutton/dshell/master/bin/linux/dshell_install
chmod +x dshell_install
export PATH="$PATH":"$HOME/.pub-cache/bin":"$HOME/.dshell/bin"
./dshell_install
pub global activate nginx_le
```

The DShell installer also installs dart (if its not already installed).

## cli commands

The Nginx-LE cli exposes the following commands:

| Command | Description | Comment
| ------ |:------|:-----
| build| Builds the docker image. | Only required if you need to customise the image.
| config | Configures the server settings | You must run config before you can run any other commands.
| start | Starts nginx-le | Starts the Docker container for a specific FQDN
| restart | Restarts nginx-le | Restarts the docker container
| stop | Stops nginx-le | Stops the docker container.
| acquire | Acquires or renews a Lets Encrypt certificate | The method use depends on the --mode switch used via `start`
| revoke | Revokes the current Lets Encrypt certificate | Full certificate revocation.
| cli | Attaches you to the Docker container in a bash shell. | Play inside the nginx-le docker container.
| logs | Tails the 


# Building Nginx-LE

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
nginx-le build --tag=<repo/image:version>
```

## Switches

### image
The requried `--image` switch sets the docker image/tag name (repo/image:version) for the image.

e.g. --image=noojee/nginx-le:1.0.0

The switch can be abbreviated to `-i`.


### update-dshell
The optonal flag `--update-dshell` causes the build to pull the latest version of dart/dshell rather than using the docker cache instance.

You only need to add this switch if you have an existing build and you need to update the dshell/dart version.

### debug
The optional flag `--debug` outputs additional build information.

The flag can be abbreviated to `-d`.

# Configure Nginx-LE
Use the `nginx-le config` command to configure you Nginx-LE container.




Select the method by which you are going to start Nginx-LE
| Method&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;| Description |
| :---------------- | ---|
| nginx-le start| The simplest method. `nginx-le config` will create a container. Use `nginx-le start` and `nginx-le stop` to start/stop the container.
| docker start | `nginx-le config` will create a container. Use `docker start` and `docker stop` to start/stop the container.
| docker-compose up | `docker-compose up` will create and start the container. You must specify a number of environment variables and volumes in the docker-compose.yaml file to configure Nginx-LE. You must have started the container with `docker-compose` at least once before running `nginx-le config`. Use `docker-compose up` and `docker-compose down` to start/stop the container.

The configure command saves a number settings so that you don't have to pass them when running other commands.

The configure command also lets you setup where the content is to be served. Nginx-LE provides for both a simple wwwroot path
as well as configuring a set of location and upstream servers.

-- If you are running a server in private mode it also requests a password to encrypt your DNS server api keys so that you don't have to re-enter the keys each time you want to acquire a certificate.

e.g.

```bash
nginx-le config 
```

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


On startup the `live` directory is symlinked to your `/etc/nginx/custom` directory.

This allows nginx-le to change the `live` folder to point to the `acquire` path when in `certificate acquistion` mode.

When configured for SSL, nginx will fail on start if you don't have a valid certificates.

To get around this problem, on startup nginx-le checks if you have active certificates. If you don't it placess the container
into `acquire` mode.

nginx-le does this by changing the `live` symlink to point to the `/etc/nginx/acquire` directory.

The `acquire` path contains a single `index.html` page informing you that a certificate needs to be acquired. In this mode no other content will be served and only requests from certbot will be processed.

This allows `nginx` to start and then `nginx-le` can then you can run the `acquire` command to obtain a valid certificate.

Once a valid certificate has been acquired `nginx-le` switches the `live` symlink back to `/etc/nginx/custom` and does a `nginx` reload and your site is online.



