import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';
import 'package:bookia_mobile/features/staff/domain/entities/staff_profile.dart';
import 'package:bookia_mobile/features/staff/domain/entities/store_panel.dart';
import 'package:bookia_mobile/features/staff/domain/repositories/staff_repository.dart';
import 'package:bookia_mobile/features/staff/domain/usecases/load_store_panel.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/domain/repositories/store_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStaffRepository extends Mock implements StaffRepository {}

class _MockStoreRepository extends Mock implements StoreRepository {}

Reservation reservation(
  String id, {
  ReservationStatus status = const Pending(),
  double price = 75,
  int quantity = 1,
  DateTime? createdAt,
  ReservationBook? book,
}) => Reservation(
  id: id,
  offerId: 'o-$id',
  price: price,
  quantity: quantity,
  status: status,
  expiresAt: DateTime.utc(2026, 11, 30),
  createdAt: createdAt,
  book: book,
);

StoreOffer offer(String id, {int stock = 6, bool available = true}) =>
    StoreOffer(
      id: id,
      bookId: 'b-$id',
      title: 'Libro $id',
      author: 'Autor',
      price: 75,
      stock: stock,
      isAvailable: available,
    );

const owner = StaffProfile(
  name: 'Karol',
  role: 'store_owner',
  storeId: 's1',
  mustChangePassword: false,
);

const admin = StaffProfile(
  name: 'Admin',
  role: 'admin',
  mustChangePassword: false,
);

void main() {
  group('StorePanel', () {
    test('pending keeps only the reservations waiting for the staff', () {
      final panel = StorePanel(
        profile: owner,
        reservations: [
          reservation('a'),
          reservation('b', status: const Confirmed()),
          reservation('c', status: const Cancelled()),
          reservation('d'),
        ],
      );

      expect(panel.pending.map((r) => r.id), ['a', 'd']);
    });

    test('catalog indicators are unknown without offers', () {
      const panel = StorePanel(profile: admin, reservations: []);

      expect(panel.catalogTitles, isNull);
      expect(panel.soldOutOffers, isNull);
    });

    test('catalog indicators count titles and sold out offers', () {
      final panel = StorePanel(
        profile: owner,
        reservations: const [],
        offers: [
          offer('a'),
          offer('b', stock: 0, available: false),
          offer('c', stock: 0),
          offer('d', available: false),
        ],
      );

      expect(panel.catalogTitles, 4);
      expect(panel.soldOutOffers, 3);
    });

    test('monthAmount adds this month reservations that were not lost', () {
      final now = DateTime(2026, 11, 17);
      final panel = StorePanel(
        profile: owner,
        reservations: [
          reservation('a', quantity: 2, createdAt: DateTime(2026, 11, 3)),
          reservation(
            'b',
            price: 100,
            status: const Confirmed(),
            createdAt: DateTime(2026, 11, 10),
          ),
          reservation(
            'c',
            price: 50,
            status: const Delivered(),
            createdAt: DateTime(2026, 11, 12),
          ),
          reservation(
            'd',
            price: 999,
            status: const Cancelled(),
            createdAt: DateTime(2026, 11, 5),
          ),
          reservation(
            'e',
            price: 999,
            status: const Expired(),
            createdAt: DateTime(2026, 11, 6),
          ),
          reservation('f', price: 500, createdAt: DateTime(2026, 10, 30)),
          reservation('g', price: 777),
        ],
      );

      expect(panel.monthAmount(now), 300);
    });

    test(
      'withReservation swaps one reservation and keeps what the API omits',
      () {
        const book = ReservationBook(
          id: 'b1',
          title: 'Pedro Páramo',
          author: 'X',
        );
        final created = DateTime(2026, 11, 3);
        final panel = StorePanel(
          profile: owner,
          reservations: [
            reservation('a', book: book, createdAt: created),
            reservation('b'),
          ],
        );

        final next = panel.withReservation(
          reservation('a', status: const Confirmed()),
        );

        expect(next.reservations.map((r) => r.id), ['a', 'b']);
        expect(next.reservations.first.status, isA<Confirmed>());
        expect(next.reservations.first.book?.title, 'Pedro Páramo');
        expect(next.reservations.first.createdAt, created);
        expect(next.reservations.last.status, isA<Pending>());
        expect(next.profile, same(panel.profile));
      },
    );
  });

  group('LoadStorePanel', () {
    late _MockStaffRepository staff;
    late _MockStoreRepository stores;
    setUp(() {
      staff = _MockStaffRepository();
      stores = _MockStoreRepository();
    });

    LoadStorePanel useCase() => LoadStorePanel(staff, stores);

    test('a store owner gets its reservations and its catalog', () async {
      when(() => staff.getProfile()).thenAnswer((_) async => owner);
      when(() => staff.listReservations())
          .thenAnswer((_) async => [reservation('a')]);
      when(() => stores.getStore('s1')).thenAnswer(
        (_) async => StoreDetail(
          store: const Store(
            id: 's1',
            name: 'Librería Azalea',
            address: 'Calle',
          ),
          offers: [offer('a'), offer('b', stock: 0)],
        ),
      );

      final panel = await useCase()();

      expect(panel.store?.name, 'Librería Azalea');
      expect(panel.reservations, hasLength(1));
      expect(panel.catalogTitles, 2);
    });

    test('an admin has no store, so no catalog is read', () async {
      when(() => staff.getProfile()).thenAnswer((_) async => admin);
      when(() => staff.listReservations())
          .thenAnswer((_) async => [reservation('a')]);

      final panel = await useCase()();

      expect(panel.store, isNull);
      expect(panel.offers, isNull);
      verifyNever(() => stores.getStore('s1'));
    });

    test('a pending password change stops before the desk is read', () async {
      when(() => staff.getProfile()).thenAnswer(
        (_) async => const StaffProfile(
          name: 'Karol',
          role: 'store_owner',
          storeId: 's1',
          mustChangePassword: true,
        ),
      );

      await expectLater(
        useCase()(),
        throwsA(isA<PasswordChangeRequiredFailure>()),
      );
      verifyNever(() => staff.listReservations());
    });

    test('a Failure while reading reaches the caller', () async {
      when(() => staff.getProfile()).thenAnswer((_) async => owner);
      when(() => staff.listReservations()).thenThrow(const NetworkFailure());

      await expectLater(useCase()(), throwsA(isA<NetworkFailure>()));
    });
  });
}
