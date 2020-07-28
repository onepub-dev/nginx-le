class CommandException implements Exception {
  String message;
  CommandException(this.message);

  @override
  String toString() => message;
}
