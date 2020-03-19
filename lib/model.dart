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
  int attitude = 0;
  int behaviour = 0;
  int escalation = 0;
  int how_to_prevent = 0;
  int how_to_treat = 0;
  int knowledge = 0;
  int question = 0;
  int symptoms = 0;

  ThemeData(this.answer, this.attitude, this.behaviour, this.escalation,
      this.how_to_prevent, this.how_to_treat, this.knowledge, this.question, this.symptoms);

  factory ThemeData.fromFirebaseMap(Map<String, dynamic> obj) {
    return ThemeData(
        obj['answer'],
        obj['attitude'],
        obj['behaviour'],
        obj['escalate'],
        obj['how_to_prevent'],
        obj['how_to_treat'],
        obj['knowledge'],
        obj['question'],
        obj['symptoms']);
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
