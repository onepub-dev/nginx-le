import 'content_providers.dart';

/// Provides a base class for content source providers.
///
/// For an Nginx install we need to define where it pulls its
/// content from.
/// There a many different content providers available
/// such as a simple static site and a raft of diffent web
/// application servers such as:
/// tomcat
/// php
/// ....
///
/// To implement a new provider you need to derive from this class
/// and then register your provider with the [ContentProviders] class.

abstract class ContentProvider {
  String get name;

  String get summary;

  void promptForSettings();

  void createLocationFile();

  void createUpstreamFile();

  List<Volume> getVolumes();
}

/// Defines the paths for a Volume to be mounted into the nginx docker
/// container.
class Volume {
  Volume({required this.hostPath, required this.containerPath});
  final String? hostPath;
  final String containerPath;
}
