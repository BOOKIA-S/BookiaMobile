/// A push notification as the app sees it, without Firebase types.
/// [data] carries the deep link keys the API sends (`reservation_id`,
/// `book_id`).
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;
  final Map<String, String> data;
}
