import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../features/interest/domain/interaction.dart';
import '../../features/safety/domain/safety_models.dart';

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
  String get authWelcome => isTurkish
      ? 'Bağlantılar bir yerden başlar.'
      : 'Every connection starts somewhere.';
  String get login => isTurkish ? 'Giriş Yap' : 'Sign in';
  String get register => isTurkish ? 'Kayıt Ol' : 'Create account';
  String get email => isTurkish ? 'E-posta' : 'Email';
  String get password => isTurkish ? 'Şifre' : 'Password';
  String get confirmPassword => isTurkish ? 'Şifre Tekrar' : 'Confirm password';
  String get forgotPassword =>
      isTurkish ? 'Şifremi Unuttum' : 'Forgot password';
  String get resetPassword => isTurkish
      ? 'Şifre Sıfırlama Bağlantısı Gönder'
      : 'Send password reset link';
  String get resetSent => isTurkish
      ? 'Eğer bu e-posta ile bir hesap varsa, sıfırlama bağlantısı gönderildi.'
      : 'If an account exists for this email, a reset link has been sent.';
  String get noAccount =>
      isTurkish ? 'Hesabın yok mu?' : "Don't have an account?";
  String get haveAccount =>
      isTurkish ? 'Zaten hesabın var mı?' : 'Already have an account?';
  String get ageRequirement => isTurkish
      ? 'NOX yalnızca 18 yaş ve üzeri kullanıcılar içindir.'
      : 'NOX is for people aged 18 and over.';
  String get passwordRequirements => isTurkish
      ? 'En az 8 karakter; büyük harf, küçük harf ve rakam içermeli.'
      : 'Use at least 8 characters with an uppercase letter, lowercase letter, and number.';
  String get securityMessage => isTurkish
      ? 'Güvenliğin ve gizliliğin bizim için önemli.'
      : 'Your safety and privacy matter to us.';
  String get privacy => isTurkish ? 'Gizlilik' : 'Privacy';
  String get terms => isTurkish ? 'Koşullar' : 'Terms';
  String get privacyPolicyTitle =>
      isTurkish ? 'Gizlilik Politikası' : 'Privacy Policy';
  String get termsOfServiceTitle =>
      isTurkish ? 'Kullanım Koşulları' : 'Terms of Service';
  String get privacyPolicyPlaceholder => isTurkish
      ? 'Gizlilik Politikası metni yakında burada yayınlanacak.'
      : 'The Privacy Policy will be published here soon.';
  String get termsOfServicePlaceholder => isTurkish
      ? 'Kullanım Koşulları metni yakında burada yayınlanacak.'
      : 'The Terms of Service will be published here soon.';
  String get continueWithGoogle =>
      isTurkish ? 'Google ile devam et' : 'Continue with Google';
  String get continueWithApple =>
      isTurkish ? 'Apple ile devam et' : 'Continue with Apple';
  String get or => isTurkish ? 'veya' : 'or';
  String get verificationTitle =>
      isTurkish ? 'E-postanı doğrula' : 'Verify your email';
  String verificationBody(String? email) => isTurkish
      ? '${email ?? 'E-posta adresine'} bir doğrulama bağlantısı gönderdik. Spam klasörünü de kontrol etmeyi unutma.'
      : 'We sent a verification link to ${email ?? 'your email address'}. Please check your spam folder too.';
  String get resendVerification => isTurkish
      ? 'Doğrulama E-postasını Tekrar Gönder'
      : 'Resend verification email';
  String get checkVerification =>
      isTurkish ? 'Kontrol Et' : 'Check verification';
  String get logout => isTurkish ? 'Çıkış Yap' : 'Sign out';
  String get loading => isTurkish ? 'Lütfen bekle…' : 'Please wait…';
  String get profileSetupTitle =>
      isTurkish ? 'Profil kurulumu' : 'Profile setup';
  String get profileSetupBody => isTurkish
      ? 'Profil bilgilerin bir sonraki aşamada güvenle alınacak.'
      : 'Your profile details will be collected safely in the next step.';
  String get requiredField =>
      isTurkish ? 'Bu alan zorunludur.' : 'This field is required.';
  String get invalidEmail => isTurkish
      ? 'Geçerli bir e-posta adresi gir.'
      : 'Enter a valid email address.';
  String get passwordsDoNotMatch =>
      isTurkish ? 'Şifreler eşleşmiyor.' : 'Passwords do not match.';
  String get passwordNotStrong => isTurkish
      ? 'Şifre gereksinimleri karşılamıyor.'
      : 'Your password does not meet the requirements.';
  String authError(String? code) => switch (code) {
        'invalidCredentials' => isTurkish
            ? 'E-posta veya şifre hatalı. Bilgilerini kontrol edip tekrar deneyebilirsin.'
            : 'The email or password is incorrect. Please check and try again.',
        'emailAlreadyInUse' => isTurkish
            ? 'Bu e-posta ile zaten bir hesap var.'
            : 'An account already exists with this email.',
        'weakPassword' => passwordNotStrong,
        'invalidEmail' => invalidEmail,
        'tooManyRequests' => isTurkish
            ? 'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar dene.'
            : 'Too many attempts. Please try again later.',
        'networkError' => isTurkish
            ? 'Bağlantını kontrol edip tekrar dene.'
            : 'Check your connection and try again.',
        'userDisabled' => isTurkish
            ? 'Bu hesap devre dışı bırakılmış.'
            : 'This account has been disabled.',
        'signInCancelled' =>
          isTurkish ? 'Giriş işlemi iptal edildi.' : 'Sign-in was cancelled.',
        _ => isTurkish
            ? 'Bir sorun oluştu. Lütfen tekrar dene.'
            : 'Something went wrong. Please try again.',
      };

  String get profileDiscoveryEyebrow =>
      isTurkish ? 'KİŞİLİĞİNİ KEŞFET' : 'DISCOVER YOUR VIBE';
  String get profileDiscoveryTitle => isTurkish
      ? 'Seni sen yapan küçük detaylar.'
      : 'The small details that make you, you.';
  String get profileDiscoveryBody => isTurkish
      ? 'Yanıtların profilini tamamlamak için yalnızca cihazında saklanır.'
      : 'Your answers stay on this device while you build your profile.';
  String selectionHint(int minimum, int maximum) => isTurkish
      ? 'En az $minimum, en fazla $maximum seçim yap.'
      : 'Choose at least $minimum and up to $maximum.';
  String selectedCount(int count, int maximum) =>
      isTurkish ? '$count / $maximum seçildi' : '$count / $maximum selected';
  String get profileContinue => isTurkish ? 'Devam et' : 'Continue';
  String get profileSkip => isTurkish ? 'Şimdilik geç' : 'Skip for now';
  String get profileBack => isTurkish ? 'Geri' : 'Back';
  String get profilePersonalTitle => isTurkish
      ? 'Birini sana yaklaştıracak bir cümle yaz.'
      : 'Write one line that brings someone closer to you.';
  String get profilePersonalBody => isTurkish
      ? 'Kısa, gerçek ve sana ait olsun.'
      : 'Keep it short, honest, and distinctly yours.';
  String get profilePersonalHint => isTurkish
      ? 'Örneğin: En iyi sohbetler plansız başlayanlardır.'
      : 'For example: The best conversations are the unplanned ones.';
  String charactersRemaining(int count) =>
      isTurkish ? '$count karakter kaldı' : '$count characters remaining';
  String get profileSummaryEyebrow =>
      isTurkish ? 'PROFİL ÖZETİ' : 'PROFILE SUMMARY';
  String get profileSummaryTitle => isTurkish
      ? 'Bağlantın düşüncelerinle başlasın.'
      : 'Let your connection start with your thoughts.';
  String get profileSummaryBody => isTurkish
      ? 'Bu yanıtları daha sonra profilinde düzenleyebilirsin.'
      : 'You can refine these answers in your profile later.';
  String get profileFinish =>
      isTurkish ? 'Profili tamamla' : 'Complete profile';
  String get profileSaved => isTurkish
      ? 'Taslağın bu cihazda kaydedildi.'
      : 'Your draft is saved on this device.';
  String profileQuestion(String key) =>
      _profileQuestionLabels[key]?[isTurkish ? 0 : 1] ?? key;
  String profileOption(String id) =>
      _profileOptionLabels[id]?[isTurkish ? 0 : 1] ?? id;

  static const _profileQuestionLabels = <String, List<String>>{
    'personality': [
      'Seni en iyi hangi özellikler anlatır?',
      'Which qualities describe you best?'
    ],
    'freeEvening': [
      'Boş bir akşamın nasıl geçer?',
      'How do you spend a free evening?'
    ],
    'attraction': [
      'Bir insanda seni ne etkiler?',
      'What draws you to someone?'
    ],
    'firstDate': [
      'İlk buluşma fikrin nedir?',
      'What sounds like a great first date?'
    ],
    'conversation': [
      'Sohbette neyi seversin?',
      'What do you enjoy in a conversation?'
    ],
    'lifeGoals': [
      'Hayatta seni ne ileri taşır?',
      'What moves you forward in life?'
    ],
    'weekend': ['İdeal hafta sonun?', 'Your ideal weekend?'],
    'music': ['Müzik dünyanda ne var?', 'What is in your music world?'],
    'travel': ['Seyahat tarzın?', 'Your travel style?'],
    'connection': [
      'Gerçek bir bağ senin için nedir?',
      'What makes a real connection for you?'
    ],
  };

  static const _profileOptionLabels = <String, List<String>>{
    'curious': ['Meraklı', 'Curious'],
    'funny': ['Komik', 'Funny'],
    'smart': ['Zeki', 'Smart'],
    'calm': ['Sakin', 'Calm'],
    'passionate': ['Tutkulu', 'Passionate'],
    'mysterious': ['Gizemli', 'Mysterious'],
    'creative': ['Yaratıcı', 'Creative'],
    'kind': ['Nazik', 'Kind'],
    'adventurous': ['Maceracı', 'Adventurous'],
    'ambitious': ['Hırslı', 'Ambitious'],
    'romantic': ['Romantik', 'Romantic'],
    'playful': ['Oyuncu ruhlu', 'Playful'],
    'thoughtful': ['Düşünceli', 'Thoughtful'],
    'social': ['Sosyal', 'Social'],
    'independent': ['Bağımsız', 'Independent'],
    'optimistic': ['İyimser', 'Optimistic'],
    'spontaneous': ['Spontane', 'Spontaneous'],
    'loyal': ['Sadık', 'Loyal'],
    'gentle': ['Yumuşak kalpli', 'Gentle'],
    'bold': ['Cesur', 'Bold'],
    'book': ['Kitap', 'Reading'],
    'series': ['Dizi', 'Series'],
    'friends': ['Arkadaşlar', 'Friends'],
    'music': ['Müzik', 'Music'],
    'walk': ['Gece yürüyüşü', 'A night walk'],
    'game': ['Oyun', 'Gaming'],
    'humor': ['Mizah', 'Humor'],
    'intelligence': ['Zekâ', 'Intelligence'],
    'kindness': ['İyilik', 'Kindness'],
    'confidence': ['Özgüven', 'Confidence'],
    'curiosity': ['Merak', 'Curiosity'],
    'ambition': ['Hırs', 'Ambition'],
    'calmEnergy': ['Sakin enerji', 'Calm energy'],
    'honesty': ['Dürüstlük', 'Honesty'],
    'coffee': ['Kahve', 'Coffee'],
    'museum': ['Müze', 'Museum'],
    'walkDate': ['Yürüyüş', 'A walk'],
    'dinner': ['Akşam yemeği', 'Dinner'],
    'concert': ['Konser', 'Concert'],
    'activity': ['Bir aktivite', 'An activity'],
    'deepTalk': ['Derin sohbet', 'Deep talk'],
    'banter': ['Tatlı atışma', 'Playful banter'],
    'ideas': ['Fikirler', 'Ideas'],
    'stories': ['Hikâyeler', 'Stories'],
    'listening': ['Dinlemek', 'Listening'],
    'questions': ['İyi sorular', 'Good questions'],
    'growth': ['Gelişim', 'Growth'],
    'career': ['Kariyer', 'Career'],
    'family': ['Aile', 'Family'],
    'travelGoal': ['Dünyayı görmek', 'Seeing the world'],
    'impact': ['Etki yaratmak', 'Making an impact'],
    'balance': ['Denge', 'Balance'],
    'slowMorning': ['Yavaş bir sabah', 'A slow morning'],
    'outdoors': ['Dışarıda olmak', 'Being outdoors'],
    'city': ['Şehirde kaybolmak', 'City wandering'],
    'hosting': ['Sofra kurmak', 'Hosting friends'],
    'exploring': ['Yeni yerler', 'Exploring'],
    'resting': ['Dinlenmek', 'Resting'],
    'indie': ['Indie', 'Indie'],
    'pop': ['Pop', 'Pop'],
    'electronic': ['Elektronik', 'Electronic'],
    'hiphop': ['Hip-hop', 'Hip-hop'],
    'jazz': ['Caz', 'Jazz'],
    'mixed': ['Her şeyden biraz', 'A bit of everything'],
    'beach': ['Sahil', 'Beach'],
    'cityBreak': ['Şehir kaçamağı', 'City break'],
    'nature': ['Doğa', 'Nature'],
    'roadTrip': ['Yolculuk', 'Road trip'],
    'culture': ['Kültür', 'Culture'],
    'staycation': ['Evde keşif', 'Staycation'],
    'trust': ['Güven', 'Trust'],
    'chemistry': ['Kimya', 'Chemistry'],
    'sharedValues': ['Ortak değerler', 'Shared values'],
    'growthTogether': ['Birlikte gelişmek', 'Growing together'],
    'funTogether': ['Birlikte gülmek', 'Having fun together'],
    'emotionalSafety': ['Duygusal güven', 'Emotional safety'],
  };

  String get profileSaving =>
      isTurkish ? 'Profilin hazırlanıyor...' : 'Preparing your profile...';
  String get profileCompleted =>
      isTurkish ? 'Profil tamamlandı.' : 'Profile completed.';
  String get profileSaveFailed => isTurkish
      ? 'Profilin kaydedilemedi. İnternet bağlantını kontrol edip tekrar deneyebilirsin.'
      : 'Your profile could not be saved. Check your internet connection and try again.';
  String get profileRetry => isTurkish ? 'Tekrar dene' : 'Try again';
  String get profileGenericError =>
      isTurkish ? 'Bir hata oluştu.' : 'Something went wrong.';
  String get homePlaceholderTitle =>
      isTurkish ? 'Profilin hazır.' : 'Your profile is ready.';
  String get homePlaceholderBody => isTurkish
      ? 'Keşif deneyimi yakında burada olacak.'
      : 'Your discovery experience will be here soon.';

  String get discoveryTitle =>
      isTurkish ? 'Bugün kimle tanışacaksın?' : 'Meet someone new.';
  String get discoveryEmpty => isTurkish
      ? 'Şimdilik burada sessizlik var.'
      : 'It is quiet here for now.';
  String get discoveryEmptyBody => isTurkish
      ? 'NOX\'ta yeni insanlar ortaya çıktıkça burada olacaklar.'
      : 'New people will appear here as they join NOX.';
  String get discoveryError =>
      isTurkish ? 'Bir şeyler ters gitti.' : 'Something went wrong.';
  String get discoveryLoadMore => isTurkish ? 'Daha fazlasını gör' : 'See more';
  String get discoveryIncomingTitle =>
      isTurkish ? '✨ Sana İlgi Var' : '✨ You Have Interest';
  String discoveryIncomingLikes(int count) => isTurkish
      ? '$count kişi seni beğendi.'
      : '$count ${count == 1 ? 'person likes' : 'people like'} you.';
  String discoveryIncomingSpecialInterests(int count) => isTurkish
      ? '✦ $count kişi sana Özel İlgi gönderdi.'
      : '✦ $count ${count == 1 ? 'person sent' : 'people sent'} you Special Interest.';
  String get discoveryIncomingEmptyTitle => isTurkish
      ? 'Henüz sana ulaşan bir ilgi yok.'
      : 'No interest has reached you yet.';
  String get discoveryIncomingEmptyBody => isTurkish
      ? 'Belki de ilk kıvılcım birazdan gelir.'
      : 'Maybe the first spark is just around the corner.';
  String get discoveryIncomingContinue =>
      isTurkish ? 'Keşfetmeye Devam Et' : 'Keep discovering';
  String get discoveryIncomingView =>
      isTurkish ? 'İlgileri Gör' : 'View interests';
  String get discoveryIncomingViewPremium =>
      isTurkish ? 'Seni Beğenenleri Gör' : 'See who likes you';
  String get discoveryIncomingUnavailable => isTurkish
      ? 'İlgiler şu anda yüklenemiyor.'
      : 'Interests cannot be loaded right now.';
  String get discoveryIncomingRetry => isTurkish ? 'Tekrar dene' : 'Try again';
  String get discoveryIncomingPlaceholder => isTurkish
      ? 'İlgi ayrıntıları yakında burada olacak.'
      : 'Interest details will be available here soon.';
  String discoveryIncomingSemantic(int likes, int specialInterests, bool empty) => empty
      ? '$discoveryIncomingTitle. $discoveryIncomingEmptyTitle $discoveryIncomingEmptyBody'
      : '$discoveryIncomingTitle. ${discoveryIncomingLikes(likes)}${specialInterests == 0 ? '' : ' ${discoveryIncomingSpecialInterests(specialInterests)}'}';
  String get discoveryPass => isTurkish ? 'Geç' : 'Pass';
  String get discoveryLike => isTurkish ? 'İlgimi Çekti' : 'I\'m interested';
  String get discoverySpecialInterest =>
      isTurkish ? 'Özel İlgi' : 'Special Interest';
  String get discoverySpecialInterestBody => isTurkish
      ? 'Bu kişiye diğerlerinden farklı olduğunu hissettir.'
      : 'Let this person know they stand out from the rest.';
  String get discoverySpecialInterestPremiumNote => isTurkish
      ? 'Özel İlgi, NOX Premium özelliğidir.'
      : 'Special Interest is a NOX Premium feature.';
  String get discoveryExplorePremium =>
      isTurkish ? 'Premium\'u Keşfet' : 'Explore Premium';
  String get discoveryPremiumPlaceholder => isTurkish
      ? 'Premium keşfi yakında burada olacak.'
      : 'Premium discovery will be available here soon.';
  String get discoveryNotNow => isTurkish ? 'Şimdi Değil' : 'Not now';
  String get discoverySpecialInterestReasonTitle => isTurkish
      ? 'Neden özellikle ilgini çekti?'
      : 'Why did they especially catch your interest?';
  String get discoverySpecialInterestReasonBody => isTurkish
      ? 'Bir neden seç. Bu, gönderdiğin Özel İlgi\'yi daha anlamlı hale getirir.'
      : 'Choose a reason. It makes the Special Interest you send more meaningful.';
  String get discoveryChooseReason =>
      isTurkish ? 'Bir neden seç.' : 'Choose a reason.';
  String discoverySpecialInterestReason(SpecialInterestReason reason) =>
      switch (reason) {
        SpecialInterestReason.personality =>
          isTurkish ? 'Kişiliği' : 'Personality',
        SpecialInterestReason.humor => isTurkish ? 'Mizahı' : 'Humor',
        SpecialInterestReason.music =>
          isTurkish ? 'Müzik zevki' : 'Music taste',
        SpecialInterestReason.lifestyle =>
          isTurkish ? 'Yaşam tarzı' : 'Lifestyle',
        SpecialInterestReason.profileEnergy =>
          isTurkish ? 'Profil enerjisi' : 'Profile energy',
        SpecialInterestReason.overall =>
          isTurkish ? 'Genel olarak ilgimi çekti' : 'I\'m interested overall',
      };
  String get discoverySpecialInterestSend =>
      isTurkish ? 'Özel İlgi Gönder' : 'Send Special Interest';
  String get discoverySpecialInterestSent =>
      isTurkish ? '✦ Özel İlgi gönderildi.' : '✦ Special Interest sent.';
  String get discoverySpecialInterestFailed => isTurkish
      ? 'Özel İlgi gönderilemedi. Tekrar deneyin.'
      : 'Special Interest could not be sent. Please try again.';
  String get discoverySpecialInterestLoading =>
      isTurkish ? 'Yükleniyor.' : 'Loading.';
  String discoveryReasonSelectionSemantics(
          SpecialInterestReason reason, bool selected) =>
      '${discoverySpecialInterestReason(reason)}, ${selected ? (isTurkish ? 'seçildi' : 'selected') : (isTurkish ? 'seçilmedi' : 'not selected')}';
  String get discoveryProfile => isTurkish ? 'Profil' : 'Profile';
  String get discoveryAnonymous => isTurkish ? 'NOX üyesi' : 'NOX member';
  String get discoveryPersonality => isTurkish ? 'Kişilik' : 'Personality';
  String get discoveryFreeTime => isTurkish ? 'Boş zaman' : 'Free time';
  String get discoveryDate => isTurkish ? 'Buluşma tarzı' : 'Date style';
  String get discoveryConversation => isTurkish ? 'Sohbet' : 'Conversation';
  String get discoveryLifeGoals => isTurkish ? 'Hayat hedefleri' : 'Life goals';
  String get discoveryMusic => isTurkish ? 'Müzik' : 'Music';
  String get discoveryTravel => isTurkish ? 'Seyahat' : 'Travel';
  String get discoveryConnection => isTurkish ? 'Bağ kurmak' : 'Connection';
  String get discoveryReport =>
      isTurkish ? 'Profil hakkında bildir' : 'Report profile';
  String get discoveryBlock => isTurkish ? 'Engelle' : 'Block';
  String get discoverySafetyPlaceholder => isTurkish
      ? 'Bu güvenlik aksiyonu yakında kullanılabilecek.'
      : 'This safety action will be available soon.';
  String discoverySemantic(
          String? name, int? age, String? city, List<String> tags) =>
      '${name ?? discoveryAnonymous}${age == null ? '' : ', $age'}${city == null ? '' : ', $city'}. ${tags.join(', ')}';

  String get safetyOptions =>
      isTurkish ? 'Profil seçenekleri' : 'Profile options';
  String get safetyCancel => isTurkish ? 'Vazgeç' : 'Cancel';
  String get safetyBlockTitle =>
      isTurkish ? 'Bu kişiyi engellemek istiyor musun?' : 'Block this person?';
  String get safetyBlockBody => isTurkish
      ? 'Engellediğinde bu kişi Discovery’de tekrar karşına çıkmaz.'
      : "When you block someone, they won't appear in Discovery again.";
  String get safetyBlocked =>
      isTurkish ? 'Bu kişi engellendi.' : 'This person has been blocked.';
  String get safetyReportTitle => isTurkish
      ? 'Bu kullanıcıyı neden bildiriyorsun?'
      : 'Why are you reporting this person?';
  String get safetyConfidential => isTurkish
      ? 'Bildirimin gizli tutulur.'
      : 'Your report is kept confidential.';
  String get safetyDetails => isTurkish
      ? 'Biraz daha anlatmak ister misin?'
      : 'Would you like to share more?';
  String get safetyDetailsHint => isTurkish
      ? 'İstersen yaşadığın durumu kısaca anlatabilirsin.'
      : 'You can briefly describe what happened.';
  String get safetyAlsoBlock =>
      isTurkish ? 'Bu kişiyi aynı zamanda engelle' : 'Also block this person';
  String get safetySubmit => isTurkish ? 'Bildirim gönder' : 'Submit report';
  String get safetyReceived =>
      isTurkish ? 'Bildirim alındı.' : 'Report received.';
  String get safetyFailed => isTurkish
      ? 'İşlem tamamlanamadı. Tekrar dene.'
      : 'The action could not be completed. Please try again.';
  String reportReason(ReportReason reason) => switch (reason) {
        ReportReason.harassment => isTurkish
            ? 'Taciz veya rahatsız edici davranış'
            : 'Harassment or unwanted behavior',
        ReportReason.inappropriateMessages =>
          isTurkish ? 'Uygunsuz mesajlar' : 'Inappropriate messages',
        ReportReason.fakeProfile => isTurkish ? 'Sahte profil' : 'Fake profile',
        ReportReason.sexualContent =>
          isTurkish ? 'Cinsel içerik' : 'Sexual content',
        ReportReason.threat => isTurkish
            ? 'Tehdit veya güvenlik endişesi'
            : 'Threat or safety concern',
        ReportReason.scam =>
          isTurkish ? 'Dolandırıcılık / para isteme' : 'Scam or money request',
        ReportReason.inappropriatePhoto =>
          isTurkish ? 'Uygunsuz fotoğraf' : 'Inappropriate photo',
        ReportReason.spam => isTurkish ? 'Spam' : 'Spam',
        ReportReason.other => isTurkish ? 'Diğer' : 'Other'
      };

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
