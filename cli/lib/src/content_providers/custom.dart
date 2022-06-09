/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:nginx_le_shared/nginx_le_shared.dart';

import '../util/ask_location_path.dart';
import 'content_provider.dart';

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
    final config = ConfigYaml();
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
