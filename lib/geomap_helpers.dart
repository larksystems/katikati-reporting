import 'package:mapbox_gl_dart/mapbox_gl_dart.dart';
import 'firebase_constants.dart' as constants;

String generateGeoMapID(String key) => 'geo-map-${key}';
String generateGeoComparisonMapID(String key) => 'geo-map-comparison-${key}';

MapboxMap generateMapboxMap(
    dynamic mapData, String id, bool comparisonEnabled) {
  Mapbox.accessToken = constants.mapboxKey;
  return MapboxMap(
    MapOptions(
      container: comparisonEnabled
          ? generateGeoComparisonMapID(id)
          : generateGeoMapID(id),
      attributionControl: false,
      style: constants.mapboxStyleURL,
      zoom: mapData['zoom'],
      center: LngLat(num.parse(mapData['center']['lng']),
          num.parse(mapData['center']['lat'])),
    ),
  );
}
