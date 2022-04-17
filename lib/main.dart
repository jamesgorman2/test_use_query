import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mytest/start_up_list.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
              Tab(text: 'With Hook'),
              Tab(text: 'With Query Widget'),
              Tab(text: 'With useState'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
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
// #enddocregion MyApp

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
