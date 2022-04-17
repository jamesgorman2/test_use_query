
class StartUp {
  final int id;
  final String? name;

  StartUp(this.id, this.name);
  StartUp.fromJson(Map<String, dynamic>? json):
    id = int.parse(json?['id'] ?? '-1'),
    name = json?['name'];
}

class StartUpListResult {
  final String? _cursor;
  final List<StartUp> _startUps;

  StartUpListResult(this._cursor, this._startUps);

  String? get cursor {
    return _cursor;
  }

  List<StartUp> get startUps {
    return _startUps;
  }

  static List<StartUp> dedupAndSort(List<StartUp> ss) {
    ss.retainWhere((element) => element.id != null);
    ss.sort((a, b) => a.id.compareTo(b.id));
    return ss.fold(
      <StartUp>[],
      (previousValue, element) {
        if (previousValue.isNotEmpty && previousValue.last.id == element.id) {
          return previousValue;
        }
        return [...previousValue, element];
      },
    );
  }

  static StartUpListResult fromJson(Map<String, dynamic>? json) {
    final String? cursor = json?['cursor'];
    final startUps = ((json?['startUps'] ?? <dynamic>[]) as List<dynamic>)
      .map((e) => StartUp.fromJson(e))
      .toList();

    return StartUpListResult(cursor, dedupAndSort(startUps));
  }
}