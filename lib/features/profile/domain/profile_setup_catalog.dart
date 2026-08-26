import 'profile_setup_draft.dart';

class ProfileQuestionDefinition {
  const ProfileQuestionDefinition({
    required this.question,
    required this.minimum,
    required this.maximum,
    required this.choices,
  });

  final ProfileQuestion question;
  final int minimum;
  final int maximum;
  final List<ProfileChoice> choices;
}

const profileQuestions = <ProfileQuestionDefinition>[
  ProfileQuestionDefinition(
      question: ProfileQuestion.personality,
      minimum: 3,
      maximum: 5,
      choices: [
        ProfileChoice(id: 'curious', emoji: '🔎'),
        ProfileChoice(id: 'funny', emoji: '😄'),
        ProfileChoice(id: 'smart', emoji: '🧠'),
        ProfileChoice(id: 'calm', emoji: '🌊'),
        ProfileChoice(id: 'passionate', emoji: '🔥'),
        ProfileChoice(id: 'mysterious', emoji: '🌙'),
        ProfileChoice(id: 'creative', emoji: '🎨'),
        ProfileChoice(id: 'kind', emoji: '🤍'),
        ProfileChoice(id: 'adventurous', emoji: '🧭'),
        ProfileChoice(id: 'ambitious', emoji: '🚀'),
        ProfileChoice(id: 'romantic', emoji: '🌹'),
        ProfileChoice(id: 'playful', emoji: '✨'),
        ProfileChoice(id: 'thoughtful', emoji: '💭'),
        ProfileChoice(id: 'social', emoji: '🫶'),
        ProfileChoice(id: 'independent', emoji: '🪐'),
        ProfileChoice(id: 'optimistic', emoji: '☀️'),
        ProfileChoice(id: 'spontaneous', emoji: '⚡'),
        ProfileChoice(id: 'loyal', emoji: '🛡️'),
        ProfileChoice(id: 'gentle', emoji: '🍃'),
        ProfileChoice(id: 'bold', emoji: '💫'),
      ]),
  ProfileQuestionDefinition(
      question: ProfileQuestion.freeEvening,
      minimum: 1,
      maximum: 3,
      choices: [
        ProfileChoice(id: 'book', emoji: '📚'),
        ProfileChoice(id: 'series', emoji: '📺'),
        ProfileChoice(id: 'friends', emoji: '🍷'),
        ProfileChoice(id: 'music', emoji: '🎧'),
        ProfileChoice(id: 'walk', emoji: '🌃'),
        ProfileChoice(id: 'game', emoji: '🎮'),
      ]),
  ProfileQuestionDefinition(
      question: ProfileQuestion.attraction,
      minimum: 1,
      maximum: 5,
      choices: [
        ProfileChoice(id: 'humor', emoji: '😄'),
        ProfileChoice(id: 'intelligence', emoji: '🧠'),
        ProfileChoice(id: 'kindness', emoji: '🤍'),
        ProfileChoice(id: 'confidence', emoji: '✨'),
        ProfileChoice(id: 'curiosity', emoji: '🔎'),
        ProfileChoice(id: 'ambition', emoji: '🚀'),
        ProfileChoice(id: 'calmEnergy', emoji: '🌊'),
        ProfileChoice(id: 'honesty', emoji: '🫱'),
      ]),
  ProfileQuestionDefinition(
      question: ProfileQuestion.firstDate,
      minimum: 1,
      maximum: 3,
      choices: [
        ProfileChoice(id: 'coffee', emoji: '☕'),
        ProfileChoice(id: 'museum', emoji: '🏛️'),
        ProfileChoice(id: 'walkDate', emoji: '🌿'),
        ProfileChoice(id: 'dinner', emoji: '🍽️'),
        ProfileChoice(id: 'concert', emoji: '🎵'),
        ProfileChoice(id: 'activity', emoji: '🎳'),
      ]),
  ProfileQuestionDefinition(
      question: ProfileQuestion.conversation,
      minimum: 1,
      maximum: 4,
      choices: [
        ProfileChoice(id: 'deepTalk', emoji: '💭'),
        ProfileChoice(id: 'banter', emoji: '😄'),
        ProfileChoice(id: 'ideas', emoji: '💡'),
        ProfileChoice(id: 'stories', emoji: '📖'),
        ProfileChoice(id: 'listening', emoji: '👂'),
        ProfileChoice(id: 'questions', emoji: '❓'),
      ]),
  ProfileQuestionDefinition(
      question: ProfileQuestion.lifeGoals,
      minimum: 1,
      maximum: 4,
      choices: [
        ProfileChoice(id: 'growth', emoji: '🌱'),
        ProfileChoice(id: 'career', emoji: '🎯'),
        ProfileChoice(id: 'family', emoji: '🏡'),
        ProfileChoice(id: 'travelGoal', emoji: '✈️'),
        ProfileChoice(id: 'impact', emoji: '🌍'),
        ProfileChoice(id: 'balance', emoji: '⚖️'),
      ]),
  ProfileQuestionDefinition(
      question: ProfileQuestion.weekend,
      minimum: 1,
      maximum: 3,
      choices: [
        ProfileChoice(id: 'slowMorning', emoji: '☀️'),
        ProfileChoice(id: 'outdoors', emoji: '🏕️'),
        ProfileChoice(id: 'city', emoji: '🏙️'),
        ProfileChoice(id: 'hosting', emoji: '🍝'),
        ProfileChoice(id: 'exploring', emoji: '🗺️'),
        ProfileChoice(id: 'resting', emoji: '🛋️'),
      ]),
  ProfileQuestionDefinition(
      question: ProfileQuestion.music,
      minimum: 1,
      maximum: 3,
      choices: [
        ProfileChoice(id: 'indie', emoji: '🎸'),
        ProfileChoice(id: 'pop', emoji: '🎤'),
        ProfileChoice(id: 'electronic', emoji: '🎛️'),
        ProfileChoice(id: 'hiphop', emoji: '🎙️'),
        ProfileChoice(id: 'jazz', emoji: '🎷'),
        ProfileChoice(id: 'mixed', emoji: '🌈'),
      ]),
  ProfileQuestionDefinition(
      question: ProfileQuestion.travel,
      minimum: 1,
      maximum: 3,
      choices: [
        ProfileChoice(id: 'beach', emoji: '🏖️'),
        ProfileChoice(id: 'cityBreak', emoji: '🏙️'),
        ProfileChoice(id: 'nature', emoji: '🏔️'),
        ProfileChoice(id: 'roadTrip', emoji: '🚗'),
        ProfileChoice(id: 'culture', emoji: '🏛️'),
        ProfileChoice(id: 'staycation', emoji: '🪴'),
      ]),
  ProfileQuestionDefinition(
      question: ProfileQuestion.connection,
      minimum: 1,
      maximum: 4,
      choices: [
        ProfileChoice(id: 'trust', emoji: '🤝'),
        ProfileChoice(id: 'chemistry', emoji: '✨'),
        ProfileChoice(id: 'sharedValues', emoji: '🧩'),
        ProfileChoice(id: 'growthTogether', emoji: '🌱'),
        ProfileChoice(id: 'funTogether', emoji: '😄'),
        ProfileChoice(id: 'emotionalSafety', emoji: '🫶'),
      ]),
];
