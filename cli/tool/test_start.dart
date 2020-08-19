#! /usr/bin/env dshell

import 'package:dshell/dshell.dart';

/// Starts the ngix docker instance using the host subdirectory 'certs' to store acquired certifiates.
void main(List<String> args) {
  'docker run'
          ' --net=host'
          ' --ulimit'
          ' core=99999999999:99999999999'
          ' -v certs:/etc/nginx/certs'
          ' noojee/nginx:1.0.0'
      .run;
}
