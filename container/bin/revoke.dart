import 'package:nginx_le_container/src/commands/internal/revoke.dart';

/// In container entry point to run certbot

void main(List<String> args) {
  revoke(args);
}
