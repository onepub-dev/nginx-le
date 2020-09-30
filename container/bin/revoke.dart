import 'package:nginx_le_container/src/commands/internal/revoke.dart';

/// 'In container' entry point to run certbot
///
/// The cli revoke command calls this command which does the actual revocation
/// within the container.
void main(List<String> args) {
  revoke(args);
}
