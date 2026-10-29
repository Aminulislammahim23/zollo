import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/chat/data/chat_repository.dart';
import 'package:zollo/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:zollo/features/chat/presentation/screens/messages_screen.dart';

import '../../support/test_helpers.dart';

void main() {
  final routes = <RouteBase>[
    GoRoute(
      path: '/messages',
      builder: (_, _) => const MessagesScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, s) =>
              ChatRoomScreen(conversationId: s.pathParameters['id']!),
        ),
      ],
    ),
    stubRoute('/account'),
    stubRoute('/products'),
  ];

  test(
    'fake repository streams new messages and finds product chats',
    () async {
      final repo = FakeChatRepository();
      final updates = repo.watchMessages('c1').take(2).toList();
      await repo.sendMessage('c1', '  Is it in stock?  ');
      final emitted = await updates;
      expect(emitted.last.last.text, 'Is it in stock?');

      final product = sampleProduct();
      final first = await repo.conversationForProduct(product);
      final again = await repo.conversationForProduct(product);
      expect(again.id, first.id);
    },
  );

  testWidgets('messages list opens a chat and sending appends a bubble', (
    tester,
  ) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/messages');
    await tester.pump();

    expect(find.text('Gadget Hub BD'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Gadget Hub BD'));
    await tester.pumpAndSettle();
    expect(find.text('Usually replies within 1 hour'), findsOneWidget);
    expect(find.text('Hi! Does this have a warranty?'), findsOneWidget);

    final send = find.ancestor(
      of: find.byIcon(Icons.send_rounded),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(send).onPressed, isNull);

    await tester.enterText(
      find.byType(TextField),
      'Can you deliver to Sylhet?',
    );
    await tester.pump();
    await tester.tap(send);
    await tester.pump();
    await tester.pump();
    expect(find.text('Can you deliver to Sylhet?'), findsOneWidget);
  });
}
