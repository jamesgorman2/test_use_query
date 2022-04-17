import { gql } from 'apollo-server';

import express from "express";
import { ApolloServer } from 'apollo-server-express';
import { createServer } from 'http';
import { ApolloServerPluginDrainHttpServer } from "apollo-server-core";
import { makeExecutableSchema } from '@graphql-tools/schema';
import { WebSocketServer } from 'ws';
import { useServer } from 'graphql-ws/lib/use/ws';

import { StartUpGenerator, StartUps} from './StartUps.js';
import {PluginDefinition} from "apollo-server-core/dist/types";
import { PubSub } from 'graphql-subscriptions';

const typeDefs = gql`
    type StartUp {
        id: ID!
        name: String!
    }

    type StartUpFeed {
        cursor: ID
        startUps: [StartUp!]!
    }

    type Query {
        startUp(id: ID!): StartUp
        startUps(cursor: ID, limit: Int): StartUpFeed!
        suggest: String!
    }
    type Mutation {
        addStartUp(name: String!): StartUp
    }
    type Subscription {
        startUpAdded: StartUp
    }
`;

const startUps = new StartUps();


// seed names
const SEED_COUNT = 15;
for (let i = 0; i < SEED_COUNT; ++i) {
  startUps.addNew(`Startup ${i}`);
}

const startUpGenerator = new StartUpGenerator();

const pubsub = new PubSub();
const resolvers = {
  Query: {
    startUp(parent: any, args: { id: string }) {
      return startUps.get(args.id);
    },
    startUps(parent: any, args: { cursor: string, limit: number }) {
      return startUps.getAll(args.cursor, args.limit || 10);
    },
    suggest() {
      return startUpGenerator.suggest();
    }
  },
  Mutation: {
    addStartUp(parent: any, args: { name: string }) {
      const startUp = startUps.addNew(args.name);
      pubsub.publish(
        'STARTUP_ADDED',
        {
          startUpAdded: startUp,
        },
      );
      return startUp;
    }
  },
  Subscription: {
    startUpAdded: {
      subscribe: () => pubsub.asyncIterator(['STARTUP_ADDED']),
    },
  },
}

const loggingPlugin: PluginDefinition = {
  // Fires whenever a GraphQL request is received from a client.
  async requestDidStart(requestContext) {
    console.log(`Request started! Query: ${requestContext.request.query}`);

    return {
      // Fires whenever Apollo Server will parse a GraphQL
      // request to create its associated document AST.
      async parsingDidStart() {
        // console.log('Parsing started!');
      },

      // Fires whenever Apollo Server will validate a
      // request's document AST against your GraphQL schema.
      async validationDidStart() {
        // console.log('Validation started!');
      },

    }
  },
};

const schema = makeExecutableSchema({ typeDefs, resolvers });

const app = express();
const httpServer = createServer(app);

const wsServer = new WebSocketServer({
  // This is the `httpServer` we created in a previous step.
  server: httpServer,
  // Pass a different path here if your ApolloServer serves at
  // a different path.
  path: '/graphql',
});
wsServer.on(
  "listening",
  () => console.log('ws listening')
);
wsServer.on(
  "headers",
  headers => console.log('ws headers', headers)
);
wsServer.on("close", () => 'ws closed');
wsServer.on(
  'connection',
  ws => {
    ws.on('message', msg => console.log(`ws message ${msg}`))
  }
);

// Hand in the schema we just created and have the
// WebSocketServer start listening.
const serverCleanup = useServer({ schema }, wsServer);

const server = new ApolloServer(
  {
    schema,
    plugins: [
      // Proper shutdown for the HTTP server.
      ApolloServerPluginDrainHttpServer({ httpServer }),
      // Proper shutdown for the WebSocket server.
      {
        async serverWillStart() {
          return {
            async drainServer() {
              await serverCleanup.dispose();
            },
          };
        },
      },
      loggingPlugin,
    ],
  }
);


await server.start();
server.applyMiddleware({ app });

const PORT = 4000;
// Now that our HTTP server is fully set up, we can listen to it.
httpServer.listen(PORT, () => {
  console.log(
    `Server is now running on http://localhost:${PORT}${server.graphqlPath}`,
  );
});