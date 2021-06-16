import 'package:dcli/dcli.dart';

import 'certbot/certbot_paths.dart';

/// Creates a symlink from [CertbotPaths().WWW_PATH_LIVE]
/// to the active web server content.
/// If [acquisitionMode] is true then this will the the page
/// we ship informing the user we are in acquistion mode.
/// If we [acquistionMode] is false then this will be the website's
/// actual content.
/// returns true if the correct link didn't exists and had to be created.
bool createContentSymlink({required bool acquisitionMode}) {
  String targetPath;
  if (acquisitionMode) {
    targetPath = CertbotPaths().WWW_PATH_ACQUIRE;
  } else {
    targetPath = CertbotPaths().WWW_PATH_OPERATING;
  }
  var created = false;

  var validTarget = false;
  var existing = false;
  // we are about to recreate the symlink to the appropriate path
  if (exists(CertbotPaths().WWW_PATH_LIVE, followLinks: false)) {
    existing = true;
    if (exists(CertbotPaths().WWW_PATH_LIVE)) {
      validTarget = true;
    }
  }

  if (validTarget) {
    if (resolveSymLink(CertbotPaths().WWW_PATH_LIVE) != targetPath) {
      deleteSymlink(CertbotPaths().WWW_PATH_LIVE);
      symlink(targetPath, CertbotPaths().WWW_PATH_LIVE);
      created = true;
    }
    // else the symlink already points at the target.
  } else {
    /// the current target is invalid so recreate the link.
    if (existing) deleteSymlink(CertbotPaths().WWW_PATH_LIVE);
    symlink(targetPath, CertbotPaths().WWW_PATH_LIVE);
    created = true;
  }
  return created;
}
