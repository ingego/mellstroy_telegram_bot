import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';

List<int> channels = [-1001875662745, -1001737560487];

List<String> admins = ["osketdev", "Dmitriy_adm"];
//TeleDartMessage? message;

bool changeMSG = false;
bool changeChannel = false;

bool createPost = false;

enum PostStyle {
  photo,
  video,
  text,
}

List<MessageTemplate> messages = [];

class MessageTemplate {
  final PostStyle style;
  final String title;
  final String fileId;

  MessageTemplate(this.style, this.title, this.fileId);
}

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
    _sendCommandCoCreatePost();
  }

  dynamic photo;
  _handleSend() {
    _td.onMessage(entityType: "*").listen((event) async {
      if (!admins.contains(event.chat.username.toString())) {
        return;
      }

      if (createPost) {
        if (textPost) {
          _createTextPost(event);
        }
        if (photoPost) {
          _createPhotoPost(event);
        }
        if (videoPost) {
          _createVideoPost(event);
        }
        _createPost(event);
      }

      // if (event.caption?.startsWith("/send-photo") ?? false) {
      //   photo = event.photo;
      //   var file = await _td.getFile(event.photo!.last.fileId);
      //   var link = file.getDownloadLink(token);
      //   await event.replyPhoto(file.fileId, caption: "тестовое");
      // }
      // event.replyPhoto(photo, )
      if (event.text?.startsWith("/admin-add") ?? false) {
        admins.add(event.text!.split("/admin-add").last.replaceAll(" ", ""));
        event.reply("Админ добавлен");
      }

      if (event.text?.startsWith("") ?? false) {
        return;
      }

      if (changeChannel) {
        var ids = event.text ?? "";
        channels = [];

        var idNew = ids.split("|");
        if (idNew.isNotEmpty) {
          for (var element in idNew) {
            if (element.isNotEmpty && element.length > 4) {
              channels.add(int.parse(element));
            }
          }

          event.reply("Каналы обновлены");
          changeChannel = false;
        }
        if (idNew.isNotEmpty) {
          // channels = idNew;
        }
      }
    });
  }

//так (https://i.ibb.co/HxgwYmd/image-2.png)
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
          await sendPostFinal(chatId, _td);
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
          "Приветствуем! Для получения фулла необходимо подписаться на этот паблики:",
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
        case "create_full":
          {
            await _td.sendMessage(
                event.teledartMessage!.chat.id, "Создайте пост по шаблону",
                replyMarkup: InlineKeyboardMarkup(inlineKeyboard: [
                  [
                    InlineKeyboardButton(
                        text: "Текстовый пост", callbackData: "text_post"),
                    InlineKeyboardButton(
                        text: "Пост с фото", callbackData: "photo_post"),
                    InlineKeyboardButton(
                        text: "Пост с Видео", callbackData: "video_post"),
                  ]
                ]));
            createPost = true;
          }
        case "view_full":
          {
            await sendPostFinal(event.teledartMessage!.chat.id, _td);

            //  message.forwardTo(chatId)
          }
        case "remove_full":
          {
            messages.clear();
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

  void _createPost(TeleDartMessage event) {
    // event.reply("Создайте пост по шаблону",
    //     replyMarkup: InlineKeyboardMarkup(inlineKeyboard: [
    //       [
    //         InlineKeyboardButton(
    //             text: "Текстовый пост", callbackData: "text_post"),
    //         InlineKeyboardButton(
    //             text: "Пост с фото", callbackData: "photo_post"),
    //         InlineKeyboardButton(
    //             text: "Пост с Видео", callbackData: "video_post"),
    //       ]
    //     ]));
    createPost = false;
  }

  void _sendCommandCoCreatePost() {
    _td.onCallbackQuery().listen((event) {
      if (event.data == "text_post") {
        textPost = true;
        photoPost = false;
        videoPost = false;
        _td.sendMessage(event.teledartMessage!.chat.id, "Отправьте сообщение");
      }
      if (event.data == "photo_post") {
        textPost = false;
        photoPost = true;
        videoPost = false;

        _td.sendMessage(event.teledartMessage!.chat.id, "Отправьте сообщение");
      }
      if (event.data == "video_post") {
        textPost = false;
        photoPost = false;
        videoPost = true;
        _td.sendMessage(event.teledartMessage!.chat.id, "Отправьте сообщение");
      }
    });
  }

  void _createTextPost(TeleDartMessage event) async {
    var type = PostStyle.text;
    var text = (event.text ?? event.caption);
    var msg = MessageTemplate(type, text ?? "", "");
    if (text == null && (text?.isEmpty ?? false)) {
      await event.reply("Ошибка, нет тела запроса");
      return;
    } else {
      messages.add(msg);
      event.reply(msg.title);
    }
    textPost = false;
  }

  void _createPhotoPost(TeleDartMessage event) async {
    var type = PostStyle.photo;
    var caption = event.caption;
    var body = event.photo?.last;
    var msg = MessageTemplate(type, caption ?? "", body?.fileId ?? "");
    if (body == null) {
      await event.reply("Ошибка, нет тела запроса");
    } else {
      messages.add(msg);
      event.replyPhoto(msg.fileId, caption: msg.title);
    }
  }

  void _createVideoPost(TeleDartMessage event) async {
    var type = PostStyle.video;

    var caption = event.caption;
    var body = event.video;
    var msg = MessageTemplate(type, caption ?? "", body?.fileId ?? "");
    if (body == null) {
      await event.reply("Ошибка, нет тела запроса");
    } else {
      messages.add(msg);
      event.replyVideo(msg.fileId, caption: msg.title);
    }
  }
}

Future<void> sendPostFinal(int chatId, TeleDart td) async {
  if (messages.isNotEmpty) {
    try {
      for (var e in messages) {
        switch (e.style) {
          case PostStyle.photo:
            {
              td.sendPhoto(chatId, e.fileId,
                  caption: e.title, protectContent: true);
            }
          case PostStyle.video:
            {
              td.sendVideo(chatId, e.fileId,
                  caption: e.title, protectContent: true);
            }
          case PostStyle.text:
            {
              td.sendMessage(chatId, e.title, protectContent: true);
            }
        }
      }
      //await message!.forwardTo(chatId, protectContent: true);
    } on Exception catch (e) {
      await td.sendMessage(chatId, e.toString());
    }
  } else {
    td.sendMessage(chatId, "Фулл не загружен в бота", protectContent: true);
  }
}

bool textPost = false;
bool photoPost = false;
bool videoPost = false;

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
      InlineKeyboardButton(text: "Создать пост", callbackData: "create_full"),
      InlineKeyboardButton(text: "Очистить", callbackData: "remove_full")
    ],
    [InlineKeyboardButton(text: "Каналы", callbackData: "view_channel")],
    [
      InlineKeyboardButton(
          text: "Загрузить каналы", callbackData: "upload_channel")
    ],
  ]);
}
