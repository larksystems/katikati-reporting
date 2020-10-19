// This generated file is used by `model.dart`
// and should not be imported or exported by any other file.

// ignore_for_file: prefer_single_quotes
// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';

import 'logger.dart';

Logger log = Logger('model.g.dart');

class Tab {
  String docId;
  String label;
  List<Filter> filters;
  List<Chart> charts;

  static Tab fromSnapshot(DocSnapshot doc, [Tab modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Tab fromData(data, [Tab modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Tab())
      ..label = String_fromData(data['label'])
      ..filters = List_fromData<Filter>(data['filters'], Filter.fromData)
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

  static void listen(DocStorage docStorage, TabCollectionListener listener, String collectionRoot, {OnErrorListener onErrorListener}) =>
      listenForUpdates<Tab>(docStorage, listener, collectionRoot, Tab.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (label != null) 'label': label,
      if (filters != null) 'filters': filters.map((elem) => elem?.toData()).toList(),
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
  String data_collection;
  String data_label;
  Field fields;
  String narrative;
  String title;
  ChartType type;
  List<String> colors;
  Geography geography;
  Timestamp timestamp;
  bool is_paired;

  static Chart fromSnapshot(DocSnapshot doc, [Chart modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Chart fromData(data, [Chart modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Chart())
      ..data_collection = String_fromData(data['data_collection'])
      ..data_label = String_fromData(data['data_label'])
      ..fields = Field.fromData(data['fields'])
      ..narrative = String_fromData(data['narrative'])
      ..title = String_fromData(data['title'])
      ..type = ChartType.fromData(data['type'])
      ..colors = List_fromData<String>(data['colors'], String_fromData)
      ..geography = Geography.fromData(data['geography'])
      ..timestamp = Timestamp.fromData(data['timestamp'])
      ..is_paired = bool_fromData(data['is_paired']);
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

  static void listen(DocStorage docStorage, ChartCollectionListener listener, String collectionRoot, {OnErrorListener onErrorListener}) =>
      listenForUpdates<Chart>(docStorage, listener, collectionRoot, Chart.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (data_collection != null) 'data_collection': data_collection,
      if (data_label != null) 'data_label': data_label,
      if (fields != null) 'fields': fields.toData(),
      if (narrative != null) 'narrative': narrative,
      if (title != null) 'title': title,
      if (type != null) 'type': type.toData(),
      if (colors != null) 'colors': colors,
      if (geography != null) 'geography': geography.toData(),
      if (timestamp != null) 'timestamp': timestamp.toData(),
      if (is_paired != null) 'is_paired': is_paired,
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
      ..aggregate = TimeAggregate.fromData(data['aggregate'])
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

  static void listen(DocStorage docStorage, TimestampCollectionListener listener, String collectionRoot, {OnErrorListener onErrorListener}) =>
      listenForUpdates<Timestamp>(docStorage, listener, collectionRoot, Timestamp.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (aggregate != null) 'aggregate': aggregate.toData(),
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
  List<String> aggregateMethod;
  String key;
  List<String> values;
  List<String> labels;
  List<String> tooltip;

  static Field fromSnapshot(DocSnapshot doc, [Field modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Field fromData(data, [Field modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Field())
      ..aggregateMethod = List_fromData<String>(data['aggregateMethod'], String_fromData)
      ..key = String_fromData(data['key'])
      ..values = List_fromData<String>(data['values'], String_fromData)
      ..labels = List_fromData<String>(data['labels'], String_fromData)
      ..tooltip = List_fromData<String>(data['tooltip'], String_fromData);
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

  static void listen(DocStorage docStorage, FieldCollectionListener listener, String collectionRoot, {OnErrorListener onErrorListener}) =>
      listenForUpdates<Field>(docStorage, listener, collectionRoot, Field.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (aggregateMethod != null) 'aggregateMethod': aggregateMethod,
      if (key != null) 'key': key,
      if (values != null) 'values': values,
      if (labels != null) 'labels': labels,
      if (tooltip != null) 'tooltip': tooltip,
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

class Filter {
  String docId;
  String key;
  String dataCollection;
  DataType type;

  static Filter fromSnapshot(DocSnapshot doc, [Filter modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Filter fromData(data, [Filter modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Filter())
      ..key = String_fromData(data['key'])
      ..dataCollection = String_fromData(data['data_collection'])
      ..type = DataType.fromData(data['type']);
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

  static void listen(DocStorage docStorage, FilterCollectionListener listener, String collectionRoot, {OnErrorListener onErrorListener}) =>
      listenForUpdates<Filter>(docStorage, listener, collectionRoot, Filter.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (key != null) 'key': key,
      if (dataCollection != null) 'data_collection': dataCollection,
      if (type != null) 'type': type.toData(),
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
      ..regionLevel = GeoRegionLevel.fromData(data['regionLevel']);
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

  static void listen(DocStorage docStorage, GeographyCollectionListener listener, String collectionRoot, {OnErrorListener onErrorListener}) =>
      listenForUpdates<Geography>(docStorage, listener, collectionRoot, Geography.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (country != null) 'country': country,
      if (regionLevel != null) 'regionLevel': regionLevel.toData(),
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

  static GeoRegionLevel fromData(data, [GeoRegionLevel defaultValue = GeoRegionLevel.state]) {
    if (data is String || data == null) return fromString(data, defaultValue);
    log.warning('invalid GeoRegionLevel: ${data.runtimeType}: $data');
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

  String toData() => 'GeoRegionLevel.$name';

  @override
  String toString() => toData();
}

class ChartType {
  static const bar = ChartType('bar');
  static const line = ChartType('line');
  static const map = ChartType('map');
  static const time_series = ChartType('time_series');
  static const summary = ChartType('summary');
  static const funnel = ChartType('funnel');

  static const values = <ChartType>[
    bar,
    line,
    map,
    time_series,
    summary,
    funnel,
  ];

  static ChartType fromString(String text, [ChartType defaultValue = ChartType.bar]) {
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

  static ChartType fromData(data, [ChartType defaultValue = ChartType.bar]) {
    if (data is String || data == null) return fromString(data, defaultValue);
    log.warning('invalid ChartType: ${data.runtimeType}: $data');
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

  String toData() => 'ChartType.$name';

  @override
  String toString() => toData();
}

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

  static TimeAggregate fromData(data, [TimeAggregate defaultValue = TimeAggregate.none]) {
    if (data is String || data == null) return fromString(data, defaultValue);
    log.warning('invalid TimeAggregate: ${data.runtimeType}: $data');
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

  String toData() => 'TimeAggregate.$name';

  @override
  String toString() => toData();
}

class DataType {
  static const string = DataType('string');
  static const datetime = DataType('datetime');

  static const values = <DataType>[
    string,
    datetime,
  ];

  static DataType fromString(String text, [DataType defaultValue = DataType.string]) {
    if (text != null) {
      const prefix = 'DataType.';
      var valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown DataType $text');
    return defaultValue;
  }

  static DataType fromData(data, [DataType defaultValue = DataType.string]) {
    if (data is String || data == null) return fromString(data, defaultValue);
    log.warning('invalid DataType: ${data.runtimeType}: $data');
    return defaultValue;
  }

  static DataType required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static DataType notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  final String name;
  const DataType(this.name);

  String toData() => 'DataType.$name';

  @override
  String toString() => toData();
}

typedef OnErrorListener = void Function(
  Object error,
  StackTrace stackTrace
);

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
    [OnErrorListener onErrorListener]
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
  }, onError: onErrorListener);
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
}

class ValueException implements Exception {
  String message;

  ValueException(this.message);

  @override
  String toString() => 'ValueException: $message';
}
