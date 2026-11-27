import 'package:bookia_mobile/core/notifications/firebase_push_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toPush keeps the text and the string data of a RemoteMessage', () {
    final push = FirebasePushService.toPush(
      const RemoteMessage(
        notification: RemoteNotification(
          title: 'Tu libro está listo',
          body: 'Pasa a recogerlo',
        ),
        data: {'reservation_id': 'abc', 'count': 2},
      ),
    );

    expect(push.title, 'Tu libro está listo');
    expect(push.body, 'Pasa a recogerlo');
    expect(push.data, {'reservation_id': 'abc'});
  });

  test('toPush accepts a data-only message', () {
    final push = FirebasePushService.toPush(
      const RemoteMessage(data: {'book_id': 'b1'}),
    );

    expect(push.title, isNull);
    expect(push.data, {'book_id': 'b1'});
  });
}
