import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';
import 'package:bookia_mobile/features/staff/domain/entities/staff_profile.dart';
import 'package:bookia_mobile/features/staff/domain/repositories/staff_repository.dart';
import 'package:bookia_mobile/features/staff/presentation/pages/staff_panel_page.dart';
import 'package:bookia_mobile/features/staff/presentation/providers.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/domain/repositories/store_repository.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockStaffRepository extends Mock implements StaffRepository {}

class _MockStoreRepository extends Mock implements StoreRepository {}

const _owner = StaffProfile(
  name: 'Karol',
  role: 'store_owner',
  storeId: 's1',
  mustChangePassword: false,
);

Reservation reservation(
  String id, {
  ReservationStatus status = const Pending(),
  double price = 75,
  int quantity = 1,
}) => Reservation(
  id: id,
  offerId: 'o-$id',
  price: price,
  quantity: quantity,
  status: status,
  expiresAt: DateTime.utc(2026, 11, 30),
  createdAt: DateTime.now(),
  book: ReservationBook(id: 'b-$id', title: 'Libro $id', author: 'Autor'),
);

StoreOffer offer(String id, {int stock = 6}) => StoreOffer(
  id: id,
  bookId: 'b-$id',
  title: 'Libro $id',
  author: 'Autor',
  price: 75,
  stock: stock,
  isAvailable: stock > 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockStaffRepository staff;
  late _MockStoreRepository stores;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    staff = _MockStaffRepository();
    stores = _MockStoreRepository();
    when(() => staff.getProfile()).thenAnswer((_) async => _owner);
    when(() => stores.getStore('s1')).thenAnswer(
      (_) async => StoreDetail(
        store: const Store(id: 's1', name: 'Librería Azalea', address: 'Calle'),
        offers: [offer('a'), offer('b'), offer('c', stock: 0)],
      ),
    );
  });

  void reservations(List<Reservation> list) =>
      when(() => staff.listReservations()).thenAnswer((_) async => list);

  Future<void> pump(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const StaffPanelPage()),
        GoRoute(path: '/profile', builder: (_, _) => const Text('perfil')),
        GoRoute(path: '/home', builder: (_, _) => const Text('inicio')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          staffRepositoryProvider.overrideWithValue(staff),
          storeRepositoryProvider.overrideWithValue(stores),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the store, the indicators and what is pending', (
    tester,
  ) async {
    reservations([
      reservation('r1'),
      reservation('r2'),
      reservation('r3', status: const Confirmed(), price: 100, quantity: 2),
    ]);

    await pump(tester);

    expect(find.text('Librería Azalea'), findsOneWidget);
    expect(find.text('Hola, Karol'), findsOneWidget);
    expect(find.text('Por confirmar'), findsOneWidget);
    expect(find.text('Títulos en catálogo'), findsOneWidget);
    expect(find.text('Ofertas agotadas'), findsOneWidget);
    expect(find.text('Apartado del mes'), findsOneWidget);
    expect(find.text('Por confirmar (2)'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text(r'$350.00'), findsOneWidget);
    expect(find.text('Libro r1'), findsOneWidget);
    expect(find.text('Libro r3'), findsNothing);
  });

  testWidgets('an admin sees every store and no catalog numbers', (
    tester,
  ) async {
    when(() => staff.getProfile()).thenAnswer(
      (_) async => const StaffProfile(
        name: 'Admin',
        role: 'admin',
        mustChangePassword: false,
      ),
    );
    reservations([reservation('r1')]);

    await pump(tester);

    expect(find.text('Todas las librerías'), findsOneWidget);
    expect(find.text('Títulos en catálogo'), findsNothing);
    expect(find.text('Ofertas agotadas'), findsNothing);
    expect(find.text('Por confirmar (1)'), findsOneWidget);
  });

  testWidgets('with nothing pending it says so', (tester) async {
    reservations([reservation('r1', status: const Confirmed())]);

    await pump(tester);

    expect(find.text('Por confirmar (0)'), findsOneWidget);
    expect(find.text('No hay reservas por confirmar.'), findsOneWidget);
  });

  testWidgets('Confirmar updates the list without reading it again', (
    tester,
  ) async {
    reservations([reservation('r1'), reservation('r2')]);
    when(() => staff.confirm('r1'))
        .thenAnswer((_) async => reservation('r1', status: const Confirmed()));
    await pump(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar').first);
    await tester.pumpAndSettle();

    verify(() => staff.confirm('r1')).called(1);
    verify(() => staff.listReservations()).called(1);
    expect(find.text('Por confirmar (1)'), findsOneWidget);
    expect(find.text('Libro r1'), findsNothing);
    expect(find.text('Libro r2'), findsOneWidget);
  });

  testWidgets('Rechazar asks first and then rejects', (tester) async {
    reservations([reservation('r1')]);
    when(() => staff.reject('r1'))
        .thenAnswer((_) async => reservation('r1', status: const Cancelled()));
    await pump(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Rechazar'));
    await tester.pumpAndSettle();
    expect(find.text('Rechazar reserva'), findsOneWidget);
    await tester.tap(find.text('Sí, rechazar'));
    await tester.pumpAndSettle();

    verify(() => staff.reject('r1')).called(1);
    expect(find.text('Por confirmar (0)'), findsOneWidget);
  });

  testWidgets('cancelling the question rejects nothing', (tester) async {
    reservations([reservation('r1')]);
    await pump(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Rechazar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(() => staff.reject('r1'));
    expect(find.text('Por confirmar (1)'), findsOneWidget);
  });

  testWidgets('a refusal of the API is shown and the reservation stays', (
    tester,
  ) async {
    reservations([reservation('r1')]);
    when(() => staff.confirm('r1')).thenAnswer(
      (_) => Future.error(const ConflictFailure('Esta reserva ya cambió.')),
    );
    await pump(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Esta reserva ya cambió.'), findsOneWidget);
    expect(find.text('Por confirmar (1)'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirmar'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a password change is asked for before the panel', (
    tester,
  ) async {
    when(() => staff.getProfile()).thenAnswer(
      (_) async => const StaffProfile(
        name: 'Karol',
        role: 'store_owner',
        storeId: 's1',
        mustChangePassword: true,
      ),
    );

    await pump(tester);

    expect(find.textContaining('cambiar tu contraseña'), findsOneWidget);
    verifyNever(() => staff.listReservations());
    await tester.tap(find.text('Ir a Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('perfil'), findsOneWidget);
  });

  testWidgets('an error shows its message and retries', (tester) async {
    when(() => staff.listReservations())
        .thenAnswer((_) => Future.error(const NetworkFailure()));
    await pump(tester);
    expect(find.text(const NetworkFailure().message), findsOneWidget);

    reservations([reservation('r1')]);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Por confirmar (1)'), findsOneWidget);
  });

  testWidgets('Cerrar sesión leaves the panel', (tester) async {
    reservations(const []);
    await pump(tester);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('inicio'), findsOneWidget);
  });
}
