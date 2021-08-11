# 7.0.2
Improvements to documentation.

# 7.0.1
upgraded to docker2.

# 6.3.2
Fixed missing reload after a certificate renewal.

# 6.2.5

# 6.2.4
reveted location of yaml
move yaml

# 6.2.3
added better error handling when invalid args passed.
Added slow tag to slow running tests.
added pubrelease_multi.yaml to support multi package releases via pub_release.
Randomize the minute for renewals schedules to avoid conflicts when multiple servers
  are using wildcards and dsn validation.
Updated dependencies to released version (post nnbd).
Modified the method we use to force docker to download the lastest dcli version as the original technique wasn't working.
Added instructions on how to delete the acquision block file.

# 6.2.2

# 6.2.1

# 6.2.0
Corrected the pull command to use the Images version.

# 6.2.0
upgraded to latest version of public_suffix.
the test incorrectly check for a production cert.
test can now be run by dcli.
updated unit tests as tail is now called follow.
The following option now defaults to false as there was no way to turn off the follow option.
Added check that completer hasn't already been completed.

# 6.1.0
upgrade public_suffix and mailer.
Migrated to dcli 1.0 and docker2

# 6.0.2

# 6.0.1
migrated to nnbd.
Migrated to nnbd.
upgraded to nnbd version of isolates.
Migrated to nnbd.

# 5.0.69
Upgraded packages as part of release process
Upgraded packages as part of release process
test is no longer needed.
increased logging.
Changed test to find an existing container.
Added logic so test completes.
now pulling the email address from the settings file.
Moved the cloudflare paths so we can mock them.
Fixed bug where the generic auth provider wasn't picking up the email address from the correct environment var.
Improved log formatting.
Fixed a bug parsing the certificate name when it contains a -000n

# 5.0.68
Updated path to cloudflare settings.ini as it needs to be persistant.

# 5.0.67
Upgraded packages as part of release process
updated tests for switching from staging to production.
Added logic to the acquire command to delete invalid certificates. If users changes from staging to production this is needed as certbot can't tell the difference.
Added logic to the service to delete any invalid certificates on startup

# 5.0.66
Added revoke all so the renew doesn't have to deal with odd certificates lying around.

# 5.0.65
Created a find method on Certificate to find a certificate that matches and then changed revoke to work against the matching certificate. This is safer than what revoke was doing which was to guess the path. The wasIssuedFor command now checks that production/staging type of the certificate matches.
renamed method.

# 5.0.64
Upgraded packages as part of release process
Moved the nginx reload logic from the deploy command to the enter/leave acquisition mode as the mode is where we change the symlinks that actually affect whether we need an nginx reload.

# 5.0.63
Added more unit testing combinations.
Added count of revoked certificates to help with unit testing.
Added call to explitiy push system out of acquisition mode on every check. This is more for unit testing but could be needed in some start up conditions if they system shutdown badly.

# 5.0.62

# 5.0.61
unit tests added for namecheap with wildcards.
Improved wasIssuedFor by ignoring invalid certificates.
hooks now require the wildcard.
Added set/get for auth provider username.
Now passing the wildcard down to the auth provider so the can correctly format challenges.
Added wildcard flag to challeange so we can correctly format the challange that we send to the provider. For wild cards we need to strip the host name.
No throws if we can't get an auth provider and logs the selected authprovider.
improved doco.

# 5.0.60
format.

# 5.0.59
Namecheap provider was not setting the host to '*' when a wild card was requested.

# 5.0.58
formatting.

# 5.0.57
added logging.

# 5.0.56
missing ;
added catch block so a renew timeout won't cause docker to shutdown.

# 5.0.55
Increased lock timeouts to 20 minutes a certbot calls can be slow (renew can easily).

# 5.0.54
Added namedlocks around certbot as only one instance of certbot can run at a time.
Improved startup logic. Now checks if we hav a valid cert before we worry about if it is deployed.

# 5.0.53
Added finally block around nginx start so we can see any failures.
An expired certificate is no considered a valid certificate as nginx can still run with an expired certificate and we actually need it up and running so we can renew the certificate.

# 5.0.52
Fixed the live config so we can always do renewals.

# 5.0.51
The renew manager now immediately check if certificaetes need to be renewed on startup so that if a system has been idle for a long time we don't have to wait for 1am for the certificate to be renewed.
released
Added a test for double tries at acquistion.

# 5.0.50
release.
set the default renewal value for 'force' to false.
removed the revoke command on startup to reduce the risk of exceeding rate limits.

# 5.0.49
toggeld to shared.
suppressed the sleep calls flooding logs.

# 5.0.48
toggled to local shared.
Added standalone test for revoke.
Fixed handling of wild card host names as a wildcard certificate doesn't have a host name.
Looks like the revoke command deletes files but doco is ambigous. We are now passing the delete option explicity and have remove the call to certbot --delete.
Added log message when cert is acquired for cloudflare.
Fixed mock paths for wildcards.
Improved comments.

# 5.0.47
release
Upgraded packages as part of release process
Fixed bugs in the handling of wildcards.

# 5.0.46
Upgraded packages as part of release process
Added move verbose statements on startup so we can see what mode nginx is starting in.
Corrected a bug in isDeploy which was checking that the certs existed not that they had been deployed.
released.

# 5.0.45
deploy attempt.
renamed dir custom to operating.
removed unused import.

# 5.0.44
formatting.
Upgraded packages as part of release process

# 5.0.43
Added ability to stop nginx reload when doing unit tests
upgraded dcli
unit tests for renewal.
ignored securitysettings.
Added unit tests for acquistion and renewal.
Added reload control for unit testing without nginx.
Changed path name from custom to opeerationa.
Mock object for all of the certbotpaths.
Changed the user of the auth provider email address so it works as per the doco (e.g. use the auth provider email but if not provided use the certbot email address).
Added optional argument so you can test if a certificate expires at a given date.
Added doco.
Fixed bug caused when _internal through an exception causing a subseqent error as _self didn't get initialised. We now print a message when revoking an invalid certificate. We know invoke expired certificates if they are more than 90 days old, just to keep things tidy. Change the term 'custom' to 'operating' to make the paths clearer.
Moved the revoke of invalid certificates into Certbot
Fixed renewal bug when using cloudflare. The renew needs the cloudflare settings file which we were deleting.
Added mock version of deploy hook which does everything deploy_hook does but from the /tmp folder.
Upgraded packages as part of release process
moved all paths to certbotpaths and made it a factory so we can overload paths for unit testing.

# 5.0.42
updated dcli named args.
Upgraded packages as part of release process

# 5.0.41

# 5.0.40
Upgraded packages as part of release process

# 5.0.39
transitive dependencies for dcli didn't work as the tools need it locally.

# 5.0.38
made dcli transitive.

# 5.0.37

# 5.0.36
Fixed typo.
upgraded to dcli 0.41
Added logic in the acquistion manager to build/repair the LIVE link if it doesn't exist.
Fixed a bug in inAcquistionMode which was failing if the symlink didn't exist at all.

# 5.0.34
Added option to force renewals. This is mainly for testing purposes.

# 5.0.33
tried to add test for wasIssuedFor but its hard to get certificates on a local system.
Improved the wasIssuedTo error messages.
grammar
When we start the acquisition mode we only try to deploy certificates if they are not already deployed.
On service start we now only attempt to revoke invalid certificates if we have some certificates.
improved commit message in release_all

# 5.0.32
failed release.
Added log message of path to deploy_hook

# 5.0.31
spelling.
failed release attempt
updated the path to dcli.

# 5.0.30
removed backups
Upgraded packages as part of release process
Upgraded packages as part of release process

# 5.0.29
corrected commit paths.

# 5.0.28
commits the changed pubspec related files after running toggle.
Now deletes the backup file after toggling.
Upgraded packages as part of release process

# 5.0.27
Added comments.

# 5.0.26

# 5.0.25
now only commits if there are uncommited files.

# 5.0.23
Upgraded packages as part of release process
commit pubspec.lock after doing pub upgrade as pub_release requires all files to be commited.

# 5.0.22

# 5.0.21

# 5.0.20

# 5.0.19

# 5.0.19
released 5.0.13.

# 5.0.18

# 5.0.17

# 5.0.16

# 5.0.15

# 5.0.14

# 5.0.13

# 5.0.14

# 5.0.13
moved toggle to after release of shared as toggle had indirect dependencies on shared.

# 5.0.13

# 5.0.12

# 5.0.8

# 5.0.7

# 5.0.7
released 5.0.6
Added test for block flag expiry.
Fixed a bug caused by trying to delete a non-existant symlink. Fixed a bug with block flag. Date comparision was inverted.

# 5.0.6

# 5.0.5

# 5.0.2
released 5.0.1

# 5.0.1
reworked the acquistiion manager to better deail with failed acquisitions. It now has a retry loop if an acquisition failed. Previously it would not retry until restarted.

# 5.0.0

# 5.0.0

# 4.0.15
Added extra loggin to make it clear why the acquistion manager hasn't started.
released 4.0.14
grammar

# 4.0.14
Fixed a bug caused by the live link already existing in some circumstances. Now we always check if it exists and delete it before we recreate it.
fixed usage message.
corrected usage message.
updated to latest dcli version. releasd 4.0.13
released 4.0.12
The custom content provider was deleting the contents of the location and up stream files. Given these directories are provided by the user we should not be deleting the contents :<
released 4.0.11
removed --force-renewal which only meant to be for testing as it forces a new certificate on every renewal. Fixed an incorrect environment var name that was causing the deploy hook to fail.
released 4.0.9
renamed prepareHooks to prepareEnvironment
added call to prepareEnvironment so the service test runs further before failing.
Fixed an incorrect log message.
removed the creating of letsencrypt/live dir as when we mount the volume this path is overwritten with the volume. Added logic to check that letsencrypt/live exists before we try to load certificates from a non-existant path. change printerr to print as this was causing logging to be incorrectly ordered making it hard to read the logs.
improved logging.
Added command to create the letsencrypt live directory.
Moved all certbot related paths into class CertbotPaths. Fixed a bug wit the code that blocks acquistion attempts after an error as the touch command was missing the 'create' option.
released 4.0.1
Fixes for renewals not working (deploy wasn't being called) and general cleanup of the hook mechanisms to simplify them.
Fixed bugs where the DNS auth hook setters were not working.
made the reload ngxin method private.
Now throws an exception if no auth provider set.
released 3.0.2
released 3.0.1.
Added a 15 minute max life to the block file.
refactored isolates into classes. Improve the error handling of isolates to log failures.  Added logic to suppress further acquistions when an error occurs so we don't immediately exceed rate limits. Change nginx to start in foreground mode so that the dart code can wait for it to complete.
Fixed table formatting.
released 2.7.10
spelling.
updated dependencies.
Added test case for starting the service.
Added logging when we shutdown due to an exception being thrown.
restructured as a class.
spelling.
Fixed a bug where if the symlink already existed we were failing to delete it.
relesaed 2.7.5 - updated to latest dcli version.
improved doco.
added logic to ensure we didn't end up with a double slash in the url
released 2.7.4
Fixed bug with tomcat provider not saving the context.
updated doco on tomcat settings.
lint errors
Fixed problems with finding the Dockerfile path.
Added option to force an image to be deleted.
logrotate was failing if a log file didn't exist and the letsencrypt log file is rarely written to. Now set so it won't error if the file is missing.
logrotate was causing nginx to stop if the logrotate command failed. No just prints an error.
Added logic to ask for and configure a tomcat context.
Added logic to search for the Dockerfile
Fixed a bug in the log rotation config which mean it would only rotate after it hit 400MB. Now rotates every day or if it hits 400MB. Whichever occurs first.
Improved the doc.
upgraded to dcli 0.32.0
released 2.5.0
nginx logs: removed duplicated logging definitions.
dcli: upgraded to dcli 0.29.0
build: added logic to prompt the user for the version no.
release_all: changed detection to using DartProject.
Added logic to set docker permissions up if the docker group exists.
Added logrotate for all of the nginx and certbot logs.
released 2.4.5
Fixed the fullname method so that it returns the correct fullname even if some components are missing.
removed the autoCreate as we should be validating paths.
Config: Added logic to ask the user if they want to start the container.
corrected the tag name.
Fixed a bug where the container was not placed into auto acquire mode.
added details on running a command.
Added pull to get latest ubuntu image before building nginx-le
Added example of using a command.
upgraded to dcli 0.27.1
upgraded to dcli 0.27.1
released 2.3.5
Printed current version when releasing.
Added a check that an Auth Provider has been set.
Added checks an errors if an nginx container doesn't exist.
released 2.3.4
updated to the latest SettingsYaml
We now activate the new published version before trying to do a docker build.
removed test script.
released 2.3.2
spelling.
changed is staging to isproduction to bring it in line with the change to the environment variable name.
Added production state of the certificate.
Fixed a bug where it was trying to get the username from the config which doesn't exist in the container.
Added missing production key.
I think this version works.
renamed certbotAuthProviderKey to authProviderKey. continued work on cleaning up environment naming conventions.
renamed start to service to make it clearer that it doesn't directly related to the external start commmand.
updated env doco
changed CERTBOT_AUTH_PROVIDER to AUTH_PROVIDER.
released 2.1.1
added example.
grammar and spelling.
final major refactor pre-release.
Removed the 'mode' environment variable as it isn't used. Removed DNSAuthProviders as all AuthProviders are now considered the same.
Rationalised the use of env keys.
upgraded to dcli 0.23
Changed output to recognize that all auth providers are now treated the same.
removed unncessary if condtion.
formatting.
Fixed a major bug in the namecheap auth. It was calling certbot again rather than the dns hook.
Improvements  in messages.
Improved the validator by printing the erroneous entry.
removed lauch.json
released 1.4.11
Logged the api key and cleaned up the logic around how we retrieve it.
Fixed a number of bugs around wildcard certificates. Primarily the paths to the certification storage is different (no hostname) when dealing with wildcards.
ignored launch.json
Reformatted code 120 characters wide.
Added additional logging.
added doco on cloudflare environment vars.
formattting and additional logging.
Added support for interactive option on start method.
Made file executable.
Added interactive option to help debug startup failures.
released 1.4.2
Fixed incorrect environment names for namecheap.
SMTP Server can now accept localhost.
Updated doco on environment variables. released 1.4.1
renamed providers and environment vars.
Updated environment variables.
released 1.4.0
upgraded to dcli 0.22
unit test for latestCertificatePath
added release notes
Fixed the wild card detection.
formatting.
Merge branch 'master' of github.com:bsutton/nginx-le
Merge branch 'master' of github.com:bsutton/nginx-le
Merge branch 'master' of github.com:bsutton/nginx-le
Merge branch 'master' of github.com:bsutton/nginx-le
Merge branch 'master' of github.com:bsutton/nginx-le
udpated.
Merge branch 'master' of github.com:bsutton/nginx-le
Merge branch 'master' of github.com:bsutton/nginx-le
removed unwanted files
removed unwanted files
Merge branch 'master' of github.com:bsutton/nginx-le
Merge branch 'master' of github.com:bsutton/nginx-le
Merge branch 'master' of github.com:bsutton/nginx-le
Merge branch 'master' of github.com:bsutton/nginx-le
Merge branch 'master' of github.com:bsutton/nginx-le
Merge branch 'master' of github.com:bsutton/nginx-le
released 1.1.6
released 1.1.6
formatting
formatting
released 1.1.6
released 1.1.6
upgraded to dcli to fix the tailing of streama.
upgraded to dcli to fix the tailing of streama.
formatting.
formatting.
minor changes to assist in unit testing and added unit tests.
minor improvements in prompts.
removed redundant code. Improved the usage instructions.
upgraded to dcli 0.21.1
Improved the start instructions by basing on them on the selected start method.
ignored stuff
ignored certbot conf
ignored log file.
upgraded to dcli
upgraded to dcli
Moved ConfigYaml into shared. Fixed bugs with acquistion/revokation and startup.
Moved ConfigYaml into shared. Fixed bugs with acquistion/revokation and startup.
Added error checks for failed cert acquisition and renewal. Added smtp server/port settings and are now sending emails when an error occurs.
Added error checks for failed cert acquisition and renewal. Added smtp server/port settings and are now sending emails when an error occurs.
released 1.1.2
released 1.1.2
Added logic to revoke and acquire a new certificate if the cert type changes.
Added logic to revoke and acquire a new certificate if the cert type changes.
documented environment vars.
documented environment vars.
renamed to make it more obvious what the code does.
renamed to make it more obvious what the code does.
fixed mis-named environment var.
fixed mis-named environment var.
formattig
formattig
Using wrong environment vars for http auth (there were missing completely).
Using wrong environment vars for http auth (there were missing completely).
released 1.0.10
released 1.0.10
improvements in doc.
improvements in doc.
completed work on centralising all environment var usage.
completed work on centralising all environment var usage.
Moved all the environment vars intoa single class and removed the internalConfig class.
Moved all the environment vars intoa single class and removed the internalConfig class.
released 1.0.7
released 1.0.7
Added logic to suppress acquire message when in auto acquire mode.
Added logic to suppress acquire message when in auto acquire mode.
Merge branch 'master' of github.com:bsutton/nginx-le
Merge branch 'master' of github.com:bsutton/nginx-le
change ConfigYaml to use SettingsYaml
change ConfigYaml to use SettingsYaml
we now use the fqdn rather than a separate host/domain name.
we now use the fqdn rather than a separate host/domain name.
spelling.
spelling.
removed as part of new provider implementation.
removed as part of new provider implementation.
added arg to supress mis-leading message when in auto acquire mode.
added arg to supress mis-leading message when in auto acquire mode.
spelling.
spelling.
Added support for new content providers.
Added support for new content providers.
formatting and doco.
formatting and doco.
removed excisve logging.
removed excisve logging.
Added config options to support tomcat and a general structure for adding additional webserver types. The config command now sets the container's debug option if it is run with the -d option.
Added config options to support tomcat and a general structure for adding additional webserver types. The config command now sets the container's debug option if it is run with the -d option.
Create FUNDING.yml
Create FUNDING.yml
Upgraded to dshell 1.11.0 and fixed breaking changes.
Upgraded to dshell 1.11.0 and fixed breaking changes.
Upgraded to dshell 1.11.0 and fixed breaking changes.
Upgraded to dshell 1.11.0 and fixed breaking changes.
Upgraded to dshell 1.11.0 and fixed breaking changes.
Upgraded to dshell 1.11.0 and fixed breaking changes.
Upgraded to dshell 1.11.0 and fixed breaking changes.
Upgraded to dshell 1.11.0 and fixed breaking changes.
Upgraded to dshell 1.11.0 and fixed breaking changes.
Upgraded to dshell 1.11.0 and fixed breaking changes.
upgraded to dshell 1.11.0 and fixed breaking changes.
upgraded to dshell 1.11.0 and fixed breaking changes.
moved to cli
moved to cli
released 1.0.1
released 1.0.1
released 1.0.1
released 1.0.1
released 1.0.1
released 1.0.1
Fixed a bug where the cert type selection menu was not showing the currently selected value.
Fixed a bug where the cert type selection menu was not showing the currently selected value.
released 0.5.4
released 0.5.4
Resolved confusion between the host and container include path. These are different but were being used interchangably.
Resolved confusion between the host and container include path. These are different but were being used interchangably.
released 0.5.3
released 0.5.3
Added logic to stop so it won't try to stop if the container isn' trunning.
Added logic to stop so it won't try to stop if the container isn' trunning.
Fixed a bug. We need the image even when using docker compose.
Fixed a bug. We need the image even when using docker compose.
released 0.5.0
released 0.5.0
adde dmissing space.
adde dmissing space.
auto selects the nginx-le container if it gets an exact match.
auto selects the nginx-le container if it gets an exact match.
released 0.4.5
released 0.4.5
collapse include directory structure into a single folder for .upstream and .location files at roberts insistance.
collapse include directory structure into a single folder for .upstream and .location files at roberts insistance.
released 0.4.4
released 0.4.4
correct the volume path.
correct the volume path.
cleaned up logging.
cleaned up logging.
released 0.4.3
released 0.4.3
New certificate class allows us to parse the certbot certificates.
New certificate class allows us to parse the certbot certificates.
changed to -F so we can follow certbots log rotation.
changed to -F so we can follow certbots log rotation.
Now using the new Certificate class to get better details of the cert.
Now using the new Certificate class to get better details of the cert.
exposed new certificates class.
exposed new certificates class.
fixed a bug. location not locations.
fixed a bug. location not locations.
we use the default include path even if its empty as when changing betwen content locations it can be left empty.
we use the default include path even if its empty as when changing betwen content locations it can be left empty.
We only run acquire if we have no certificates or the wrong type of certificate.
We only run acquire if we have no certificates or the wrong type of certificate.
tweaked content source logic as it wasn't requesting the right paths for the give type.
tweaked content source logic as it wasn't requesting the right paths for the give type.
released 0.4.1
released 0.4.1
switch the renew scheduler to run at 1am each day.
switch the renew scheduler to run at 1am each day.
released 0.4.0
released 0.4.0
changed retries to 20.
changed retries to 20.
add validation for the namecheap keys.
add validation for the namecheap keys.
change the default retries to 20 and made it configurable.
change the default retries to 20 and made it configurable.
prints a message after deploy indicating that certs are active.
prints a message after deploy indicating that certs are active.
print the version no. on start.
print the version no. on start.
Made it possible to auto acquire a certificate.
Made it possible to auto acquire a certificate.
no longer storing the namecheap keys as this is a security issue and wasn't required. Added in staging and debug.
no longer storing the namecheap keys as this is a security issue and wasn't required. Added in staging and debug.
removed unused code.
removed unused code.
ignored launch.json
ignored launch.json
released 0.3.14
released 0.3.14
updated default paths.
updated default paths.
created a tool to automate the release of nginx-le
created a tool to automate the release of nginx-le
fixed a bug when parsing names with no tag.
fixed a bug when parsing names with no tag.
built a script to automate
built a script to automate
added some additional prompts..
added some additional prompts..
Added method to pull images by the fullname.
Added method to pull images by the fullname.
renamed nginx_le_cli to nginx_le to make install easier.
renamed nginx_le_cli to nginx_le to make install easier.
Added option to redirect logging to stdout.
Added option to redirect logging to stdout.
Fixed the dns auth hook. The TXT record name as incorrect.
Fixed the dns auth hook. The TXT record name as incorrect.
0.2.0 release
0.2.0 release
fixed the test.
fixed the test.
Fixed the dig command as we were not passing down the domain.
Fixed the dig command as we were not passing down the domain.
Added logic to check the container exits.
Added logic to check the container exits.
moved to root.
moved to root.
moved readme
moved readme
first commit
first commit

# 4.0.13
# 4.0.12
# 4.0.11
# 4.0.10
# 4.0.9
# 4.0.8
# 4.0.7
# 4.0.6
# 4.0.5
# 4.0.4
# 4.0.3
# 4.0.2
# 4.0.1
# 4.0.0
# 3.0.2
Reduced dart sdk to 2.7. so we can run on a raspberry pi.

# 3.0.1
# 3.0.0
# 2.7.10
# 2.7.9
# 2.7.8
# 2.7.7
# 2.7.6
# 2.7.5
upgraded to dcli 0.33.6
# 2.7.4
# 2.7.3
# 2.7.2
# 2.7.1
# 2.7.0
# 2.6.1
# 2.6.0
# 2.5.4
# 2.5.3
# 2.5.3
# 2.5.2
# 2.5.1
upgraded to dcli 0.30.0
# 2.5.0
# 2.4.8
Upgraded to dcli 0.29.2
# 2.4.7
upgraded to dcli 0.29.0
# 2.4.6
Updated to dcli 0.28.0
# 2.4.5
# 2.4.4
# 2.4.3
# 2.4.2
# 2.4.1
# 2.4.1
# 2.4.0
# 2.3.6
upgraded to dcli 0.27.1
# 2.3.5
# 2.3.4
# 2.3.3
# 2.3.2
# 2.3.1
# 2.3.0
# 2.1.2
Final refactoring and improvements to documentation.
# 2.1.1
# 2.1.0
# 2.1.0
# 2.0.3
# 2.0.2
# 2.0.1
# 2.0.1
# 2.0.0
# 2.0.0
# 1.4.16
# 1.4.15
# 1.4.14
# 1.4.13
# 1.4.12
# 1.4.11
Fixed wild card cert paths.
# 1.4.10
# 1.4.9
# 1.4.8
# 1.4.7
# 1.4.6
# 1.4.5
# 1.4.5
# 1.4.4
# 1.4.3
# 1.4.2
# 1.4.1
# 1.4.0
# 1.3.1
# 1.3.0
# 1.2.0
# 1.1.6
# 1.1.5
# 1.1.5
# 1.1.4
# 1.1.3
# 1.1.2
# 1.1.1
# 1.1.0
# 1.0.11
# 1.0.11
Fixed the HTTP auth hooks. Was uising the DNS auth hook due to a mix up in environment vars.
# 1.0.10
Added missing consts for namecheap
# 1.0.9
Completed work on centralising all environment var access.
# 1.0.8
Moved all of the environment var access to a single class to ensure consistency and removed the InternalConfig file as its no longer used.

# 1.0.7
incremented to sync release version no.s
# 1.0.6
added autoacquiremode flag
# 1.0.3
# 1.0.2
Upgraded to dcli 1.11.0 and fixed breaking changes.

# 1.0.1
Fixed: default certificate type was ignoring the currently selected certificate type.
# 1.0.0
First release
# 0.5.6
# 0.5.5

Fixed the host include paths.
# 0.5.4
synchronized release with nginx-le
# 0.5.3
container .stop check if the container is running.
# 0.5.2
Had to add the terminal:true option.
# 0.5.1
Added a 'cli' method to the container class which attaches to the container and starts a bash shell.
# 0.5.0
# 0.4.5
# 0.4.4
# 0.4.3
# 0.4.2
# 0.4.1
# 0.4.0
# 0.3.16
# 0.3.15
# 0.3.10
# 0.3.9
# 0.3.8
# 0.3.8
# 0.3.7
# 0.3.7
# 0.3.5
# 0.3.4
# 0.3.3
# 0.3.2
# 0.3.1
# 0.3.0
# 0.2.0
First mostly working version.
# 0.1.1
Added libraries to list Docker containers/images.
# 0.1.0
