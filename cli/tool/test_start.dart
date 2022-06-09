#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */



import 'package:dcli/dcli.dart';

/// Starts the ngix docker instance using the host subdirectory 'certs'
/// to store acquired certificates.
void main(List<String> args) {
  'docker run'
          ' --net=host'
          ' --ulimit'
          ' core=99999999999:99999999999'
          ' -v certs:/etc/nginx/certs'
          ' noojee/nginx:1.0.0'
      .run;
}
