// This generated file is used by `model.dart`
// and should not be imported or exported by any other file.

import 'dart:async';

import 'logger.dart';

Logger log = Logger('model.g.dart');

class Config {
  String docId;
  Map<String, String> data_paths;
  List<Tab> tabs;

  static Config fromSnapshot(DocSnapshot doc, [Config modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Config fromData(data, [Config modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Config())
      ..data_paths = Map_fromData<String>(data['data_paths'], String_fromData)
      ..tabs = List_fromData<Tab>(data['tabs'], Tab.fromData);
  }

  static void listen(DocStorage docStorage, ConfigCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Config>(docStorage, listener, collectionRoot, Config.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (data_paths != null) 'data_paths': data_paths,
      if (tabs != null) 'tabs': tabs.map((elem) => elem?.toData()).toList(),
    };
  }

  String toString() => 'Config [$docId]: ${toData().toString()}';
}
typedef void ConfigCollectionListener(
  List<Config> added,
  List<Config> modified,
  List<Config> removed,
);

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

  static void listen(DocStorage docStorage, TabCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Tab>(docStorage, listener, collectionRoot, Tab.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (label != null) 'label': label,
      if (filters != null) 'filters': filters.map((elem) => elem?.toData()).toList(),
      if (charts != null) 'charts': charts.map((elem) => elem?.toData()).toList(),
    };
  }

  String toString() => 'Tab [$docId]: ${toData().toString()}';
}
typedef void TabCollectionListener(
  List<Tab> added,
  List<Tab> modified,
  List<Tab> removed,
);

class Chart {
  String docId;
  DataPath data_path;
  String data_label;
  String doc_name;
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
      ..data_path = DataPath.fromString(data['data_path'] as String)
      ..data_label = String_fromData(data['data_label'])
      ..doc_name = String_fromData(data['doc_name'])
      ..fields = Field.fromData(data['fields'])
      ..narrative = String_fromData(data['narrative'])
      ..title = String_fromData(data['title'])
      ..type = ChartType.fromString(data['type'] as String)
      ..colors = List_fromData<String>(data['colors'], String_fromData)
      ..geography = Geography.fromData(data['geography'])
      ..timestamp = Timestamp.fromData(data['timestamp'])
      ..is_paired = bool_fromData(data['is_paired']);
  }

  static void listen(DocStorage docStorage, ChartCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Chart>(docStorage, listener, collectionRoot, Chart.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (data_path != null) 'data_path': data_path.toString(),
      if (data_label != null) 'data_label': data_label,
      if (doc_name != null) 'doc_name': doc_name,
      if (fields != null) 'fields': fields.toData(),
      if (narrative != null) 'narrative': narrative,
      if (title != null) 'title': title,
      if (type != null) 'type': type.toString(),
      if (colors != null) 'colors': colors,
      if (geography != null) 'geography': geography.toData(),
      if (timestamp != null) 'timestamp': timestamp.toData(),
      if (is_paired != null) 'is_paired': is_paired,
    };
  }

  String toString() => 'Chart [$docId]: ${toData().toString()}';
}
typedef void ChartCollectionListener(
  List<Chart> added,
  List<Chart> modified,
  List<Chart> removed,
);

class DataPath {
  static const interactions = DataPath('interactions');
  static const message_stats = DataPath('message_stats');
  static const survey_status = DataPath('survey_status');

  static const values = <DataPath>[
    interactions,
    message_stats,
    survey_status,
  ];

  static DataPath fromString(String text, [DataPath defaultValue = DataPath.interactions]) {
    if (DataPath_fromStringOverride != null) {
      var value = DataPath_fromStringOverride(text);
      if (value != null) return value;
    }
    if (text != null) {
      const prefix = 'DataPath.';
      String valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown DataPath $text');
    return defaultValue;
  }

  final String name;
  const DataPath(this.name);
  String toString() => 'DataPath.$name';
}
DataPath Function(String text) DataPath_fromStringOverride;

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

  static void listen(DocStorage docStorage, TimestampCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Timestamp>(docStorage, listener, collectionRoot, Timestamp.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (aggregate != null) 'aggregate': aggregate.toString(),
      if (key != null) 'key': key,
    };
  }

  String toString() => 'Timestamp [$docId]: ${toData().toString()}';
}
typedef void TimestampCollectionListener(
  List<Timestamp> added,
  List<Timestamp> modified,
  List<Timestamp> removed,
);

class Field {
  String docId;
  List<String> summary;
  String key;
  List<String> values;
  List<String> labels;
  List<String> tooltip;

  static Field fromSnapshot(DocSnapshot doc, [Field modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Field fromData(data, [Field modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Field())
      ..summary = List_fromData<String>(data['summary'], String_fromData)
      ..key = String_fromData(data['key'])
      ..values = List_fromData<String>(data['values'], String_fromData)
      ..labels = List_fromData<String>(data['labels'], String_fromData)
      ..tooltip = List_fromData<String>(data['tooltip'], String_fromData);
  }

  static void listen(DocStorage docStorage, FieldCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Field>(docStorage, listener, collectionRoot, Field.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (summary != null) 'summary': summary,
      if (key != null) 'key': key,
      if (values != null) 'values': values,
      if (labels != null) 'labels': labels,
      if (tooltip != null) 'tooltip': tooltip,
    };
  }

  String toString() => 'Field [$docId]: ${toData().toString()}';
}
typedef void FieldCollectionListener(
  List<Field> added,
  List<Field> modified,
  List<Field> removed,
);

class Filter {
  String docId;
  String key;
  DataPath data_path;

  static Filter fromSnapshot(DocSnapshot doc, [Filter modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Filter fromData(data, [Filter modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Filter())
      ..key = String_fromData(data['key'])
      ..data_path = DataPath.fromString(data['data_path'] as String);
  }

  static void listen(DocStorage docStorage, FilterCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Filter>(docStorage, listener, collectionRoot, Filter.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (key != null) 'key': key,
      if (data_path != null) 'data_path': data_path.toString(),
    };
  }

  String toString() => 'Filter [$docId]: ${toData().toString()}';
}
typedef void FilterCollectionListener(
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

  static void listen(DocStorage docStorage, GeographyCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Geography>(docStorage, listener, collectionRoot, Geography.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (country != null) 'country': country,
      if (regionLevel != null) 'regionLevel': regionLevel.toString(),
    };
  }

  String toString() => 'Geography [$docId]: ${toData().toString()}';
}
typedef void GeographyCollectionListener(
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
      String valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown GeoRegionLevel $text');
    return defaultValue;
  }

  final String name;
  const GeoRegionLevel(this.name);
  String toString() => 'GeoRegionLevel.$name';
}
GeoRegionLevel Function(String text) GeoRegionLevel_fromStringOverride;

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
    if (ChartType_fromStringOverride != null) {
      var value = ChartType_fromStringOverride(text);
      if (value != null) return value;
    }
    if (text != null) {
      const prefix = 'ChartType.';
      String valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown ChartType $text');
    return defaultValue;
  }

  final String name;
  const ChartType(this.name);
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
      String valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown TimeAggregate $text');
    return defaultValue;
  }

  final String name;
  const TimeAggregate(this.name);
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

DateTime DateTime_fromData(data) {
  if (data == null) return null;
  var datetime = DateTime.tryParse(data);
  if (datetime != null) return datetime;
  log.warning('unknown DateTime value: ${data?.toString()}');
  return null;
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

String String_fromData(data) => data?.toString();

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

List<T> List_fromData<T>(dynamic data, T createModel(data)) =>
    (data as List)?.map<T>((elem) => createModel(elem))?.toList();

Map<String, T> Map_fromData<T>(dynamic data, T createModel(data)) =>
    (data as Map)?.map<String, T>((key, value) => MapEntry(key.toString(), createModel(value)));

Set<T> Set_fromData<T>(dynamic data, T createModel(data)) =>
    (data as List)?.map<T>((elem) => createModel(elem))?.toSet();

StreamSubscription<List<DocSnapshot>> listenForUpdates<T>(
    DocStorage docStorage,
    void listener(List<T> added, List<T> modified, List<T> removed),
    String collectionRoot,
    T createModel(DocSnapshot doc),
    ) {
  log.verbose('Loading from $collectionRoot');
  log.verbose('Query root: $collectionRoot');
  return docStorage.onChange(collectionRoot).listen((List<DocSnapshot> snapshots) {
    List<T> added = [];
    List<T> modified = [];
    List<T> removed = [];
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
