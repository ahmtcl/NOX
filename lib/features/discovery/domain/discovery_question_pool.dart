import 'discovery_question.dart';

class DiscoveryQuestionPool {
  factory DiscoveryQuestionPool(Iterable<DiscoveryQuestion> questions) {
    final values = List<DiscoveryQuestion>.unmodifiable(questions);
    final ids = values.map((question) => question.id).toList();
    if (ids.toSet().length != ids.length) {
      throw ArgumentError.value(questions, 'questions', 'must have unique IDs');
    }
    for (final category in DiscoveryQuestionCategory.values) {
      if (values.where((question) => question.category == category).length < 15) {
        throw ArgumentError.value(
          questions,
          'questions',
          'must include at least 15 questions for ${category.name}',
        );
      }
    }
    return DiscoveryQuestionPool._(values);
  }

  const DiscoveryQuestionPool._(this.questions);

  final List<DiscoveryQuestion> questions;

  List<DiscoveryQuestion> forCategory(DiscoveryQuestionCategory category) =>
      questions.where((question) => question.category == category).toList();
}

final discoveryQuestionPool = DiscoveryQuestionPool([
  DiscoveryQuestion(id: 'character_001', text: 'Bir insanda seni en çok etkileyen özellik nedir?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_002', text: 'Seni tanıyan insanlar seni en çok hangi yönünle anlatır?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_003', text: 'Bir sorun olduğunda hemen konuşmayı mı, biraz düşünmeyi mi tercih edersin?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_004', text: 'Yeni tanıştığın birinde ilk dikkat ettiğin şey nedir?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_005', text: 'Kendinde geliştirmeye en çok önem verdiğin yön hangisi?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_006', text: 'Günün zor geçtiğinde seni en iyi ne toparlar?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_007', text: 'Küçük ama seni mutlu eden bir alışkanlığın var mı?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_008', text: 'Bir karar verirken sezgilerin mi, mantığın mı daha baskındır?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_009', text: 'Sence iyi bir dinleyici olmak ne gerektirir?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_010', text: 'Arkadaşların senden en çok hangi konuda fikir ister?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_011', text: 'Yeni bir ortama girdiğinde önce gözlemlemeyi mi, sohbet etmeyi mi seversin?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_012', text: 'Hayatında sana yön veren bir değer nedir?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_013', text: 'Sence seni sen yapan bir özellik hangisi?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_014', text: 'Birine güvenmeni sağlayan davranış nedir?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'character_015', text: 'Kendini en rahat hangi ortamda ifade edersin?', category: DiscoveryQuestionCategory.character),
  DiscoveryQuestion(id: 'lifestyle_001', text: 'Planlı bir hafta sonu mu, aniden çıkan bir yolculuk mu?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_002', text: 'Kalabalık bir akşam mı, sakin bir akşam mı sana daha iyi gelir?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_003', text: 'Bir gün tamamen sana ait olsa nasıl geçirirdin?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_004', text: 'Yeni yerler keşfetmek mi, sevdiğin yerlere tekrar gitmek mi?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_005', text: 'Şehirde geçireceğin ideal bir gün nasıl başlar?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_006', text: 'Boş bir akşamda seni en çok hangi aktivite dinlendirir?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_007', text: 'Kahveni alıp uzun uzun oturacağın bir yer nasıl olurdu?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_008', text: 'Güne erken başlamak mı, geceyi uzatmak mı sana daha yakın?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_009', text: 'Bir şehri tanımak için önce nerelerini gezersin?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_010', text: 'Hafta içinde küçük bir keyif anını nasıl yaratırsın?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_011', text: 'Evde ağırlamak mı, dışarıda buluşmak mı sana daha keyifli gelir?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_012', text: 'Bir tatilde tempolu keşif mi, yavaş bir dinlenme mi seçersin?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_013', text: 'Seni yeni bir hobi denemeye ne ikna eder?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_014', text: 'Müzik dinlemek için en sevdiğin an hangisi?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'lifestyle_015', text: 'Günlük rutininde vazgeçmek istemeyeceğin küçük şey nedir?', category: DiscoveryQuestionCategory.lifestyle),
  DiscoveryQuestion(id: 'connection_001', text: 'Kendini yakın hissettiğin bir insanda ne ararsın?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_002', text: 'Bir ilişkide senin için vazgeçilmez olan şey nedir?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_003', text: 'İki insan arasındaki gerçek uyum sence nasıl anlaşılır?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_004', text: 'Birlikte geçirilen kaliteli zaman senin için ne demek?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_005', text: 'Güzel bir sohbetin aklında kalmasını sağlayan şey nedir?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_006', text: 'Bir insanla bağ kurarken seni rahatlatan şey nedir?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_007', text: 'Sence iyi bir ilk buluşma hangi hissi bırakmalı?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_008', text: 'Birlikte gülmek mi, derin konuşmak mı seni daha yakın hissettirir?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_009', text: 'Birinin seni gerçekten anladığını nasıl fark edersin?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_010', text: 'Yakınlık kurarken küçük jestlerin yeri sence nedir?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_011', text: 'Birlikte yeni bir şey denemek sana ne hissettirir?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_012', text: 'Sence iyi iletişimde en önemli şey nedir?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_013', text: 'Bir arkadaşlığın uzun sürmesini sağlayan şey nedir?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_014', text: 'Bir insana kendini açmanı kolaylaştıran şey nedir?', category: DiscoveryQuestionCategory.connection),
  DiscoveryQuestion(id: 'connection_015', text: 'Birlikteyken zamanı unutturan şey sence nedir?', category: DiscoveryQuestionCategory.connection),
]);
