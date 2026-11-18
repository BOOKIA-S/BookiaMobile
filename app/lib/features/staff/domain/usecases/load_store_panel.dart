import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/staff/domain/entities/store_panel.dart';
import 'package:bookia_mobile/features/staff/domain/repositories/staff_repository.dart';
import 'package:bookia_mobile/features/stores/domain/repositories/store_repository.dart';

/// Gathers what screen 16 needs: the account, its reservations and, for a
/// store owner, the catalog of its store.
class LoadStorePanel {
  const LoadStorePanel(this._staff, this._stores);

  final StaffRepository _staff;
  final StoreRepository _stores;

  Future<StorePanel> call() async {
    final profile = await _staff.getProfile();
    if (profile.mustChangePassword) throw const PasswordChangeRequiredFailure();
    final reservations = await _staff.listReservations();
    final storeId = profile.storeId;
    if (storeId == null) {
      return StorePanel(profile: profile, reservations: reservations);
    }
    final detail = await _stores.getStore(storeId);
    return StorePanel(
      profile: profile,
      reservations: reservations,
      store: detail.store,
      offers: detail.offers,
    );
  }
}
