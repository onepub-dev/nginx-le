import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';
import '../../nginx_le_shared.dart';
import 'container.dart';

class Containers {
  static final _self = Containers._internal();

  Containers._internal();

  factory Containers() => _self;

  final containerCache = <Container>[];

  List<Container> containers({bool excludeStopped = false}) {
    if (containerCache.isEmpty) {
      var cmd =
          'docker container ls --format "table {{.ID}}|{{.Image}}|{{.CreatedAt}}|{{.Status}}|{{.Ports}}|{{.Names}}"';
      if (!excludeStopped) cmd += ' --all';
      var lines = cmd.toList(skipLines: 1);

      for (var line in lines) {
        var parts = line.split('|');
        var containerid = parts[0];
        var imageid = parts[1];
        var created = parts[2];
        var status = parts[3];
        var ports = parts[4];
        var names = parts[5];

        // sometimes the imageid is actually the image name.
        var image = Images().findByFullname(imageid);
        if (image != null) {
          /// the imageid that we parsed actually contained an image name
          /// so lets replace that with the actual id.
          imageid = image.imageid;
        }

        var container = Container(
            containerid: containerid, imageid: imageid, created: created, status: status, ports: ports, names: names);
        containerCache.add(container);
      }
    }
    return containerCache;
  }

  void flushCache() {
    containerCache.clear();
  }

  bool existsByContainerId(String containerid, {bool excludeStopped = false}) =>
      findByContainerId(containerid, excludeStopped: excludeStopped) != null;

  bool existsByName({@required String name, bool excludeStopped}) =>
      findByName(name, excludeStopped: excludeStopped) != null;

  Container findByContainerId(String containerid, {bool excludeStopped = false}) {
    var list = containers(excludeStopped: excludeStopped);

    for (var container in list) {
      if (containerid == container.containerid) {
        return container;
      }
    }
    return null;
  }

  List<Container> findByImageid(String imageid, {bool excludeStopped = false}) {
    var list = containers(excludeStopped: excludeStopped);
    var matches = <Container>[];

    for (var container in list) {
      if (imageid == container.imageid) {
        matches.add(container);
      }
    }
    return matches;
  }

  /// assumes that a container only has one name :)
  /// if [includeStopped] is true then also  return containers that are not running.
  Container findByName(String name, {bool excludeStopped = false}) {
    var list = containers(excludeStopped: excludeStopped);

    for (var container in list) {
      if (name == container.names) {
        return container;
      }
    }
    return null;
  }

  List<Container> findByImage(Image image, {bool excludeStopped = false}) =>
      findByImageid(image.imageid, excludeStopped: excludeStopped);
}
