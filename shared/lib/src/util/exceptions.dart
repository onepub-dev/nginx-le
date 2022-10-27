class DockerException implements Exception {
  DockerException(this.message);

  String message;
}

class ConfigurationException implements Exception {
  ConfigurationException(this.message);

  String message;
}
