import 'package:intl/intl.dart';

String chartDateLabelFormat(DateTime time) {
  return DateFormat.MMMd().format(time);
}

String messageTimeFormat(DateTime time) {
  return '${DateFormat.Hms().format(time)} ${DateFormat.MMMEd().format(time)}';
}

String NumFormat(int num) {
  return NumberFormat().format(num);
}

class MetaData {
  String color;
  String label;
  String get background => '${color}AA';

  MetaData(this.color, this.label);
}

Map<String, MetaData> metadata = {
  'a': MetaData('#ef5350', 'Filter A'),
  'b': MetaData('#00acc1', 'Filter B'),
  'male': MetaData('#FFC369', 'Male'),
  'female': MetaData('#E58B88', 'Female'),
  'unknown': MetaData('#dddddd', 'Unknown'),
  '0_18': MetaData('#3479b3', '0-18 yrs'),
  '18_35': MetaData('#8383BB', '18-35 yrs'),
  '35_50': MetaData('#cb7d8b', '35-50 yrs'),
  '50_': MetaData('#ffa2a2', '50+ yrs'),
  'all': MetaData('#000000', 'All'),
  'chasing_reply': MetaData('#000000', 'Chasing reply'),
  'call_for_right_practice': MetaData('#000000', 'Call for right practice'),
  'religious_hope_practice': MetaData('#000000', 'Religious hope or practice'),
  'statement': MetaData('#000000', 'Statement'),
  'government_responce': MetaData('#000000', 'Govt. response'),
  'about_conversation': MetaData('#000000', 'About coversation'),
  'call_for_awareness_creation':
      MetaData('#000000', 'Call for awareness creation'),
  'humanitarian_aid': MetaData('#000000', 'Humanitarian aid'),
  'denial': MetaData('#000000', 'Denial'),
  'somalia_update': MetaData('#000000', 'Somalia update'),
  'other': MetaData('#000000', 'Other'),
  'escalate': MetaData('#f57774', 'Escalate'),
  'answer': MetaData('#5cb299', 'Answer'),
  'question': MetaData('#fcc64e', 'Question'),
  'attitude': MetaData('#0078c7', 'Attitude'),
  'behaviour': MetaData('#28a5a6', 'Behaviour'),
  'knowledge': MetaData('#85c765', 'Knowledge'),
  'gratitude': MetaData('#fcd919', 'Gratitude'),
  'about_coronavirus': MetaData('#90a4ae', 'About coronavirus'),
  'anxiety_panic': MetaData('#ff6464', 'Anxiety or panic'),
  'collective_hope': MetaData('#4888f9', 'Collective hope'),
  'how_spread_transmitted': MetaData('#ffdc2e', 'How virus spread'),
  'how_to_prevent': MetaData('#8ea311', 'How to prevent'),
  'how_to_treat': MetaData('#b2d812', 'How to treat'),
  'opinion_on_govt_policy': MetaData('#318c3c', 'Opinion of govt. policy'),
  'rumour_stigma_misinfo': MetaData('#ff9827', 'Rumour, stigma, or misinfo'),
  'symptoms': MetaData('#00c2ef', 'Symptoms'),
  'what_is_govt_policy': MetaData('#805fce', 'What is govt. policy'),
  'kenya_update': MetaData('#8d6e63', 'Kenya update'),
  'other_theme': MetaData('#dddddd', 'Other themes'),
  'radio_show': MetaData('#e80000', 'Radio show')
};
