import 'package:nginx_le/src/content_providers/content_provider.dart';
import 'package:nginx_le/src/util/ask_location_path.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

class Custom extends ContentProvider {
  @override
  String get name => 'custom';

  @override
  String get summary => 'Custom .location and .upstream files.';
  @override
  void promptForSettings() {
    askForLocationPath(
        'Host directory for your custom `.location` and `.upstream` files');
  }

  @override
  List<Volume> getVolumes() {
    var config = ConfigYaml();
    return [
      Volume(
          hostPath: config.hostIncludePath,
          containerPath: Nginx.containerIncludePath),
    ];
  }

  @override
  void createLocationFile() {
    // no-op user must provide
  }

  @override
  void createUpstreamFile() {
    // no-op user must provide
  }
}
