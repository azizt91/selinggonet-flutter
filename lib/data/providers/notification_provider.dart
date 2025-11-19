import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/notification_repository.dart';
import '../models/notification_model.dart';
import 'supabase_provider.dart';

// Repository Provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(supabaseClientProvider));
});

// Notifications Provider
final notificationsProvider = FutureProvider.autoDispose.family<List<NotificationModel>, String>(
  (ref, userId) async {
    final repository = ref.watch(notificationRepositoryProvider);
    return repository.getUserNotifications(userId);
  },
);

// Unread Count Provider
final unreadNotificationCountProvider = FutureProvider.autoDispose.family<int, String>(
  (ref, userId) async {
    final repository = ref.watch(notificationRepositoryProvider);
    return repository.getUnreadNotificationCount(userId);
  },
);

// Notification Controller
class NotificationController extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repository;

  NotificationController(this._repository) : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAsRead(notificationId, userId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> markAllAsRead(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAllAsRead(userId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteNotification(notificationId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> clearAllNotifications(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.clearAllNotifications(userId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
  return NotificationController(ref.read(notificationRepositoryProvider));
});
