import 'package:logger/logger.dart';
import 'package:mellstroy_telegram_bot/bot/command.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';

const token = "5950103849:AAEmx1kAXUnD4urbvtv21rtDds5kie8DKMY";
late TeleDart _td;

final class Bot with Dialog {
  final TeleDart td;
  static Future<Bot> init() async {
    var gram = Telegram(token);
    var me = await gram.getMe();
    _td = TeleDart(token, Event(me.username!));
    _td.start();
    return Bot._(_td);
  }

  Bot._(this.td) {
    Logger().d("message");
    initDialog(td);
  }

  Bot getInstance() => Bot._(_td);
}
