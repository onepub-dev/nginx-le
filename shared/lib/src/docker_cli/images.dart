import 'package:dshell/dshell.dart';
import 'package:meta/meta.dart';
import 'image.dart';

class Images {
  static final _self = Images._internal();

  Images._internal();

  final imageCache = <Image>[];

  factory Images() => _self;

  List<Image> get images {
    if (imageCache.isEmpty) {
      var lines = 'docker images'.toList(skipLines: 1);

      var cmd =
          'docker images --format "table {{.ID}}|{{.Repository}}|{{.Tag}}|{{.CreatedAt}}|{{.Size}}"';
      // print(cmd);

      lines = cmd.toList(skipLines: 1);

      for (var line in lines) {
        var parts = line.split('|');
        var imageid = parts[0];
        var repositoryAndName = parts[1];
        var tag = parts[2];
        var created = parts[3];
        var size = parts[4];

        var image = Image(
            repositoryAndName: repositoryAndName,
            tag: tag,
            imageid: imageid,
            created: created,
            size: size);
        imageCache.add(image);
      }
    }

    return imageCache;
  }

  void flushCache() {
    imageCache.clear();
  }

  bool existsByImageId({@required String imageid}) =>
      findByImageId(imageid) != null;

  bool existsByFullname({
    @required String fullname,
  }) =>
      findByFullname(fullname) != null;

  bool existsByParts(
          {@required String repository,
          @required String name,
          @required String tag}) =>
      findByParts(repository: repository, name: name, tag: tag) != null;

  Image findByImageId(String imageid) {
    var list = images;

    for (var image in list) {
      if (imageid == image.imageid) {
        return image;
      }
    }
    return null;
  }

  /// full name of the format repo/name:tag
  Image findByFullname(String fullname) {
    var match = Image.fromName(fullname);

    return findByParts(
        repository: match.repository, name: match.name, tag: match.tag);
  }

  Image findByParts(
      {@required String repository,
      @required String name,
      @required String tag}) {
    var list = images;

    for (var image in list) {
      if (repository == image.repository &&
          name == image.name &&
          tag == image.tag) {
        return image;
      }
    }
    return null;
  }

  Image pull({String fullname}) {
    'docker pull $fullname'.run;
    flushCache();
    return findByFullname(fullname);
  }
}
