import 'package:dcli/dcli.dart';

import 'certbot/certbot_paths.dart';

/// Creates a symlink from [CertbotPaths().WWW_PATH_LIVE]
/// to the active web server content.
/// If [acquisitionMode] is true then this will be the page
/// we ship informing the user we are in acquistion mode.
/// If we [acquistionMode] is false then this will be the website's
/// actual content.
/// returns true if the correct link didn't exists and had to be created.
bool createContentSymlink({required bool acquisitionMode}) {
  String targetPath;
  if (acquisitionMode) {
    targetPath = CertbotPaths().wwwPathToAcquire;
  } else {
    targetPath = CertbotPaths().wwwPathToOperating;
  }
  var created = false;

  var validTarget = false;
  var existing = false;
  // we are about to recreate the symlink to the appropriate path
  if (exists(CertbotPaths().wwwPathLive, followLinks: false)) {
    existing = true;
    if (exists(CertbotPaths().wwwPathLive)) {
      validTarget = true;
    }
  }

  if (validTarget) {
    if (resolveSymLink(CertbotPaths().wwwPathLive) != targetPath) {
      deleteSymlink(CertbotPaths().wwwPathLive);
      symlink(targetPath, CertbotPaths().wwwPathLive);
      created = true;
    }
    // else the symlink already points at the target.
  } else {
    /// the current target is invalid so recreate the link.
    if (existing) deleteSymlink(CertbotPaths().wwwPathLive);
    symlink(targetPath, CertbotPaths().wwwPathLive);
    created = true;
  }
  return created;
}
