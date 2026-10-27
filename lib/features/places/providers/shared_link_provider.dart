import 'package:flutter_riverpod/flutter_riverpod.dart';

class SharedLinkNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setLink(String link) => state = link;
  void clear() => state = null;
}

final sharedLinkProvider = NotifierProvider<SharedLinkNotifier, String?>(
  SharedLinkNotifier.new,
);
