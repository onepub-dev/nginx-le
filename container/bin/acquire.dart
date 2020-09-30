import 'package:nginx_le_container/nginx_le_container.dart';

/// In container entry point to run certbot
/// The cli acquire command calls this command which does the actual acquistion of a certificate
/// within the container.

void main(List<String> args) {
  acquire(args);
}
