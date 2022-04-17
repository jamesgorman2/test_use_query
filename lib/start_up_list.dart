import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mytest/startup.dart';

String getStartUps = r"""
  query GetStartUps($cursor: ID) {
    startUps(cursor: $cursor) {
      cursor
      startUps {
        id
        name
      }
    }
  }
""";

String getStartUpAdded = r"""
  subscription GetStartUpAdded {
    startUpAdded {
      id
      name
    }
  }
""";

class StartUpListWithQuery extends StatelessWidget {
  const StartUpListWithQuery({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Query<StartUpListResult>(
      options: QueryOptions(
        document: gql(getStartUps),
        parserFn: (data) => StartUpListResult.fromJson(data['startUps']),
      ),
      builder: (QueryResult<StartUpListResult> result, { Refetch<StartUpListResult>? refetch, FetchMore<StartUpListResult>? fetchMore }) {
        print('StartUpListWithQuery isLoading: ${result.isLoading} hasException: ${result.hasException}');

        if (result.hasException) {
          return Text(result.exception.toString());
        }

        if (result.isLoading) {
          return const Text('Loading');
        }

        final String? cursor = result.parsedData?.cursor;
        final startUps = result.parsedData?.startUps;

        FetchMoreOptions opts = FetchMoreOptions(
          variables: {'cursor': cursor},
          updateQuery: (previousResultData, fetchMoreResultData) {
            // this function will be called so as to combine both the original and fetchMore results
            // it allows you to combine them as you would like

            final List<dynamic> startUps = [
              ...(previousResultData?['startUps']?['startUps'] ?? <dynamic>[])
              as List<dynamic>,
              ...(fetchMoreResultData?['startUps']?['startUps'] ?? <dynamic>[])
              as List<dynamic>
            ];

            fetchMoreResultData = fetchMoreResultData ?? <String, dynamic>{};
            if (fetchMoreResultData['startUps'] == null) {
              fetchMoreResultData['startUps'] = <String, dynamic>{};
            }
            // to avoid a lot of work, lets just update the list of repos in returned
            // data with new data, this also ensures we have the endCursor already set
            // correctly
            fetchMoreResultData['startUps']['startUps'] = startUps;

            return fetchMoreResultData;
          },
        );

        final fm = (fetchMore == null) ? () => {} : () => fetchMore(opts);

        return _StartUpListView(
          startups: startUps ?? [],
          hasMore: (cursor != null),
          fetchMore: fm,
        );
      },
    );
  }
}


class StartUpListWithHook extends HookWidget {
  const StartUpListWithHook({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qhr = useQuery(QueryOptions(
      document: gql(getStartUps),
      parserFn: (data) => StartUpListResult.fromJson(data['startUps']),
    ));
    final result = qhr.result;

    print('StartUpListWithHook isLoading: ${result.isLoading} hasException: ${result.hasException}');

    if (result.hasException) {
      return Text(result.exception.toString());
    }

    if (result.isLoading) {
      return const Text('Loading');
    }

    final String? cursor = result.parsedData?.cursor;
    final startUps = result.parsedData?.startUps;

    FetchMoreOptions opts = FetchMoreOptions(
      variables: {'cursor': cursor},
      updateQuery: (previousResultData, fetchMoreResultData) {
        // this function will be called so as to combine both the original and fetchMore results
        // it allows you to combine them as you would like

        final List<dynamic> startUps = [
          ...(previousResultData?['startUps']?['startUps'] ?? <dynamic>[])
              as List<dynamic>,
          ...(fetchMoreResultData?['startUps']?['startUps'] ?? <dynamic>[])
              as List<dynamic>
        ];

        fetchMoreResultData = fetchMoreResultData ?? <String, dynamic>{};
        if (fetchMoreResultData['startUps'] == null) {
          fetchMoreResultData['startUps'] = <String, dynamic>{};
        }
        // to avoid a lot of work, lets just update the list of repos in returned
        // data with new data, this also ensures we have the endCursor already set
        // correctly
        fetchMoreResultData['startUps']['startUps'] = startUps;

        return fetchMoreResultData;
      },
    );

    return _StartUpListView(
      startups: startUps ?? [],
      hasMore: (cursor != null),
      fetchMore: () => qhr.fetchMore(opts),
    );
  }
}

class _StartUpListView extends StatelessWidget {
  _StartUpListView({
    Key? key,
    required this.startups,
    required this.hasMore,
    required this.fetchMore,
  }) : super(key: key);

  final List<StartUp> startups;
  final bool hasMore;
  final Function fetchMore;

  @override
  Widget build(BuildContext context) {
    print('_StartUpListView $hasMore ${startups.length} ${context.owner.hashCode}');

    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: hasMore ? (startups.length * 2) + 1 : (startups.length * 2) - 1,
        itemBuilder: (context, i) {
          if (i.isOdd) {
            return const Divider();
          }

          final index = i ~/ 2;
          if (index >= startups.length && hasMore) {
            // get next page
            print('Fetching more... $hasMore ${startups.length} $i $index');
            fetchMore();
            return const Text('Loading...');
          }

          return _StartUpName(startups[index].name ?? 'unk');
        });
  }
}

class _StartUpName extends StatelessWidget {
  final String _name;

  const _StartUpName(this._name, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      _name,
      style: const TextStyle(fontSize: 18),
    );
  }
}
