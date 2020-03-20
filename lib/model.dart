import 'dart:core';

class GenderData {
  int female = 0;
  int male = 0;
  int unknown = 0;

  GenderData(this.female, this.male, this.unknown);

  factory GenderData.fromFirebaseMap(Map<String, dynamic> obj) {
    return GenderData(obj['female'], obj['male'], obj['unknown']);
  }
}

class AgeData {
  int bucket_0_18 = 0;
  int bucket_18_35 = 0;
  int bucket_35_50 = 0;
  int bucket_50_ = 0;
  int unknown = 0;

  AgeData(this.bucket_0_18, this.bucket_18_35, this.bucket_35_50,
      this.bucket_50_, this.unknown);

  factory AgeData.fromFirebaseMap(Map<String, dynamic> obj) {
    return AgeData(
        obj['0_18'], obj['18_35'], obj['35_50'], obj['50+'], obj['unknown']);
  }
}

class ThemeData {
  int answer = 0;
  int question = 0;
  int escalation = 0;

  int attitude = 0;
  int behaviour = 0;
  int knowledge = 0;

  int about_coronavirus = 0;
  int anxiety_panic = 0;
  int collective_hope = 0;
  int gratitude = 0;
  int how_spread_transmitted = 0;
  int how_to_prevent = 0;
  int how_to_treat = 0;
  int opinion_on_govt_policy = 0;
  int other_theme = 0;
  int rumour_stigma_misinfo = 0;
  int symptoms = 0;
  int what_is_govt_policy = 0;

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
      this.what_is_govt_policy);

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
    );
  }
}

class DaySummary {
  DateTime date;
  AgeData age;
  GenderData gender;
  ThemeData theme;

  DaySummary(this.date, this.age, this.gender, this.theme);

  factory DaySummary.fromFirebaseMap(Map<String, dynamic> obj) {
    var date = DateTime.parse(obj['date']);
    var age = AgeData.fromFirebaseMap(obj['age']);
    var gender = GenderData.fromFirebaseMap(obj['gender']);
    var theme = ThemeData.fromFirebaseMap(obj['response_themes']);

    return DaySummary(date, age, gender, theme);
  }
}
