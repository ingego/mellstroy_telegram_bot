import 'package:logger/logger.dart';
import 'package:mellstroy_telegram_bot/bot/command.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';

const _token = "6023522487:AAHeJNQR7PmbPBCtdUc7eqvWPGbFz15iGt8";
late TeleDart _td;

final class Bot with Dialog {
  final TeleDart td;
  static Future<Bot> init() async {
    var gram = Telegram(_token);
    var me = await gram.getMe();
    _td = TeleDart(_token, Event(me.username!));
    _td.start();
    return Bot._(_td);
  }

  Bot._(this.td) {
    Logger().d("message");
    initDialog(td);
  }

  Bot getInstance() => Bot._(_td);
}
