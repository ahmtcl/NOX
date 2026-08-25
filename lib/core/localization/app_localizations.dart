import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('tr'), Locale('en')];
  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    _NoxLocalizationsDelegate(),
  ];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get isTurkish => locale.languageCode == 'tr';
  String get appName => 'NOX';
  String get tagline => isTurkish
      ? 'Önce konuş. Bağ kur. Sonra gör.'
      : 'Talk first. Connect. Then reveal.';
  String get skip => isTurkish ? 'Atla' : 'Skip';
  String get back => isTurkish ? 'Geri' : 'Back';
  String get next => isTurkish ? 'Devam et' : 'Continue';
  String get startNox => isTurkish ? "NOX'a Başla" : 'Start NOX';
  String get authPlaceholderTitle =>
      isTurkish ? 'Devam etmek için hazırız.' : 'You are ready to continue.';
  String get authPlaceholderBody => isTurkish
      ? 'Güvenli başlangıç akışı yakında burada olacak.'
      : 'The secure sign-in flow will be here soon.';

  String onboardingTitle(int index) => switch (index) {
        0 => isTurkish
            ? 'Fotoğraftan önce kişiyi tanı.'
            : 'Know the person before the photo.',
        1 => isTurkish ? 'Önce konuş.' : 'Talk first.',
        2 => isTurkish ? 'Kimyayı hisset.' : 'Feel the chemistry.',
        _ => isTurkish
            ? 'Tanışmanın daha iyi bir yolu var.'
            : 'There is a better way to meet.',
      };

  String onboardingBody(int index) => switch (index) {
        0 => isTurkish
            ? 'NOX, insanları yalnızca görünüşlerine göre değil, düşünceleri ve kişilikleri üzerinden keşfetmeni sağlar.'
            : 'NOX helps you discover people through their thoughts and personality, not only their appearance.',
        1 => isTurkish
            ? 'Blind Date ile karşındaki kişiyi görmeden sohbet etmeye başlayabilir, gerçek bir bağlantı olup olmadığını keşfedebilirsin.'
            : 'With Blind Date, begin a conversation before seeing the other person and discover whether there is a real connection.',
        2 => isTurkish
            ? 'Birbirinizi gerçekten merak ettiğinizde Reveal ile profilinizi karşılıklı olarak açın.'
            : 'When curiosity is mutual, reveal your profiles together.',
        _ => isTurkish
            ? "NOX'ta amaç daha fazla kişiyle eşleşmek değil, doğru insanlarla daha anlamlı bağlantılar kurmak."
            : 'NOX is not about more matches. It is about more meaningful connections with the right people.',
      };
}

class _NoxLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _NoxLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(Locale(locale.languageCode));

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_NoxLocalizationsDelegate old) => false;
}
