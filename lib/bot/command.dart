import 'package:logger/logger.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';

List<int> channels = [-1001875662745, -1001737560487];

List<String> admins = ["osketdev", "Dmitriy_adm"];
TeleDartMessage? message;

bool changeMSG = false;
bool changeChannel = false;
base mixin Dialog {
  late TeleDart _td;
  initDialog(TeleDart td) {
    _td = td;
    commandList();
    eventHandler();
  }

  commandList() {
    _onStart();
    _callAdmin();
    _handleAdminEvents();
    _handleSend();
  }

  _handleSend() {
    _td.onMessage(entityType: "*").listen((event) async {
      if (changeMSG) {
        message = event;
        Logger().d(event);
        await event.reply("Сообщение обновлено");
        changeMSG = false;
      }
      if (changeChannel) {
        var ids = event.text ?? "";
        channels = [];
        var idNew = ids.split("|");
        if (idNew.isNotEmpty) {
          for (var element in idNew) {
            if (element.isNotEmpty) {
              channels.add(int.parse(element));
            }
          }

          event.reply("Каналы обновлены");
        }
        if (idNew.isNotEmpty) {
          // channels = idNew;
        }
      }
    });
  }

  eventHandler() {
    _td.onCallbackQuery().listen((event) async {
      if (event.data == null) {
        return;
      }
      var data = event.data!;
      if (data == "check") {
        var res = await _checkSubscribe(event.teledartMessage!.chat.id);
        var chatId = event.teledartMessage!.chat.id;
        if (res) {
          if (message != null) {
            message!.forwardTo(chatId, protectContent: true);
          } else {
            _td.sendMessage(chatId, "Фул не загружен в бота",
                protectContent: true);
          }
        } else {
          _td.sendMessage(chatId, "Вы не подписаны на каналы",
              protectContent: true);
        }
      }
      event.answer(showAlert: false);
    });
  }

  _handleCommand(String command,
      {required void Function(TeleDartMessage event) handle}) {
    _td.onCommand(command).listen((event) => handle(event));
  }

  Future<bool> _checkSubscribe(int id) async {
    var res = await _td.getChatMember(channels.first, id);
    var resTwo = await _td.getChatMember(channels.last, id);
    var status = (res.status != "left" && resTwo.status != "left");
    return status;
  }

  _onStart() {
    _handleCommand("start", handle: (event) async {
      var link = <String>[];
      for (var element in channels) {
        var chat = await _td.getChat(element);
        link.add(chat.inviteLink!);
      }
      event.reply(
          "Добрый день! Для получения фула, подпищитесь на этим паблики",
          replyMarkup: invateMarkup(link));
    });
  }

  void _callAdmin() {
    _handleCommand("admin", handle: (event) {
      bool isAdmin = false;
      for (var element in admins) {
        if (element.toLowerCase() == event.chat.username?.toLowerCase()) {
          isAdmin = true;
          break;
        }
      }
      if (!isAdmin) {
        event.reply("Вы не админ бота");
        return;
      }
      event.reply("Консоль управления", replyMarkup: adminMarkup());
    });
  }

  _handleAdminEvents() {
    _td.onCallbackQuery().listen((event) async {
      switch (event.data ?? "") {
        case "view_full":
          {
            if (message == null) {
              _td.sendMessage(event.teledartMessage!.chat.id, "Нет сообщения");
            } else {
              message!.forwardTo(event.teledartMessage!.chat.id);
            }
            //  message.forwardTo(chatId)
          }
        case "upload_full":
          {
            if (message != null) {
              await _td.sendMessage(
                  event.teledartMessage!.chat.id, "Фулл уже загружен");
            } else {
              await _td.sendMessage(
                  event.teledartMessage!.chat.id, "Отправьте сообщение");
              changeMSG = true;
            }
          }
        case "change_full":
          {
            await _td.sendMessage(event.teledartMessage!.chat.id,
                "Отправьте сообщение, что бы изменить фул");
            changeMSG = true;
          }
        case "view_channel":
          {
            List<Future> futures = [];
            List<(String, String)> chats = [];

            for (var element in channels) {
              futures.add(_td.getChat(element).then((value) {
                chats.add((value.username ?? "", value.inviteLink ?? ""));
              }));
            }
            await Future.wait(futures);

            await _td.sendMessage(event.teledartMessage!.chat.id, "Каналы",
                replyMarkup: InlineKeyboardMarkup(inlineKeyboard: [
                  List.generate(chats.length, (index) {
                    var (name, link) = chats[index];
                    return InlineKeyboardButton(text: name, url: link);
                  })
                ]));
          }
        case "upload_channel":
          {
            await _td.sendMessage(event.teledartMessage!.chat.id, '''
Отправьте ID каналлов в след формате: 
-123123123123|-23203203203203|-394394394934
''');

            changeChannel = true;
          }
      }
      event.answer(showAlert: true);
    });
  }
}

InlineKeyboardMarkup invateMarkup(List<String> links) {
  return InlineKeyboardMarkup(inlineKeyboard: [
    List.generate(
      links.length,
      (index) =>
          InlineKeyboardButton(text: "Канал #${index + 1}", url: links[index]),
    ),
    [InlineKeyboardButton(text: "Проверить", callbackData: "check")]
  ]);
}

InlineKeyboardMarkup adminMarkup() {
  return InlineKeyboardMarkup(inlineKeyboard: [
    [InlineKeyboardButton(text: "Мой фулл", callbackData: "view_full")],
    [
      InlineKeyboardButton(
          text: "«Загрузить фулл»", callbackData: "upload_full"),
      InlineKeyboardButton(text: "Изменить фулл»", callbackData: "change_full")
    ],
    [InlineKeyboardButton(text: "Каналы", callbackData: "view_channel")],
    [
      InlineKeyboardButton(
          text: "Загрузить каналы", callbackData: "upload_channel")
    ],
  ]);
}
