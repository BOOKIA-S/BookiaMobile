# ADR-002 · Manejo de estado e inyección de dependencias: Riverpod

- **Estado:** Aceptado
- **Fecha:** 2026-11-05
- **Autor:** Ángel de Jesús Torres Temporal
- **Relacionado con:** ADR-001, Constitución §2.2 y §4 (PAT-02, PAT-03, PAT-04, PAT-06)

## Contexto

- MVVM (ADR-001) necesita una pieza que guarde el estado de cada pantalla y avise a la vista cuando cambia.
- Varias pantallas comparten estado: la sesión (01, 10–17), la ubicación (02, 03, 08, 09) y las reservas (10, 11, 12, 16).
- Las capas necesitan recibir sus dependencias (`ApiClient`, repositorios, casos de uso) sin crearlas a mano, y poder cambiarlas por mocks en las pruebas.
- Casi todo el estado viene de la red: hay que mostrar carga, error y datos en cada pantalla (PRU-02).

## Decisión

Usar **`flutter_riverpod`** con **`riverpod_annotation` + `riverpod_generator`** para el estado y para la inyección de dependencias.

| Uso | Herramienta de Riverpod | Ejemplo |
| --- | --- | --- |
| ViewModel de una pantalla con datos remotos | `AsyncNotifier` (`@riverpod class`) | `BookDetailController` → `AsyncValue<Book>` |
| ViewModel con estado local | `Notifier` | `FiltersController` (género, precio, orden) |
| Inyección de dependencias | Provider funcional (`@riverpod`) | `bookRepositoryProvider` devuelve `BookRepositoryImpl` |
| Singletons (PAT-04) | `@Riverpod(keepAlive: true)` | `apiClientProvider`, `tokenStorageProvider`, `pushServiceProvider` |
| Observer (PAT-06) | `ref.watch`, `ref.listen`, `ProviderObserver` | La vista se redibuja; un `listen` muestra un `SnackBar` ante un `Failure` |
| Pruebas | `ProviderContainer(overrides: [...])` | Reemplazar el repositorio por un mock de `mocktail` |

Reglas:

- La vista solo lee estado (`ref.watch`) y llama métodos del controller. No contiene lógica de negocio (COD-07).
- Los controllers dependen de casos de uso o repositorios **abstractos** de `domain/`, nunca de `data/` (ARQ-02).
- La pantalla pinta los tres estados de `AsyncValue` con `when(data:, loading:, error:)`.
- Los providers de dependencias de cada feature viven en `features/<feature>/presentation/providers.dart`. Los globales viven en `core/di/providers.dart`.
- El código generado (`*.g.dart`, `*.freezed.dart`) se versiona y no cuenta para el límite de ~150 líneas por commit.

## Alternativas consideradas

| Alternativa | Por qué no |
| --- | --- |
| **`provider`** | Depende del `BuildContext` y del árbol de widgets. Es más difícil de probar fuera de la UI y no trae estado asíncrono integrado |
| **`flutter_bloc`** | Es sólido, pero exige eventos, estados y bloc por pantalla: más código para un equipo nuevo en 4 semanas. Además necesita otra librería para la DI (`get_it`) |
| **GetX** | Mezcla estado, rutas y DI en una sola librería. Es difícil de probar y no está en los paquetes aprobados |
| **`setState` y `InheritedWidget`** | No escala para estado compartido (sesión, reservas) ni da DI |

## Consecuencias

**Positivas**

- Una sola herramienta resuelve estado, DI, singletons y observer.
- `AsyncValue` obliga a manejar carga y error en cada pantalla.
- Las pruebas no necesitan widgets: `ProviderContainer` con `overrides` basta para probar controllers.
- No depende del `BuildContext`, así que los servicios (push, ubicación) leen providers sin la UI.

**Negativas y cómo se mitigan**

- Requiere `build_runner`: `dart run build_runner build --delete-conflicting-outputs` antes de compilar. Se documenta en el README y se corre en la CI.
- Es fácil olvidar `keepAlive` y perder un estado que debía vivir toda la sesión. Por eso los singletons se declaran solo en `core/di/providers.dart`.
