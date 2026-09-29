import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../services/message_service.dart';

final messageServiceProvider = Provider((ref) => MessageService(ApiClient()));

final coachThreadsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(messageServiceProvider).fetchThreads();
});
