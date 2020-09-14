import 'dart:html' as html;


const _PAGE_KEY = 'page';
String get page => _getQueryParameter(_PAGE_KEY);
set page(String value) => _updateQueryParameter(_PAGE_KEY, value);

const _ANALYSIS_TAB_KEY = 'analysis-tab';
String get analysisTab => _getQueryParameter(_ANALYSIS_TAB_KEY);
set analysisTab(String value) => _updateQueryParameter(_ANALYSIS_TAB_KEY, value);

const _COMPARE_KEY = 'compare';
bool get compare => _getQueryParameter(_COMPARE_KEY) == 'true' ? true : false;
set compare(bool value) => _updateQueryParameter(_COMPARE_KEY, value.toString());

const _NORMALISE_KEY = 'normalise';
bool get normalise => _getQueryParameter(_NORMALISE_KEY) == 'true' ? true : false;
set normalise(bool value) => _updateQueryParameter(_NORMALISE_KEY, value.toString());

const _STACK_KEY = 'stack';
bool get stack => _getQueryParameter(_STACK_KEY) == 'true' ? true : false;
set stack(bool value) => _updateQueryParameter(_STACK_KEY, value.toString());

const _FILTER_KEYS_KEY = 'filter.keys';
List<String> get filterKeys => _getQueryParameter(_FILTER_KEYS_KEY)?.split(',');
set filterKeys(List<String> value) => _updateQueryParameter(_FILTER_KEYS_KEY, value.join(','));

const _FILTER_COLLECTIONS_KEY = 'filter.collections';
List<String> get filterCollections => _getQueryParameter(_FILTER_COLLECTIONS_KEY)?.split(',');
set filterCollections(List<String> value) => _updateQueryParameter(_FILTER_COLLECTIONS_KEY, value.join(','));

const _FILTER_VALUES_KEY = 'filter.values';
List<String> get filterValues => _getQueryParameter(_FILTER_VALUES_KEY)?.split(',');
set filterValues(List<String> value) => _updateQueryParameter(_FILTER_VALUES_KEY, value?.join(','));

const _FILTER_COMPARISON_VALUES_KEY = 'filter.comparisonValues';
List<String> get filterComparisonValues => _getQueryParameter(_FILTER_COMPARISON_VALUES_KEY).split(',');
set filterComparisonValues(List<String> value) => _updateQueryParameter(_FILTER_COMPARISON_VALUES_KEY, value.join(','));


String _getQueryParameter(String key) {
  var uri = Uri.parse(html.window.location.href);
  if (uri.queryParameters.containsKey(key)) {
    return uri.queryParameters[key];
  }
  return null;
}

void _updateQueryParameter(String key, String value) {
  var uri = Uri.parse(html.window.location.href);
  var queryParameters = Map<String, String>.from(uri.queryParameters);
  if (value == null) {
    queryParameters.remove(key);
  } else {
    queryParameters[key] = value;
  }
  uri = uri.replace(queryParameters: queryParameters);
  html.window.history.pushState('', '', uri.toString());
}
