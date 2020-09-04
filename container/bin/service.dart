import 'package:nginx_le_container/nginx_le_container.dart';
import 'package:nginx_le_container/src/commands/internal/service.dart';

/// The container entry point to run nginx.
/// This starts the primary nginx service thread.
void main() {
  start_service();
}
