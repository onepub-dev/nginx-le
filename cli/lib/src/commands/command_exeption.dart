class CommandException implements Exception {
  CommandException(this.message);
  String message;

  @override
  String toString() => message;
}
