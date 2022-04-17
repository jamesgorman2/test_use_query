import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'dart:io';

String get host {
  try {
    if (Platform.isAndroid) {
      return '10.0.2.2';
    }
  } catch(e) {
    // do nothing
  }
  return 'localhost';
}

String port = '4000';

final client = clientFor(
  uri: 'http://$host:$port/graphql',
  subscriptionUri: 'ws://$host:$port/graphql',
);

GraphQLClient getClient({
  required String uri,
  String? subscriptionUri,
}) {
  Link link = HttpLink(uri);

  if (subscriptionUri != null) {
    final WebSocketLink websocketLink = WebSocketLink(
      subscriptionUri,
      config: const SocketClientConfig(
        autoReconnect: true,
        inactivityTimeout: Duration(seconds: 30),
      ),
    );

    // link = link.concat(websocketLink);
    link = Link.split((request) => request.isSubscription, websocketLink, link);
  }

  print('Creating client to $uri & $subscriptionUri');

  return GraphQLClient(
    cache: cache,
    link: link,
  );
}

String? uuidFromObject(Object object) {
  if (object is Map<String, Object>) {
    final String? typeName = object['__typename'] as String;
    final String? id = object['id'].toString();
    if (typeName != null && id != null) {
      return <String>[typeName, id].join('/');
    }
  }
  return null;
}

final cache = GraphQLCache(store: InMemoryStore());

ValueNotifier<GraphQLClient> clientFor({
  required String uri,
  String? subscriptionUri,
}) {
  return ValueNotifier<GraphQLClient>(getClient(uri: uri, subscriptionUri: subscriptionUri));
}