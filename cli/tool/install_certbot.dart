#! /bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';

void main(List<String> args) {
  'apt install --no-install-recommends -y python3 python3-venv'.run;
  'python3 -m venv /opt/certbot/'.run;
  '/opt/certbot/bin/pip install --upgrade pip'.run;
  '/opt/certbot/bin/pip install certbot'.run;
  'ln -s /opt/certbot/bin/certbot /usr/bin/certbot'.run;
  '/opt/certbot/bin/pip install certbot-dns-cloudflare'.run;
}
