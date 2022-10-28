# 8.3.6
- path to shared
- added an override for shared.
- Removed a number of null ! operators and added explict tests/errors.
- Fixed lints for unawaited async calls. Hopefully I've not created any dead locks.
- corrected the path to the block acquisitsions flag reported when we can't get a cert.
- Fixed lint.
- removed verbose logging.
- change the 'pub global' to use the PubCache api so it selects the correct version of dart.

# 8.3.5

# 8.3.4

# 8.3.2
- Added default_server directive to default_conf so a server isn't selected at random.
- change the docker hub repository to onepub.
- added copy right notices.


# 8.2.6
- env var keys static consts.

# 8.2.1
Failed pub release

# 8.2.0
Added support for hostless fqdn.

# 8.1.1
- second attempt at 8.1 release

# 8.1.0
- improved the acquisition blocked message.
- add support for a domain certificate e.g. onepub.doc rather than www.onepub.doc
  set the HOSTNAME environment var to blank and DOMAIN to the domain name (e.g. onepub.doc)

# 8.0.7

# 8.0.6

# 8.0.5
- stopped certbot_test form shutting down all tests as it was calling exit(1)
- FIX: bug in image selection when there are several docker images with the same name. Upgraded to docker2 2.2 fixed the issue.
- Fix: if you selected a private server we still set the default auth provider to a public auth provider which cause the menu to fail with an unrecogized provider.

# 8.0.4
Fixed dependency problem again
# 8.0.3
Fixed dependency problem.

# 8.0.1
- Migrated to lint_hard
- fixed a bug in the config command when selecting auth provider.

# 8.0.0
- Upgraded packages as part of release process

# 7.1.4

# 7.1.3

# 7.1.1
Toggled path to shared package

# 7.0.2
Improvements to documentation.

# 7.0.1
multi-release 

# 7.0.0
Upgraded to latest from of dcli and docker2.
Fixed a problem with the downloaded dart archive not having the execute bit set on the util directory.

# 6.3.2
Fixed missing reload of nginx after certificate renewal.


# 6.2.5

# 6.2.2
Upgraded packages as part of release process

# 6.2.1
Upgraded packages as part of release process

# 6.2.0
Upgraded packages as part of release process
Toggled path to shared package

# 5.1.0
migrated to using the docker2 package and upgraded to dcli 1.0

# 5.0.69
Upgraded packages as part of release process

# 5.0.68
Upgraded packages as part of release process

# 5.0.67
Upgraded packages as part of release process

# 5.0.66
Upgraded packages as part of release process

# 5.0.64
Upgraded packages as part of release process

# 5.0.63
Upgraded packages as part of release process

# 5.0.62
Upgraded packages as part of release process

# 5.0.60
Upgraded packages as part of release process

# 5.0.58
Upgraded packages as part of release process

# 5.0.56
Upgraded packages as part of release process

# 5.0.55
Upgraded packages as part of release process

# 5.0.54
Upgraded packages as part of release process

# 5.0.53
Upgraded packages as part of release process

# 5.0.52
Upgraded packages as part of release process

# 5.0.51
Toggled path to shared package

# 5.0.50
Toggled path to shared package

# 5.0.49
Toggled path to shared package

# 5.0.48
Upgraded packages as part of release process
Toggled path to shared package

# 5.0.47
Upgraded packages as part of release process
Toggled path to shared package

# 5.0.46
Upgraded packages as part of release process
Toggled path to shared package

# 5.0.45
Toggled path to shared package

# 5.0.44
Upgraded packages as part of release process

# 5.0.43
Toggled path to shared package

# 5.0.42
Upgraded packages as part of release process

# 5.0.41
Upgraded packages as part of release process

# 5.0.40
Upgraded packages as part of release process

# 5.0.39
Upgraded packages as part of release process

# 5.0.38
Upgraded packages as part of release process
Toggled path to shared package

# 5.0.37
Upgraded packages as part of release process
Toggled path to shared package

# 5.0.34
Upgraded packages as part of release process

# 5.0.33
Upgraded packages as part of release process

# 5.0.32
Upgraded packages as part of release process

# 5.0.31
Upgraded packages as part of release process

# 5.0.30
Upgraded packages as part of release process

# 5.0.22

# 5.0.21

# 5.0.20

# 5.0.19

# 5.0.17

# 5.0.16

# 5.0.15

# 5.0.14

# 5.0.12

# 5.0.8

# 5.0.7

# 5.0.6

# 5.0.5

# 5.0.2
released 5.0.2
upgraded to dcli 0.39.7 to fix a bug when fetching the dart version when dartsdk isn't installed.

# 5.0.1

# 5.0.0

# 4.0.15

# 4.0.14

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
# 3.0.2
# 3.0.1
# 2.7.10
# 2.7.9
# 2.7.8
# 2.7.7
# 2.7.6
# 2.7.4
# 2.7.3
# 2.7.2
# 2.7.1
# 2.7.0
Added support for tomcat contexts when configuring the Tomcat provider.
Added logic to build to find the Dockerfile.
# 2.6.1
# 2.6.0
# 2.5.4
# 2.5.3
# 2.5.2
# 2.5.0
# 2.4.5
# 2.4.4
# 2.4.3
# 2.4.2
# 2.4.0
# 2.3.5
# 2.3.4
# 2.3.3
# 2.3.2
# 2.3.1
# 2.3.0
# 2.1.1
# 2.1.0
# 2.0.3
# 2.0.2
# 2.0.1
# 2.0.0
# 1.4.16
# 1.4.15
# 1.4.14
# 1.4.13
# 1.4.12
# 1.4.11
# 1.4.10
# 1.4.9
# 1.4.8
# 1.4.7
# 1.4.6
# 1.4.4
# 1.4.3
# 1.4.2
# 1.4.1
# 1.4.0
# 1.3.1
# 1.3.0
# 1.2.0
# 1.1.6
Fixed logging. Was ignoring output to stderr.
# 1.1.5
# 1.1.4
# 1.1.3
# 1.1.2
# 1.1.1
# 1.1.0
# 1.0.10

Added missing consts for namecheap
# 1.0.9
Completed work on centralising all environment var access.
# 1.0.7
fixed bug in auto acquire in shared lib.
# 1.0.6
See nginx_le for details
# 1.0.3
upgraded to latest shared lib.
# 1.0.2
Upgraded to dcli 1.11.0 and fixed breaking changes.
# 1.0.1
Fixed: default certificate type was ignoring the currently selected certificate type.
# 1.0.0
First release
# 1.0.0
First release
# 0.5.6
# 0.5.6
