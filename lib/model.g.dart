// This generated file is used by `model.dart`
// and should not be imported or exported by any other file.

import 'dart:async';

import 'logger.dart';

Logger log = Logger('model.g.dart');

class Config {
  String docId;
  Map<String, String> data_paths;
  List<Filter> filters;
  List<Tab> tabs;

  static Config fromSnapshot(DocSnapshot doc, [Config modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Config fromData(data, [Config modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Config())
      ..data_paths = Map_fromData<String>(data['data_paths'], String_fromData)
      ..filters = List_fromData<Filter>(data['filters'], Filter.fromData)
      ..tabs = List_fromData<Tab>(data['tabs'], Tab.fromData);
  }

  static Config required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static Config notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static void listen(DocStorage docStorage, ConfigCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Config>(docStorage, listener, collectionRoot, Config.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (data_paths != null) 'data_paths': data_paths,
      if (filters != null) 'filters': filters.map((elem) => elem?.toData()).toList(),
      if (tabs != null) 'tabs': tabs.map((elem) => elem?.toData()).toList(),
    };
  }

  @override
  String toString() => 'Config [$docId]: ${toData().toString()}';
}
typedef ConfigCollectionListener = void Function(
  List<Config> added,
  List<Config> modified,
  List<Config> removed,
);

class Tab {
  String docId;
  String label;
  List<String> exclude_filters;
  List<Chart> charts;

  static Tab fromSnapshot(DocSnapshot doc, [Tab modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Tab fromData(data, [Tab modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Tab())
      ..label = String_fromData(data['label'])
      ..exclude_filters = List_fromData<String>(data['exclude_filters'], String_fromData)
      ..charts = List_fromData<Chart>(data['charts'], Chart.fromData);
  }

  static Tab required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static Tab notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static void listen(DocStorage docStorage, TabCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Tab>(docStorage, listener, collectionRoot, Tab.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (label != null) 'label': label,
      if (exclude_filters != null) 'exclude_filters': exclude_filters,
      if (charts != null) 'charts': charts.map((elem) => elem?.toData()).toList(),
    };
  }

  @override
  String toString() => 'Tab [$docId]: ${toData().toString()}';
}
typedef TabCollectionListener = void Function(
  List<Tab> added,
  List<Tab> modified,
  List<Tab> removed,
);

class Chart {
  String docId;
  ChartType type;
  Timestamp timestamp;
  String title;
  String narrative;
  List<Field> fields;
  List<String> colors;
  Geography geography;

  static Chart fromSnapshot(DocSnapshot doc, [Chart modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Chart fromData(data, [Chart modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Chart())
      ..type = ChartType.fromString(data['type'] as String)
      ..timestamp = Timestamp.fromData(data['timestamp'])
      ..title = String_fromData(data['title'])
      ..narrative = String_fromData(data['narrative'])
      ..fields = List_fromData<Field>(data['fields'], Field.fromData)
      ..colors = List_fromData<String>(data['colors'], String_fromData)
      ..geography = Geography.fromData(data['geography']);
  }

  static Chart required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static Chart notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static void listen(DocStorage docStorage, ChartCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Chart>(docStorage, listener, collectionRoot, Chart.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (type != null) 'type': type.toString(),
      if (timestamp != null) 'timestamp': timestamp.toData(),
      if (title != null) 'title': title,
      if (narrative != null) 'narrative': narrative,
      if (fields != null) 'fields': fields.map((elem) => elem?.toData()).toList(),
      if (colors != null) 'colors': colors,
      if (geography != null) 'geography': geography.toData(),
    };
  }

  @override
  String toString() => 'Chart [$docId]: ${toData().toString()}';
}
typedef ChartCollectionListener = void Function(
  List<Chart> added,
  List<Chart> modified,
  List<Chart> removed,
);

class Timestamp {
  String docId;
  TimeAggregate aggregate;
  String key;

  static Timestamp fromSnapshot(DocSnapshot doc, [Timestamp modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Timestamp fromData(data, [Timestamp modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Timestamp())
      ..aggregate = TimeAggregate.fromString(data['aggregate'] as String)
      ..key = String_fromData(data['key']);
  }

  static Timestamp required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static Timestamp notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static void listen(DocStorage docStorage, TimestampCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Timestamp>(docStorage, listener, collectionRoot, Timestamp.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (aggregate != null) 'aggregate': aggregate.toString(),
      if (key != null) 'key': key,
    };
  }

  @override
  String toString() => 'Timestamp [$docId]: ${toData().toString()}';
}
typedef TimestampCollectionListener = void Function(
  List<Timestamp> added,
  List<Timestamp> modified,
  List<Timestamp> removed,
);

class Field {
  String docId;
  String label;
  String tooltip;
  List<num> bucket;
  Map<String, num> time_bucket;
  FieldOperation field;

  static Field fromSnapshot(DocSnapshot doc, [Field modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Field fromData(data, [Field modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Field())
      ..label = String_fromData(data['label'])
      ..tooltip = String_fromData(data['tooltip'])
      ..bucket = List_fromData<num>(data['bucket'], num_fromData)
      ..time_bucket = Map_fromData<num>(data['time_bucket'], num_fromData)
      ..field = FieldOperation.fromData(data['field']);
  }

  static Field required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static Field notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static void listen(DocStorage docStorage, FieldCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Field>(docStorage, listener, collectionRoot, Field.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (label != null) 'label': label,
      if (tooltip != null) 'tooltip': tooltip,
      if (bucket != null) 'bucket': bucket,
      if (time_bucket != null) 'time_bucket': time_bucket,
      if (field != null) 'field': field.toData(),
    };
  }

  @override
  String toString() => 'Field [$docId]: ${toData().toString()}';
}
typedef FieldCollectionListener = void Function(
  List<Field> added,
  List<Field> modified,
  List<Field> removed,
);

class FieldOperation {
  String docId;
  String key;
  FieldOperator operator;
  dynamic value;

  static FieldOperation fromSnapshot(DocSnapshot doc, [FieldOperation modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static FieldOperation fromData(data, [FieldOperation modelObj]) {
    if (data == null) return null;
    return (modelObj ?? FieldOperation())
      ..key = String_fromData(data['key'])
      ..operator = FieldOperator.fromString(data['operator'] as String)
      ..value = data['value'];
  }

  static FieldOperation required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static FieldOperation notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static void listen(DocStorage docStorage, FieldOperationCollectionListener listener, String collectionRoot) =>
      listenForUpdates<FieldOperation>(docStorage, listener, collectionRoot, FieldOperation.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (key != null) 'key': key,
      if (operator != null) 'operator': operator.toString(),
      if (value != null) 'value': value,
    };
  }

  @override
  String toString() => 'FieldOperation [$docId]: ${toData().toString()}';
}
typedef FieldOperationCollectionListener = void Function(
  List<FieldOperation> added,
  List<FieldOperation> modified,
  List<FieldOperation> removed,
);

class Filter {
  String docId;
  String key;
  String label;
  String tooltip;
  List<dynamic> exclude_values;

  static Filter fromSnapshot(DocSnapshot doc, [Filter modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Filter fromData(data, [Filter modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Filter())
      ..key = String_fromData(data['key'])
      ..label = String_fromData(data['label'])
      ..tooltip = String_fromData(data['tooltip'])
      ..exclude_values = List_fromData<dynamic>(data['exclude_values'], null);
  }

  static Filter required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static Filter notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static void listen(DocStorage docStorage, FilterCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Filter>(docStorage, listener, collectionRoot, Filter.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (key != null) 'key': key,
      if (label != null) 'label': label,
      if (tooltip != null) 'tooltip': tooltip,
      if (exclude_values != null) 'exclude_values': exclude_values,
    };
  }

  @override
  String toString() => 'Filter [$docId]: ${toData().toString()}';
}
typedef FilterCollectionListener = void Function(
  List<Filter> added,
  List<Filter> modified,
  List<Filter> removed,
);

class Geography {
  String docId;
  String country;
  GeoRegionLevel regionLevel;

  static Geography fromSnapshot(DocSnapshot doc, [Geography modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Geography fromData(data, [Geography modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Geography())
      ..country = String_fromData(data['country'])
      ..regionLevel = GeoRegionLevel.fromString(data['regionLevel'] as String);
  }

  static Geography required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static Geography notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static void listen(DocStorage docStorage, GeographyCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Geography>(docStorage, listener, collectionRoot, Geography.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (country != null) 'country': country,
      if (regionLevel != null) 'regionLevel': regionLevel.toString(),
    };
  }

  @override
  String toString() => 'Geography [$docId]: ${toData().toString()}';
}
typedef GeographyCollectionListener = void Function(
  List<Geography> added,
  List<Geography> modified,
  List<Geography> removed,
);

class GeoRegionLevel {
  static const city = GeoRegionLevel('city');
  static const state = GeoRegionLevel('state');
  static const country = GeoRegionLevel('country');

  static const values = <GeoRegionLevel>[
    city,
    state,
    country,
  ];

  static GeoRegionLevel fromString(String text, [GeoRegionLevel defaultValue = GeoRegionLevel.state]) {
    if (GeoRegionLevel_fromStringOverride != null) {
      var value = GeoRegionLevel_fromStringOverride(text);
      if (value != null) return value;
    }
    if (text != null) {
      const prefix = 'GeoRegionLevel.';
      var valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown GeoRegionLevel $text');
    return defaultValue;
  }

  static GeoRegionLevel required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static GeoRegionLevel notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  final String name;
  const GeoRegionLevel(this.name);

  @override
  String toString() => 'GeoRegionLevel.$name';
}
GeoRegionLevel Function(String text) GeoRegionLevel_fromStringOverride;

class FieldOperator {
  static const equals = FieldOperator('equals');
  static const contains = FieldOperator('contains');
  static const not_contains = FieldOperator('not_contains');

  static const values = <FieldOperator>[
    equals,
    contains,
    not_contains,
  ];

  static FieldOperator fromString(String text, [FieldOperator defaultValue = FieldOperator.equals]) {
    if (FieldOperator_fromStringOverride != null) {
      var value = FieldOperator_fromStringOverride(text);
      if (value != null) return value;
    }
    if (text != null) {
      const prefix = 'FieldOperator.';
      var valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown FieldOperator $text');
    return defaultValue;
  }

  static FieldOperator required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static FieldOperator notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  final String name;
  const FieldOperator(this.name);

  @override
  String toString() => 'FieldOperator.$name';
}
FieldOperator Function(String text) FieldOperator_fromStringOverride;

class ChartType {
  static const bar = ChartType('bar');
  static const line = ChartType('line');
  static const map = ChartType('map');
  static const time_series = ChartType('time_series');

  static const values = <ChartType>[
    bar,
    line,
    map,
    time_series,
  ];

  static ChartType fromString(String text, [ChartType defaultValue = ChartType.bar]) {
    if (ChartType_fromStringOverride != null) {
      var value = ChartType_fromStringOverride(text);
      if (value != null) return value;
    }
    if (text != null) {
      const prefix = 'ChartType.';
      var valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown ChartType $text');
    return defaultValue;
  }

  static ChartType required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static ChartType notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  final String name;
  const ChartType(this.name);

  @override
  String toString() => 'ChartType.$name';
}
ChartType Function(String text) ChartType_fromStringOverride;

class TimeAggregate {
  static const day = TimeAggregate('day');
  static const hour = TimeAggregate('hour');
  static const none = TimeAggregate('none');

  static const values = <TimeAggregate>[
    day,
    hour,
    none,
  ];

  static TimeAggregate fromString(String text, [TimeAggregate defaultValue = TimeAggregate.none]) {
    if (TimeAggregate_fromStringOverride != null) {
      var value = TimeAggregate_fromStringOverride(text);
      if (value != null) return value;
    }
    if (text != null) {
      const prefix = 'TimeAggregate.';
      var valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown TimeAggregate $text');
    return defaultValue;
  }

  static TimeAggregate required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static TimeAggregate notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  final String name;
  const TimeAggregate(this.name);

  @override
  String toString() => 'TimeAggregate.$name';
}
TimeAggregate Function(String text) TimeAggregate_fromStringOverride;

// ======================================================================
// Core firebase/yaml utilities

bool bool_fromData(data) {
  if (data == null) return null;
  if (data is bool) return data;
  if (data is String) {
    var boolStr = data.toLowerCase();
    if (boolStr == 'true') return true;
    if (boolStr == 'false') return false;
  }
  log.warning('unknown bool value: ${data?.toString()}');
  return null;
}

bool bool_required(Map data, String fieldName, String className) {
  var value = bool_fromData(data[fieldName]);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

bool bool_notNull(Map data, String fieldName, String className) {
  var value = bool_required(data, fieldName, className);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

DateTime DateTime_fromData(data) {
  if (data == null) return null;
  var datetime = DateTime.tryParse(data);
  if (datetime != null) return datetime;
  log.warning('unknown DateTime value: ${data?.toString()}');
  return null;
}

DateTime DateTime_required(Map data, String fieldName, String className) {
  var value = DateTime_fromData(data[fieldName]);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

DateTime DateTime_notNull(Map data, String fieldName, String className) {
  var value = DateTime_required(data, fieldName, className);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

dynamic dynamic_fromData(data) => data;

dynamic dynamic_required(Map data, String fieldName, String className) {
  var value = data[fieldName];
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

dynamic dynamic_notNull(Map data, String fieldName, String className) {
  var value = dynamic_required(data, fieldName, className);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

int int_fromData(data) {
  if (data == null) return null;
  if (data is int) return data;
  if (data is String) {
    var result = int.tryParse(data);
    if (result is int) return result;
  }
  log.warning('unknown int value: ${data?.toString()}');
  return null;
}

int int_required(Map data, String fieldName, String className) {
  var value = int_fromData(data[fieldName]);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

int int_notNull(Map data, String fieldName, String className) {
  var value = int_required(data, fieldName, className);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

String String_fromData(data) => data?.toString();

String String_required(Map data, String fieldName, String className) {
  var value = String_fromData(data[fieldName]);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

String String_notNull(Map data, String fieldName, String className) {
  var value = String_required(data, fieldName, className);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

String String_notEmpty(Map data, String fieldName, String className) {
  var value = String_notNull(data, fieldName, className);
  if (value.isEmpty)
    throw ValueException("$className.$fieldName must not be empty");
  return value;
}

num num_fromData(data) {
  if (data == null) return null;
  if (data is num) return data;
  if (data is String) {
    var result = num.tryParse(data);
    if (result is num) return result;
  }
  log.warning('unknown num value: ${data?.toString()}');
  return null;
}

num num_required(Map data, String fieldName, String className) {
  var value = num_fromData(data[fieldName]);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

num num_notNull(Map data, String fieldName, String className) {
  var value = num_required(data, fieldName, className);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

List<T> List_fromData<T>(dynamic data, T Function(dynamic) createModel) =>
    (data as List)?.map<T>((elem) => createModel(elem))?.toList();

List<T> List_required<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = List_fromData(data[fieldName], createModel);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

List<T> List_notNull<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = List_required(data, fieldName, className, createModel);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

List<T> List_notEmpty<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = List_notNull(data, fieldName, className, createModel);
  if (value.isEmpty)
    throw ValueException("$className.$fieldName must not be empty");
  return value;
}

Map<String, T> Map_fromData<T>(dynamic data, T Function(dynamic) createModel) =>
    (data as Map)?.map<String, T>((key, value) => MapEntry(key.toString(), createModel(value)));

Map<String, T> Map_required<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = Map_fromData(data[fieldName], createModel);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

Map<String, T> Map_notNull<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = Map_required(data, fieldName, className, createModel);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

Map<String, T> Map_notEmpty<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = Map_notNull(data, fieldName, className, createModel);
  if (value.isEmpty)
    throw ValueException("$className.$fieldName must not be empty");
  return value;
}

Set<T> Set_fromData<T>(dynamic data, T Function(dynamic) createModel) =>
    (data as List)?.map<T>((elem) => createModel(elem))?.toSet();

Set<T> Set_required<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = Set_fromData(data[fieldName], createModel);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

Set<T> Set_notNull<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = Set_required(data, fieldName, className, createModel);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

Set<T> Set_notEmpty<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = Set_notNull(data, fieldName, className, createModel);
  if (value.isEmpty)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

StreamSubscription<List<DocSnapshot>> listenForUpdates<T>(
    DocStorage docStorage,
    void Function(List<T> added, List<T> modified, List<T> removed) listener,
    String collectionRoot,
    T Function(DocSnapshot doc) createModel,
    ) {
  log.verbose('Loading from $collectionRoot');
  log.verbose('Query root: $collectionRoot');
  return docStorage.onChange(collectionRoot).listen((List<DocSnapshot> snapshots) {
    var added = <T>[];
    var modified = <T>[];
    var removed = <T>[];
    log.verbose("Starting processing ${snapshots.length} changes.");
    for (var snapshot in snapshots) {
      log.verbose('Processing ${snapshot.id}');
      switch (snapshot.changeType) {
        case DocChangeType.added:
          added.add(createModel(snapshot));
          break;
        case DocChangeType.modified:
          modified.add(createModel(snapshot));
          break;
        case DocChangeType.removed:
          removed.add(createModel(snapshot));
          break;
      }
    }
    listener(added, modified, removed);
  });
}

/// Document storage interface.
/// See [FirebaseDocStorage] for a firebase specific version of this.
abstract class DocStorage {
  /// Return a stream of document snapshots
  Stream<List<DocSnapshot>> onChange(String collectionRoot);

  /// Return a object for batching document updates.
  /// Call [DocBatchUpdate.commit] after the changes have been made.
  DocBatchUpdate batch();
}

enum DocChangeType {
  added,
  modified,
  removed
}

/// A snapshot of a document's id and data at a particular moment in time.
class DocSnapshot {
  final String id;
  final Map<String, dynamic> data;
  final DocChangeType changeType;

  DocSnapshot(this.id, this.data, this.changeType);
}

/// A batch update, used to perform multiple writes as a single atomic unit.
/// None of the writes are committed (or visible locally) until
/// [DocBatchUpdate.commit()] is called.
abstract class DocBatchUpdate {
  /// Commits all of the writes in this write batch as a single atomic unit.
  /// Returns non-null [Future] that resolves once all of the writes in the
  /// batch have been successfully written to the backend as an atomic unit.
  /// Note that it won't resolve while you're offline.
  Future<Null> commit();

  /// Updates fields in the document referred to by this [DocumentReference].
  /// The update will fail if applied to a document that does not exist.
  void update(String documentPath, {Map<String, dynamic> data});
}

// ======================================================================
// Core pub/sub utilities

/// A pub/sub based mechanism for updating documents
abstract class DocPubSubUpdate {
  /// Publish the given opinion for the given namespace.
  Future<void> publishAddOpinion(String namespace, Map<String, dynamic> opinion);

  /// Publish the given document list/set additions,
  /// where [additions] is a mapping of field name to new values to be added to the list/set.
  /// Callers should catch and handle IOException.
  Future<void> publishDocAdd(String collectionName, List<String> docIds, Map<String, List<dynamic>> additions);

  /// Publish the given document changes,
  /// where [changes] is a mapping of field name to new value.
  /// Callers should catch and handle IOException.
  Future<void> publishDocChange(String collectionName, List<String> docIds, Map<String, dynamic> changes);

  /// Publish the given document list/set removals,
  /// where [removals] is a mapping of field name to old values to be removed from the list/set.
  /// Callers should catch and handle IOException.
  Future<void> publishDocRemove(String collectionName, List<String> docIds, Map<String, List<dynamic>> removals);
}

class ValueException implements Exception {
  String message;

  ValueException(this.message);

  @override
  String toString() => 'ValueException: $message';
}
