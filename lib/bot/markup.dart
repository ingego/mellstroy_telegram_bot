import 'package:teledart/model.dart';

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
