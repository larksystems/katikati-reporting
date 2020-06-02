// This generated file is used by `model.dart`
// and should not be imported or exported by any other file.

import 'dart:async';

import 'logger.dart';

Logger log = Logger('model.g.dart');

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
      String valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown FieldOperator $text');
    return defaultValue;
  }

  final String name;
  const FieldOperator(this.name);
  String toString() => 'FieldOperator.$name';
}
FieldOperator Function(String text) FieldOperator_fromStringOverride;

class ChartType {
  static const bar = ChartType('bar');
  static const line = ChartType('line');
  static const map = ChartType('map');

  static const values = <ChartType>[
    bar,
    line,
    map,
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
}
typedef void FilterCollectionListener(
  List<Filter> added,
  List<Filter> modified,
  List<Filter> removed,
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

  static void listen(DocStorage docStorage, FieldOperationCollectionListener listener, String collectionRoot) =>
      listenForUpdates<FieldOperation>(docStorage, listener, collectionRoot, FieldOperation.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (key != null) 'key': key,
      if (operator != null) 'operator': operator.toString(),
      if (value != null) 'value': value,
    };
  }
}
typedef void FieldOperationCollectionListener(
  List<FieldOperation> added,
  List<FieldOperation> modified,
  List<FieldOperation> removed,
);

class Field {
  String docId;
  String label;
  String tooltip;
  FieldOperation field;

  static Field fromSnapshot(DocSnapshot doc, [Field modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Field fromData(data, [Field modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Field())
      ..label = String_fromData(data['label'])
      ..tooltip = String_fromData(data['tooltip'])
      ..field = FieldOperation.fromData(data['field']);
  }

  static void listen(DocStorage docStorage, FieldCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Field>(docStorage, listener, collectionRoot, Field.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (label != null) 'label': label,
      if (tooltip != null) 'tooltip': tooltip,
      if (field != null) 'field': field.toData(),
    };
  }
}
typedef void FieldCollectionListener(
  List<Field> added,
  List<Field> modified,
  List<Field> removed,
);

class Chart {
  String docId;
  ChartType type;
  String title;
  String narrative;
  List<Field> fields;

  static Chart fromSnapshot(DocSnapshot doc, [Chart modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Chart fromData(data, [Chart modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Chart())
      ..type = ChartType.fromString(data['type'] as String)
      ..title = String_fromData(data['title'])
      ..narrative = String_fromData(data['narrative'])
      ..fields = List_fromData<Field>(data['fields'], Field.fromData);
  }

  static void listen(DocStorage docStorage, ChartCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Chart>(docStorage, listener, collectionRoot, Chart.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (type != null) 'type': type.toString(),
      if (title != null) 'title': title,
      if (narrative != null) 'narrative': narrative,
      if (fields != null) 'fields': fields.map((elem) => elem?.toData()).toList(),
    };
  }
}
typedef void ChartCollectionListener(
  List<Chart> added,
  List<Chart> modified,
  List<Chart> removed,
);

class Tab {
  String docId;
  String id;
  String label;
  List<String> exclude_filters;
  List<Chart> charts;

  static Tab fromSnapshot(DocSnapshot doc, [Tab modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Tab fromData(data, [Tab modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Tab())
      ..id = String_fromData(data['id'])
      ..label = String_fromData(data['label'])
      ..exclude_filters = List_fromData<String>(data['exclude_filters'], String_fromData)
      ..charts = List_fromData<Chart>(data['charts'], Chart.fromData);
  }

  static void listen(DocStorage docStorage, TabCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Tab>(docStorage, listener, collectionRoot, Tab.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (exclude_filters != null) 'exclude_filters': exclude_filters,
      if (charts != null) 'charts': charts.map((elem) => elem?.toData()).toList(),
    };
  }
}
typedef void TabCollectionListener(
  List<Tab> added,
  List<Tab> modified,
  List<Tab> removed,
);

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

  static void listen(DocStorage docStorage, ConfigCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Config>(docStorage, listener, collectionRoot, Config.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (data_paths != null) 'data_paths': data_paths,
      if (filters != null) 'filters': filters.map((elem) => elem?.toData()).toList(),
      if (tabs != null) 'tabs': tabs.map((elem) => elem?.toData()).toList(),
    };
  }
}
typedef void ConfigCollectionListener(
  List<Config> added,
  List<Config> modified,
  List<Config> removed,
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
