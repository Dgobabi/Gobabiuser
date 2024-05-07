import 'package:flutter/material.dart';
import '../main.dart';
import '../model/LanguageDataModel.dart';
import '../model/TextModel.dart';
import 'images.dart';

List<TexIModel> getBookList() {
  List<TexIModel> list = [];
  list.add(TexIModel(title: 'Home', iconData: Icons.home));
  list.add(TexIModel(title: 'Work', iconData: Icons.work));
  list.add(TexIModel(title: 'Recently', iconData: Icons.history));
  return list;
}

List<LanguageDataModel> languageList() {
  return [
    LanguageDataModel(
        id: 6,
        name: 'French',
        subTitle: 'Français',
        languageCode: 'fr',
        fullLanguageCode: 'fr-FR',
        flag: ic_france),
    LanguageDataModel(
        id: 1,
        name: 'English',
        subTitle: 'English',
        languageCode: 'en',
        fullLanguageCode: 'en-US',
        flag: ic_us),
    LanguageDataModel(
        id: 2,
        name: 'Hindi',
        subTitle: 'हिंदी',
        languageCode: 'hi',
        fullLanguageCode: 'hi-IN',
        flag: ic_india),
    LanguageDataModel(
        id: 3,
        name: 'Arabic',
        subTitle: 'عربي',
        languageCode: 'ar',
        fullLanguageCode: 'ar-AR',
        flag: ic_ar),
    LanguageDataModel(
        id: 4,
        name: 'Spanish',
        subTitle: 'Española',
        languageCode: 'es',
        fullLanguageCode: 'es-ES',
        flag: ic_spain),
    LanguageDataModel(
        id: 5,
        name: 'Afrikaans',
        subTitle: 'Afrikaans',
        languageCode: 'af',
        fullLanguageCode: 'af-AF',
        flag: ic_south_africa),
    LanguageDataModel(
        id: 7,
        name: 'German',
        subTitle: 'Deutsch',
        languageCode: 'de',
        fullLanguageCode: 'de-DE',
        flag: ic_germany),
    LanguageDataModel(
        id: 8,
        name: 'Indonesian',
        subTitle: 'bahasa Indonesia',
        languageCode: 'id',
        fullLanguageCode: 'id-ID',
        flag: ic_indonesia),
    LanguageDataModel(
        id: 9,
        name: 'Portuguese',
        subTitle: 'Português',
        languageCode: 'pt',
        fullLanguageCode: 'pt-PT',
        flag: ic_portugal),
    LanguageDataModel(
        id: 10,
        name: 'Turkish',
        subTitle: 'Türkçe',
        languageCode: 'tr',
        fullLanguageCode: 'tr-TR',
        flag: ic_turkey),
    LanguageDataModel(
        id: 11,
        name: 'vietnamese',
        subTitle: 'Tiếng Việt',
        languageCode: 'vi',
        fullLanguageCode: 'vi-VI',
        flag: ic_vitnam),
    LanguageDataModel(
        id: 12,
        name: 'Dutch',
        subTitle: 'Nederlands',
        languageCode: 'nl',
        fullLanguageCode: 'nl-NL',
        flag: ic_dutch),
    LanguageDataModel(
        id: 13,
        name: 'Panjabi',
        subTitle: 'ਪੰਜਾਬੀ',
        languageCode: 'pa',
        fullLanguageCode: 'pa-IN',
        flag: ic_india),
    LanguageDataModel(
        id: 14,
        name: 'Tamil',
        subTitle: 'தமிழ்',
        languageCode: 'ta',
        fullLanguageCode: 'ta-IN',
        flag: ic_india),
    LanguageDataModel(
        id: 15,
        name: 'Urdu',
        subTitle: 'اردو',
        languageCode: 'ur',
        fullLanguageCode: 'ur-UR',
        flag: ic_pakistan),
    LanguageDataModel(
        id: 16,
        name: 'Russian',
        subTitle: 'Русский',
        languageCode: 'ru',
        fullLanguageCode: 'ru-RU',
        flag: ic_russia),
    LanguageDataModel(
        id: 17,
        name: 'Chinese',
        subTitle: '中国人',
        languageCode: 'zh',
        fullLanguageCode: 'zh-CN',
        flag: ic_china),
    LanguageDataModel(
        id: 18,
        name: 'Korean',
        subTitle: '한국인',
        languageCode: 'ko',
        fullLanguageCode: 'ko-KR',
        flag: ic_korea),
    LanguageDataModel(
        id: 19,
        name: 'Japanese',
        subTitle: '日本',
        languageCode: 'ja',
        fullLanguageCode: 'ja-JP',
        flag: ic_japan),
    LanguageDataModel(
        id: 20,
        name: 'Bengali',
        subTitle: 'বাংলা',
        languageCode: 'bn',
        fullLanguageCode: 'bn-BN',
        flag: ic_bangladesh),
    LanguageDataModel(
        id: 21,
        name: 'Armenian',
        subTitle: 'հայերեն',
        languageCode: 'hy',
        fullLanguageCode: 'hy-AM',
        flag: ic_armenia),
  ];
}

List<String> getCancelReasonList() {
  List<String> list = [];
  list.add(language.driverGoingWrongDirection);
  list.add(language.pickUpTimeTakingTooLong);
  list.add(language.driverAskedMeToCancel);
  list.add(language.others);
  return list;
}
