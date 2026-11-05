# ADR-001 · Arquitectura de la app: Clean Architecture feature-first + MVVM

- **Estado:** Aceptado
- **Fecha:** 2026-11-05
- **Autor:** Ángel de Jesús Torres Temporal
- **Relacionado con:** Constitución §3 (ARQ-01 a ARQ-06) y §4 (PAT-01 a PAT-12), ADR-002

## Contexto

- La app la programan 5 integrantes en paralelo durante 4 semanas, con un PR por commit. Si dos personas tocan las mismas carpetas, aparecen conflictos que solo Jaime puede resolver.
- El docente evalúa la arquitectura y los patrones, así que cada decisión debe poder verificarse en el código.
- Las reglas de negocio (reservas, stock, roles, auditoría) ya viven en la API de BOOKIA. La app no debe duplicarlas.
- Se pide al menos 70 % de cobertura en `domain/` y `data/`, así que la lógica tiene que poder probarse sin Flutter ni red.

## Decisión

Usar **Clean Architecture por capas, organizada por feature**, con **MVVM** en la capa de presentación.

```
presentation ──► domain ◄── data
```

| Capa | Contenido | Puede importar |
| --- | --- | --- |
| `domain/` | Entidades (freezed), interfaces de repositorio, casos de uso | Solo Dart puro y otras clases de `domain/` |
| `data/` | DTO (`fromJson`), datasources remotos y locales, mappers, `*_repository_impl.dart` | `domain/`, `core/`, Dio, Hive |
| `presentation/` | Pages (View), widgets, controllers (ViewModel = Notifier de Riverpod) | `domain/` y `core/` vía providers |

Carpetas: `app/lib/features/<feature>/{data,domain,presentation}`. Lo compartido va en `app/lib/core/` (red, almacenamiento, ubicación, notificaciones, errores, widgets y utilidades).

Reglas que se derivan de esta decisión:

- `domain/` no importa `package:flutter`, `dio`, `hive_ce` ni nada de `data/` o `presentation/` (ARQ-01). Lo verifica `test/architecture_test.dart`.
- La vista nunca llama a Dio ni a un datasource (ARQ-02).
- Una feature no importa archivos internos de otra feature (ARQ-04).
- Los errores cruzan capas como `Failure` sealed, nunca como `DioException` (ARQ-05).
- Ningún archivo pasa de 300 líneas (ARQ-06).

## Patrones y dónde viven

| ID | Patrón | Ubicación |
| --- | --- | --- |
| PAT-01 | Repository | `features/*/domain/repositories/*_repository.dart` + `features/*/data/repositories/*_repository_impl.dart` |
| PAT-02 | MVVM | `features/*/presentation/controllers/*_controller.dart` + `pages/` |
| PAT-03 | Provider / DI | `core/di/providers.dart` y providers de cada feature (ver ADR-002) |
| PAT-04 | Singleton | `ApiClient`, `TokenStorage`, `PushService` con providers `keepAlive` |
| PAT-05 | Factory | `BookDto.fromJson(...)` en `data/dto/`; `FailureFactory.fromDioException()` en `core/error/` |
| PAT-06 | Observer | `ref.watch`/`ref.listen`; stream de FCM en `PushService`; `ProviderObserver` en debug |
| PAT-07 | Adapter (Mapper) | `features/*/data/mappers/*_mapper.dart` (DTO → entidad); `TypeAdapter` de Hive |
| PAT-08 | Chain of Responsibility | `core/network/interceptors/`: `AuthInterceptor` → `LoggingInterceptor` → `ErrorInterceptor` |
| PAT-09 | Strategy | `features/search/domain/sort/`: `SortByPrice`, `SortByDistance`, `SortByTitle` |
| PAT-10 | State | `features/reservations/domain/entities/reservation_status.dart` (sealed: `Pending`, `Confirmed`, `Delivered`, `Cancelled`, `Expired`) |
| PAT-11 | Facade | `core/location/location_service.dart`, `core/notifications/push_service.dart` |
| PAT-12 | Middleware (Chain) | En la API: `bookia/api/middlewares/` (`requireAuth`, `requireRole`). Se hereda; la app no lo implementa |

## Alternativas consideradas

| Alternativa | Por qué no |
| --- | --- |
| **Por capas globales** (`lib/data`, `lib/domain`, `lib/presentation`) | Todos editarían las mismas carpetas y habría más conflictos de merge. Tampoco deja claro quién es dueño de cada pantalla |
| **Sin capas** (widgets que llaman a Dio) | Más rápido al inicio, pero no se puede probar sin red, no cumple la meta de 70 % y no permite mostrar los patrones |
| **MVC o GetX** | GetX mezcla navegación, estado y DI en una sola librería con mucha "magia". Es difícil de probar y no está en los paquetes aprobados |

## Consecuencias

**Positivas**

- Cada integrante trabaja en su carpeta `features/<feature>/`, con pocos conflictos. CODEOWNERS asigna revisor por carpeta.
- `domain/` y `data/` se prueban con pruebas unitarias puras y mocks (`mocktail`).
- Cada patrón tiene una ruta fija que el docente puede revisar.
- La app es "un cliente más" de la API: un arreglo en la API beneficia a la web y al móvil.

**Negativas y cómo se mitigan**

- Más archivos por pantalla (entidad, DTO, mapper, repositorio, caso de uso, controller y page). Se mitiga con plantillas en el README y con `freezed`/`json_serializable` para el código repetitivo.
- Curva de aprendizaje para un equipo nuevo en Flutter. Se mitiga con este ADR, `docs/API_USAGE.md` y la feature `books` como ejemplo de referencia en S02.
- Algunas features comparten datos (por ejemplo, `reservations` y `staff`). Lo compartido se mueve a `core/` en lugar de importar entre features.
