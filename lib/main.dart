import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mytest/start_up_list.dart';
import 'package:mytest/startup.dart';

import 'client.dart';

void main() async {
  await initHiveForFlutter();

  runApp(GraphQLProvider(client: client, child: const MyApp()));
}


class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    print('MyApp build');
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Welcome to Flutter'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Single Element With Hook'),
              Tab(text: 'Single Element Query Widget'),
              Tab(text: 'List With Hook'),
              Tab(text: 'List With Query Widget'),
              Tab(text: 'With useState'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            Center(
              child: StartUpWithHook(),
            ),
            Center(
              child: StartUpWithQuery(),
            ),
            Center(
              child: StartUpListWithHook(),
            ),
            Center(
              child: StartUpListWithQuery(),
            ),
            Center(
              child: WithUseState(),
            ),
          ],
        )
      ),
    );
  }
}


String getStartUp = r"""
  query GetStartUp($id: ID!) {
    startUp(id: $id) {
      id
      name
    }
  }
""";

class StartUpWithQuery extends StatelessWidget {
  const StartUpWithQuery({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(getStartUp),
        parserFn: (data) => StartUp.fromJson(data['startUp']),
        variables: const {
          'id': '0',
        },
      ),
      builder: (QueryResult<StartUp> result, { Refetch<StartUp>? refetch, FetchMore<StartUp>? fetchMore }) {

        print('StartUpWithQuery isLoading: ${result.isLoading} hasException: ${result.hasException}');

        if (result.hasException) {
          return Text(result.exception.toString());
        }

        if (result.isLoading) {
          return const Text('Loading');
        }

        return Text(result.parsedData?.name ?? 'unk');

      },
    );
  }
}


class StartUpWithHook extends HookWidget {
  const StartUpWithHook({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qhr = useQuery(
      QueryOptions(
        document: gql(getStartUp),
        parserFn: (data) => StartUp.fromJson(data['startUp']),
        variables: const {
          'id': '0',
        },
      )
    );
    final result = qhr.result;

    print('StartUpWithHook isLoading: ${result.isLoading} hasException: ${result.hasException}');

    if (result.hasException) {
      return Text(result.exception.toString());
    }

    if (result.isLoading) {
      return const Text('Loading');
    }

    return Text(result.parsedData?.name ?? 'unk');
  }
}


class WithUseState extends HookWidget {
  const WithUseState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    print('WithUseState counter: ${counter.value}');
    return GestureDetector(
      // automatically triggers a rebuild of the Counter widget
      onTap: () => counter.value++,
      child: Text(counter.value.toString()),
    );
  }
}
