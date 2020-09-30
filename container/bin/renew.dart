import 'package:nginx_le_container/src/commands/internal/renew.dart';

/// In container entry point to run certbot
///
/// The cli renew command calls this command which does the actual certificate renewal
/// within the container.

void main(List<String> args) {
  renew(args);
}
