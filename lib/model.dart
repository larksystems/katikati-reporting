import 'dart:core';

class TopMetric {
  num conversations = 0;
  num messages_outgoing = 0;
  num messages_incoming_non_demog = 0;
  num messages_incoming_demog = 0;
  num messages = 0;

  TopMetric(
      this.conversations,
      this.messages_outgoing,
      this.messages_incoming_non_demog,
      this.messages_incoming_demog,
      this.messages);

  factory TopMetric.fromFirebaseMap(Map<String, dynamic> obj) {
    var incoming_demog = obj['incoming_messages_count'] -
        obj['incoming_non_demogs_messages_count'];
    return TopMetric(
        obj['conversations_count'],
        obj['outgoing_messages_count'],
        obj['incoming_non_demogs_messages_count'],
        incoming_demog,
        obj['messages_count']);
  }
}

class GenderData {
  num female = 0;
  num male = 0;
  num unknown = 0;

  GenderData(this.female, this.male, this.unknown);

  factory GenderData.fromFirebaseMap(Map<String, dynamic> obj) {
    return GenderData(obj['female'], obj['male'], obj['unknown']);
  }
}

class AgeData {
  num bucket_0_18 = 0;
  num bucket_18_35 = 0;
  num bucket_35_50 = 0;
  num bucket_50_ = 0;
  num unknown = 0;

  AgeData(this.bucket_0_18, this.bucket_18_35, this.bucket_35_50,
      this.bucket_50_, this.unknown);

  factory AgeData.fromFirebaseMap(Map<String, dynamic> obj) {
    return AgeData(
        obj['0_18'], obj['18_35'], obj['35_50'], obj['50+'], obj['unknown']);
  }
}

class ThemeData {
  num answer = 0;
  num question = 0;
  num escalation = 0;

  num attitude = 0;
  num behaviour = 0;
  num knowledge = 0;

  num about_coronavirus = 0;
  num anxiety_panic = 0;
  num collective_hope = 0;
  num gratitude = 0;
  num how_spread_transmitted = 0;
  num how_to_prevent = 0;
  num how_to_treat = 0;
  num opinion_on_govt_policy = 0;
  num other_theme = 0;
  num rumour_stigma_misinfo = 0;
  num symptoms = 0;
  num what_is_govt_policy = 0;
  num kenya_update = 0;

  ThemeData(
      this.answer,
      this.question,
      this.escalation,
      // --
      this.attitude,
      this.behaviour,
      this.knowledge,
      // --
      this.about_coronavirus,
      this.anxiety_panic,
      this.collective_hope,
      this.gratitude,
      this.how_spread_transmitted,
      this.how_to_prevent,
      this.how_to_treat,
      this.opinion_on_govt_policy,
      this.other_theme,
      this.rumour_stigma_misinfo,
      this.symptoms,
      this.what_is_govt_policy,
      this.kenya_update);

  factory ThemeData.fromFirebaseMap(Map<String, dynamic> obj) {
    return ThemeData(
        obj['answer'],
        obj['question'],
        obj['escalate'],
        obj['attitude'],
        obj['behaviour'],
        obj['knowledge'],
        obj['about_coronavirus'],
        obj['anxiety_panic'],
        obj['collective_hope'],
        obj['gratitude'],
        obj['how_spread_transmitted'],
        obj['how_to_prevent'],
        obj['how_to_treat'],
        obj['opinion_on_govt_policy'],
        obj['other_theme'],
        obj['rumour_stigma_misinfo'],
        obj['symptoms'],
        obj['what_is_govt_policy'],
        obj['kenya_update']);
  }
}

class DaySummary {
  DateTime date;
  AgeData age;
  GenderData gender;
  ThemeData theme;
  bool radioShow;

  DaySummary operator *(num scale) {
    var newAge = AgeData(age.bucket_0_18 * scale, age.bucket_18_35 * scale,
        age.bucket_35_50 * scale, age.bucket_50_ * scale, age.unknown * scale);
    var newGender = GenderData(
        gender.female * scale, gender.male * scale, gender.unknown * scale);
    var newTheme = ThemeData(
        theme.answer * scale,
        theme.question * scale,
        theme.escalation * scale,
        theme.attitude * scale,
        theme.behaviour * scale,
        theme.knowledge * scale,
        theme.about_coronavirus * scale,
        theme.anxiety_panic * scale,
        theme.collective_hope * scale,
        theme.gratitude * scale,
        theme.how_spread_transmitted * scale,
        theme.how_to_prevent * scale,
        theme.how_to_treat * scale,
        theme.opinion_on_govt_policy * scale,
        theme.other_theme * scale,
        theme.rumour_stigma_misinfo * scale,
        theme.symptoms * scale,
        theme.what_is_govt_policy * scale,
        theme.kenya_update * scale);
    return DaySummary(date, newAge, newGender, newTheme, radioShow);
  }

  DaySummary operator +(DaySummary other) {
    var newAge = AgeData(
        age.bucket_0_18 + other.age.bucket_0_18,
        age.bucket_18_35 + other.age.bucket_18_35,
        age.bucket_35_50 + other.age.bucket_35_50,
        age.bucket_50_ + other.age.bucket_50_,
        age.unknown + other.age.unknown);
    var newGender = GenderData(gender.female + other.gender.female,
        gender.male + other.gender.male, gender.unknown + other.gender.unknown);
    var newTheme = ThemeData(
        theme.answer + other.theme.answer,
        theme.question + other.theme.question,
        theme.escalation + other.theme.escalation,
        theme.attitude + other.theme.attitude,
        theme.behaviour + other.theme.behaviour,
        theme.knowledge + other.theme.knowledge,
        theme.about_coronavirus + other.theme.about_coronavirus,
        theme.anxiety_panic + other.theme.anxiety_panic,
        theme.collective_hope + other.theme.collective_hope,
        theme.gratitude + other.theme.gratitude,
        theme.how_spread_transmitted + other.theme.how_spread_transmitted,
        theme.how_to_prevent + other.theme.how_to_prevent,
        theme.how_to_treat + other.theme.how_to_treat,
        theme.opinion_on_govt_policy + other.theme.opinion_on_govt_policy,
        theme.other_theme + other.theme.other_theme,
        theme.rumour_stigma_misinfo + other.theme.rumour_stigma_misinfo,
        theme.symptoms + other.theme.symptoms,
        theme.what_is_govt_policy + other.theme.what_is_govt_policy,
        theme.kenya_update + other.theme.kenya_update);
    return DaySummary(date, newAge, newGender, newTheme, radioShow);
  }

  DaySummary(this.date, this.age, this.gender, this.theme, this.radioShow);

  factory DaySummary.fromFirebaseMap(Map<String, dynamic> obj) {
    var date = DateTime.parse(obj['date']);
    var age = AgeData.fromFirebaseMap(obj['age']);
    var gender = GenderData.fromFirebaseMap(obj['gender']);
    var theme = ThemeData.fromFirebaseMap(obj['response_themes']);
    var radioShow = obj['radio_show'];

    return DaySummary(date, age, gender, theme, radioShow);
  }
}

class Message {
  String text;
  String translation;
  List<String> tags;
  DateTime received_at;

  Message(this.text, this.translation, this.tags, this.received_at);

  factory Message.fromFirebaseMap(Map<String, dynamic> obj) {
    var text = obj['text'];
    var translated_text = obj['translation'];
    var tags = List<String>();
    obj['tags'].forEach((a) => tags.add(a.toString()));
    var received_at = DateTime.parse(obj['received_at']);

    return Message(text, translated_text, tags, received_at);
  }
}

class InteractionMessage {
  int id;
  String text;
  String translated_text;
  bool is_sent;
  DateTime recorded_at;

  InteractionMessage(this.id, this.text, this.recorded_at);
}

class Option {
  String label;
  String value;
}

class InteractionOptions {
  Map<String, Option> age_buckets;
  Map<String, Option> gender;
  Map<String, Option> location_region;
  Map<String, Option> language;
  Map<String, Option> ipd_status;

  InteractionOptions(this.age_buckets, this.gender, this.location_region,
      this.language, this.ipd_status);
}

class Interaction {
  int id;
  List<InteractionMessage> messages;
  List<String> themes;
  String age_bucket;
  String gender;
  String location_region;
  String location;
  String language;
  String idp_status;
  DateTime recorded_at;

  Interaction(
      this.id,
      this.messages,
      this.themes,
      this.age_bucket,
      this.gender,
      this.location_region,
      this.location,
      this.language,
      this.idp_status,
      this.recorded_at);
}
