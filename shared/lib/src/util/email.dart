import 'package:dcli/dcli.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:nginx_le_shared/src/util/environment.dart';

class Email {
  static void sendError({String subject, String body}) {
    final smtpServer = SmtpServer(Environment().smtpServer,
        port: Environment().smtpServerPort);

    // Use the SmtpServer class to configure an SMTP server:
    // final smtpServer = SmtpServer('smtp.domain.com');
    // See the named arguments of SmtpServer for further configuration
    // options.

    // Create our message.
    final message = Message()
      ..from = Environment().emailaddress
      ..recipients.add(Environment().emailaddress)
      ..subject = subject
      ..text = body
      ..html = '<p>$body</p>';

    try {
      final sendReport = waitForEx<SendReport>(send(message, smtpServer));
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      printerr('Message not sent.');
      for (var p in e.problems) {
        printerr('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
}
