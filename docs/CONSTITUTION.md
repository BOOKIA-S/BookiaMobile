# Carta Constitución de BOOKIA Móvil

**Proyecto:** BookiaMobile · Materia: Desarrollo de Aplicaciones Móviles 2 · Huauchinango, Puebla
**Versión del documento:** 0.3 (borrador) · **Fecha:** 2026-11-04
**Equipo:** Jaime de Jesús Fuentes Cruz, Elizabeth de la Cruz Ramírez, Ángel de Jesús López Temporal, Karol Hernán López Ortega, Andrés Alvarado Lazcano
**Repositorio:** `github.com/imDestro1/BookiaMobile`

> ### 🤖 Instrucciones para tu Claude
> Lee este documento como las reglas obligatorias del proyecto y, si está disponible, también el archivo `CLAUDE.md` de la raíz del repo BookiaMobile.
> - **Proyecto:** BOOKIA Móvil es una app Flutter de 5 estudiantes con entrega final el 27 de noviembre de 2026. El docente evalúa la calidad del resultado y el uso correcto de las tecnologías.
> - **La API no se programa aquí.** La API de BOOKIA (Express + MongoDB) vive en el repo público https://github.com/imdestro1/bookia, carpeta `api/`. Se clona en una carpeta junto a BookiaMobile (`../bookia`) y se levanta como **servicio independiente con Docker** (`docker compose up -d`, en `http://localhost:4000/api`). La app Flutter **solo la consume por HTTP**. Nunca copies código de la API dentro de la app. Si falta un endpoint, no lo inventes: avisa a Jaime, que es el único que modifica la API.
> - **Arquitectura y código:** Clean Architecture feature-first + MVVM con Riverpod (secciones 3 a 5). Usa los patrones de la sección 4 en el lugar indicado.
> - **GitHub:** tu integrante crea una rama `feature/<issue>-<nombre>` desde `develop`, hace commits pequeños en Conventional Commits en inglés, sube la rama con `git push` y abre un Pull Request hacia `develop`. **Prohibido** hacer push a `main` o `develop`, hacer merges, crear releases o cambiar `.github/` o Docker: eso lo hace solo **Jaime (administrador)**, quien aprueba cada PR. Guía paso a paso: `docs/GUIA_GITHUB.md`.
> - Haz solo los commits asignados a tu integrante en el Plan de commits (`docs/PLAN.md`).

Este documento fija las reglas que rigen el desarrollo de BOOKIA Móvil. Cada regla tiene un identificador, un nivel y una forma de verificarla, para que el equipo y el docente puedan evaluar si se cumplió.

**Niveles de obligación**

| Nivel | Significado |
| --- | --- |
| **OBLIGATORIO** | Se debe cumplir siempre. Un PR que lo incumple no se integra. |
| **RECOMENDADO** | Se cumple salvo que una decisión registrada en un ADR (`docs/adr/`) justifique lo contrario. |
| **PROHIBIDO** | No se permite en ninguna rama integrada. |

> **Supuestos.** Los puntos marcados con 🟡 **SUPUESTO S-n** son decisiones que tomé sin confirmación. Están listados al final (sección 12) para que se corrijan antes de publicar este documento en el repositorio.

---

## 1. Objetivo

### 1.1 Objetivo general

Desarrollar una aplicación móvil multiplataforma (Android e iOS) con Flutter que permita **localizar, comparar y apartar** libros disponibles en las librerías y papelerías de Huauchinango, Puebla, reutilizando la API REST de BOOKIA (MVP web), y construirla con un proceso de ingeniería **contenerizado (Docker), versionado en GitHub, integrado y entregado de forma continua (CI/CD) y medido con métricas DORA y de calidad**.

### 1.2 Objetivos específicos (verificables)

| ID | Objetivo | Indicador de cumplimiento |
| --- | --- | --- |
| OBJ-01 | Consultar libros por título, autor, género o ISBN sin cuenta | Pantallas 03, 04, 05 y 07 funcionando contra la API |
| OBJ-02 | Mostrar librerías en mapa ordenadas por distancia | Pantallas 02, 08 y 09; endpoint `GET /api/stores/near` |
| OBJ-03 | Escanear el ISBN para abrir la ficha del libro | Pantalla 06; endpoint `GET /api/books?isbn=` |
| OBJ-04 | Reservar 1 a 5 ejemplares con vigencia de 48 h, obtener un código QR de recogida y seguir su estado | Pantallas 10, 11 y 12 |
| OBJ-05 | Notificar por push cambios de reserva y disponibilidad | Pantalla 13; endpoint `POST /api/devices` |
| OBJ-06 | Ofrecer al encargado de tienda un panel para confirmar reservas, escanear el código QR de entrega y editar precio y stock | Pantallas 16 y 17 |
| OBJ-07 | Levantar backend, base de datos y verificación de la app con Docker | `docker compose up` sin pasos manuales extra |
| OBJ-08 | Integrar y entregar de forma continua con GitHub Actions | Workflows en verde y un *release* por semana |
| OBJ-09 | Medir el proceso con DORA y la calidad con métricas heredadas del MVP | `docs/DORA.md` y sección de métricas de cada bitácora |
| OBJ-10 | Repartir el trabajo de forma equitativa y trazable entre 5 integrantes | Bitácoras semanales y `scripts/commit-stats.sh` |

### 1.3 Alcance

**Incluido:** las 17 pantallas de la propuesta aprobada (`propuesta_movil/`), los ajustes a la API descritos en la sección 3.4 y la infraestructura de Docker y CI/CD.

**Fuera de alcance:** pagos en línea, catálogo nacional, chat con la tienda, publicación en App Store o Google Play (se distribuye un APK firmado en GitHub Releases y, si hay Mac disponible, una build de iOS para el iPhone del equipo).

---

## 2. Estándares tecnológicos

### 2.1 Stack

| ID | Elemento | Decisión | Nivel |
| --- | --- | --- | --- |
| TEC-01 | Framework móvil | **Flutter 3.x, canal `stable`**, lenguaje **Dart 3** (null safety y *records/sealed classes*) | OBLIGATORIO |
| TEC-02 | Versión fijada | La versión exacta de Flutter se fija en `.fvmrc` (FVM) y en la imagen de Docker; se registra en la bitácora S01. Todo el equipo y la CI usan la misma | OBLIGATORIO |
| TEC-03 | Plataformas | Android (mínimo API 24) e iOS (mínimo 15). Android es la plataforma de referencia para CI | OBLIGATORIO |
| TEC-04 | Diseño | Material 3 con tema propio BOOKIA (tokens de color, tipografía y espaciado de los mockups); widgets Cupertino donde el mockup lo muestra | OBLIGATORIO |
| TEC-05 | Backend | La API Express + MongoDB/Mongoose del MVP, en su propio repo `imdestro1/bookia` y consumida como servicio Docker (ver 3.4) | OBLIGATORIO |
| TEC-06 | Base de datos | MongoDB 7 en contenedor para desarrollo, CI y demo | OBLIGATORIO |
| TEC-07 | Node.js | Versión LTS activa, fijada en la imagen `node:<LTS>-alpine` | OBLIGATORIO |
| TEC-08 | Versiones | Solo versiones estables. Prohibido Beta, `dev`/`master` de Flutter o paquetes *discontinued* en pub.dev | PROHIBIDO lo contrario |

### 2.2 Paquetes de Flutter aprobados

Cualquier paquete fuera de esta lista requiere un ADR. `pubspec.lock` se versiona siempre.

| Necesidad | Paquete | Patrón o capa donde vive |
| --- | --- | --- |
| Estado e inyección de dependencias | `flutter_riverpod` (+ `riverpod_annotation`, `riverpod_generator`) | `presentation/controllers`, `core/di` |
| Navegación | `go_router` | `app/router.dart` |
| HTTP | `dio` | `core/network` |
| Modelos inmutables y JSON | `freezed`, `json_serializable` | `domain/entities`, `data/dto` |
| Token seguro | `flutter_secure_storage` | `core/storage` |
| Caché sin conexión | `hive_ce` (+ `hive_ce_flutter`) | `data/datasources/local` |
| Mapa | `google_maps_flutter` | `features/stores` |
| Ubicación | `geolocator`, `permission_handler` | `core/location` |
| Escáner ISBN | `mobile_scanner` (ML Kit) | `features/scanner` |
| Push y errores | `firebase_core`, `firebase_messaging`, `firebase_crashlytics` | `core/notifications`, `main.dart` |
| Abrir mapas, llamadas | `url_launcher` | `features/stores` |
| Código QR de reserva | `qr_flutter` (generar) y `mobile_scanner` (leer en el panel de tienda) | `features/reservations`, `features/staff` |
| Formato de moneda y fechas | `intl` | `core/utils` |
| Pruebas | `flutter_test`, `mocktail`, `integration_test` | `test/`, `integration_test/` |
| Lint | `flutter_lints` + reglas extra en `analysis_options.yaml` | raíz de `app/` |

### 2.3 Licencias

| ID | Regla | Nivel |
| --- | --- | --- |
| LIC-01 | Solo dependencias con licencia **MIT, Apache 2.0 o BSD (2 o 3 cláusulas)**. Se amplía la regla del MVP para admitir BSD porque Flutter y la mayoría de sus paquetes oficiales usan BSD-3 | OBLIGATORIO |
| LIC-02 | La CI genera un reporte de licencias por release (`flutter pub deps` + `license-checker` para el backend) | OBLIGATORIO |

---

## 3. Arquitectura

### 3.1 Decisión

**Clean Architecture por capas, organizada *feature-first*, con MVVM en la capa de presentación** (los *ViewModels* son `Notifier`/`AsyncNotifier` de Riverpod).

**Justificación**

1. **Separación de responsabilidades evaluable:** cada capa tiene una carpeta y una regla de dependencia que se puede revisar en cualquier PR.
2. ***Feature-first* = reparto por integrante:** cada pantalla o grupo de pantallas es una carpeta `features/<feature>/`, así cada integrante trabaja en su carpeta con pocos conflictos de merge.
3. **Testeable:** el dominio no depende de Flutter ni de Dio, así que se prueba con pruebas unitarias puras; los repositorios se sustituyen por *mocks*.
4. **Coherente con el MVP:** la API ya usa una arquitectura en capas (`routes → middlewares → controllers → models`); la app replica la idea del lado del cliente.
5. **El backend no se duplica:** la app es un cliente más de la API; las reglas de negocio (reservas, stock, roles, auditoría) siguen en el servidor.

### 3.2 Capas y regla de dependencia

```
presentation  ──►  domain  ◄──  data
 (pages,           (entities,      (dto, datasources,
  widgets,          repositories    repository impl)
  controllers)      abstractas,
                    use cases)
```

| ID | Regla | Nivel |
| --- | --- | --- |
| ARQ-01 | `domain/` no importa `package:flutter`, `dio`, `hive_ce` ni nada de `data/` o `presentation/` | OBLIGATORIO |
| ARQ-02 | `presentation/` solo habla con `domain/` (casos de uso o repositorios abstractos) a través de *providers*; nunca llama a Dio ni a un *datasource* | OBLIGATORIO |
| ARQ-03 | `data/` implementa las interfaces de `domain/repositories` y convierte DTO ↔ entidad con *mappers* | OBLIGATORIO |
| ARQ-04 | Una *feature* no importa archivos internos de otra; lo compartido va a `core/` | OBLIGATORIO |
| ARQ-05 | Los errores cruzan capas como `Failure` (clase *sealed*), nunca como `DioException` | OBLIGATORIO |
| ARQ-06 | Ningún archivo pasa de **300 líneas** (heredado del MVP) | OBLIGATORIO |

**Verificación:** revisión en PR con la lista de la plantilla, más una prueba automática (`test/architecture_test.dart`) que recorre `lib/features/*/domain` y falla si encuentra imports prohibidos.

### 3.3 Estructura de carpetas del repositorio

```
BookiaMobile/
├── app/                              # Proyecto Flutter
│   ├── lib/
│   │   ├── main.dart                 # arranque, Firebase, ProviderScope
│   │   ├── app/                      # app.dart, router.dart, theme/
│   │   ├── core/                     # compartido entre features
│   │   │   ├── network/              # ApiClient (Dio), interceptores
│   │   │   ├── storage/              # TokenStorage (secure storage)
│   │   │   ├── location/             # LocationService
│   │   │   ├── notifications/        # PushService (FCM)
│   │   │   ├── error/                # Failure, mapeo de errores
│   │   │   ├── widgets/              # botones, tarjetas, estados vacíos
│   │   │   └── utils/                # formato de moneda, ISBN, fechas
│   │   └── features/
│   │       ├── splash/               # 01
│   │       ├── onboarding/           # 02 permiso de ubicación
│   │       ├── home/                 # 03
│   │       ├── search/               # 04 resultados, 05 filtros
│   │       ├── scanner/              # 06
│   │       ├── books/                # 07
│   │       ├── stores/               # 08 mapa, 09 ficha de librería
│   │       ├── reservations/         # 10, 11, 12
│   │       ├── notifications/        # 13
│   │       ├── auth/                 # 14
│   │       ├── profile/              # 15
│   │       └── staff/                # 16 panel de tienda, 17 editar oferta
│   │           ├── data/             # datasources/, dto/, repositories/
│   │           ├── domain/           # entities/, repositories/, usecases/
│   │           └── presentation/     # pages/, widgets/, controllers/
│   ├── test/                         # espejo de lib/
│   ├── integration_test/             # flujos de punta a punta
│   ├── analysis_options.yaml
│   └── pubspec.yaml / pubspec.lock
├── docker/
│   ├── api/Dockerfile                # construye la API desde ../bookia/api
│   └── Dockerfile.flutter-ci         # verificación de la app en contenedor
├── docker-compose.yml
├── .github/
│   ├── workflows/                    # ver sección 7
│   ├── ISSUE_TEMPLATE/               # feature, bug, incident
│   ├── pull_request_template.md
│   ├── CODEOWNERS
│   └── dependabot.yml
├── docs/
│   ├── CONSTITUTION.md               # este documento
│   ├── API_USAGE.md                  # cómo consumir la API desde la app
│   ├── SPECS.md
│   ├── QUALITY.md                    # plan de calidad y métricas
│   ├── DORA.md                       # generado cada semana
│   ├── adr/                          # ADR-001, ADR-002, ...
│   └── bitacoras/                    # Bitacora_S01_2026-11-06.docx, ...
├── scripts/                          # commit-stats.sh, dora.sh
├── CLAUDE.md                         # instrucciones para el Claude de cada integrante
├── CHANGELOG.md
├── CONTRIBUTING.md
└── README.md
```

### 3.4 La API de BOOKIA como servicio independiente

✅ **Confirmado:** se reutiliza la misma API del MVP y se monta en un contenedor Docker. La app Flutter solo la consume.

| ID | Regla | Nivel |
| --- | --- | --- |
| SRV-01 | La API vive **solo** en el repo `https://github.com/imdestro1/bookia` (carpeta `api/`, repo público). No se copia ni se importa a BookiaMobile | OBLIGATORIO |
| SRV-02 | Cada integrante clona `bookia` **junto a** `BookiaMobile` (`../bookia`); el `docker-compose.yml` de BookiaMobile construye la imagen de la API desde esa carpeta | OBLIGATORIO |
| SRV-03 | La app se comunica con la API **solo por HTTP** a través de `core/network/ApiClient`; ninguna clase de la app conoce MongoDB | OBLIGATORIO |
| SRV-04 | Solo Jaime (con apoyo del asistente) modifica la API, en el repo `bookia`, por rama y PR con sus pruebas Jest | OBLIGATORIO |
| SRV-05 | El contrato vigente es `bookia/api/API_CONTRACT.md`; `docs/API_USAGE.md` resume lo que usa la app | OBLIGATORIO |

```
mis-proyectos/
├── bookia/          ← repo de la API (se clona y se usa; no se modifica)
│   └── api/
└── BookiaMobile/    ← repo del equipo (app, Docker, docs)
```

✅ **Confirmado (S-8):** Jaime agrega a la API, en el repo `bookia`, estos ajustes pequeños y compatibles con la web, para el escáner de ISBN, los códigos QR de reserva, la ubicación y las notificaciones. La columna "Listo antes de" es la fecha en que el equipo los necesita, y la última columna queda solo como plan de contingencia.

| ID | Cambio | Pantallas | Listo antes de | Alternativa sin tocar la API |
| --- | --- | --- | --- | --- |
| API-01 | Aceptar `Authorization: Bearer <JWT>` además de la cookie `httpOnly` | 10–17 | 9 nov | Guardar la cookie de sesión con `dio_cookie_manager` |
| API-02 | Coordenadas en `stores` (`location` GeoJSON + índice `2dsphere`) y `GET /api/stores/near?lat&lng` | 08, 09 | 9 nov | Coordenadas fijas en la app por tienda y distancia calculada en el teléfono |
| API-03 | `GET /api/books?isbn=` con ISBN normalizado (sin guiones) | 06 | 9 nov | Buscar con `GET /api/books?q=<isbn>` |
| API-04 | `POST /api/devices` para registrar el token FCM | 13 | 16 nov | Notificaciones locales al consultar el estado de la reserva |
| API-05 | `POST/DELETE /api/alerts` para "Avisarme" cuando regrese un libro agotado | 07, 13 | 23 nov | Se omite "Avisarme" |

Las pruebas y el lint de la API corren en la CI del propio repo `bookia`. Cada cambio de la API mantiene las reglas del MVP: pruebas Jest con cobertura ≥ 70 %, auditoría en `audit_logs`, RBAC y respuestas < 200 ms.

---

## 4. Patrones de diseño

Cada patrón tiene un lugar concreto en el código. Un patrón listado aquí que no aparezca en el código es un incumplimiento.

| ID | Patrón | Tipo | Dónde se usa | Para qué |
| --- | --- | --- | --- | --- |
| PAT-01 | **Repository** | Arquitectura | `features/*/domain/repositories/*_repository.dart` (interfaz) y `features/*/data/repositories/*_repository_impl.dart` | Aísla la app del origen de datos (API o caché) |
| PAT-02 | **MVVM** | Arquitectura | `features/*/presentation/controllers/*_controller.dart` (ViewModel) + `pages/` (View) | La vista solo pinta estado; la lógica de pantalla vive en el controlador |
| PAT-03 | **Provider / Inyección de dependencias** | Creacional | `core/di/providers.dart` y providers de cada feature (Riverpod) | Entrega a cada capa sus dependencias y permite sustituirlas por *mocks* en pruebas |
| PAT-04 | **Singleton** | Creacional | `ApiClient` (una sola instancia de Dio), `TokenStorage`, `PushService`, expuestos con `Provider` *keepAlive* | Una conexión y un almacén compartidos durante todo el ciclo de vida |
| PAT-05 | **Factory** | Creacional | Constructores `factory BookDto.fromJson(...)` en `data/dto/`; `FailureFactory.fromDioException()` en `core/error/` | Crear objetos según el tipo de dato o error recibido |
| PAT-06 | **Observer** | Comportamiento | `ref.watch`/`ref.listen` de Riverpod en las vistas; `Stream` de mensajes FCM en `PushService`; `ProviderObserver` que registra cambios de estado en modo debug | La UI reacciona sola cuando cambia el estado o llega una notificación |
| PAT-07 | **Adapter (Mapper)** | Estructural | `data/mappers/*_mapper.dart` (DTO `snake_case` de la API → entidad de dominio); `TypeAdapter` de Hive | Traduce el formato de la API al modelo de la app |
| PAT-08 | **Chain of Responsibility** | Comportamiento | Interceptores de Dio en `core/network/interceptors/`: `AuthInterceptor` → `LoggingInterceptor` → `ErrorInterceptor` | Cada petición pasa por una cadena: añade token, registra, traduce errores |
| PAT-09 | **Strategy** | Comportamiento | `features/search/domain/sort/`: `SortByPrice`, `SortByDistance`, `SortByTitle` | Cambiar el orden de resultados (filtros, pantalla 05) sin `if` encadenados |
| PAT-10 | **State** | Comportamiento | `features/reservations/domain/entities/reservation_status.dart` (clase *sealed*: `Pending`, `Confirmed`, `Delivered`, `Cancelled`, `Expired`) con las acciones permitidas por estado | Modela las transiciones de reserva del MVP; la UI muestra solo las acciones válidas |
| PAT-11 | **Facade** | Estructural | `core/location/location_service.dart` (permiso + posición + distancia) y `core/notifications/push_service.dart` | Esconde APIs de plataforma detrás de una interfaz simple |
| PAT-12 | **Middleware (Chain)** en la API | Comportamiento | `bookia/api/middlewares/` (`requireAuth`, `requireRole`), heredado del MVP | RBAC antes de cada controlador |

**Verificación:** cada ADR o PR que introduce un patrón enlaza su archivo; la bitácora semanal tiene una fila "patrones aplicados esta semana". En la entrega final se adjunta la tabla con la ruta exacta de cada patrón.

---

## 5. Estándares de código

| ID | Regla | Nivel |
| --- | --- | --- |
| COD-01 | Nombres Dart: `UpperCamelCase` en clases, enums y widgets; `lowerCamelCase` en variables, funciones y parámetros; `snake_case` en archivos y carpetas; constantes `lowerCamelCase` (guía oficial de Dart) | OBLIGATORIO |
| COD-02 | JSON de la API en `snake_case`, convertido con `@JsonSerializable(fieldRename: FieldRename.snake)` | OBLIGATORIO |
| COD-03 | Código, comentarios y mensajes de commit en inglés; textos visibles al usuario en español (es-MX) | OBLIGATORIO |
| COD-04 | `flutter analyze` con **0 errores y 0 warnings**; `dart format --set-exit-if-changed` sin cambios | OBLIGATORIO |
| COD-05 | Backend: ESLint + Prettier sin advertencias (heredado) | OBLIGATORIO |
| COD-06 | Ningún secreto en el código: URL de la API con `--dart-define=API_BASE_URL=...`; claves de Firebase y Google Maps fuera del repo o restringidas por paquete | OBLIGATORIO |
| COD-07 | Widgets de UI sin lógica de negocio; textos y colores desde el tema, no valores sueltos | OBLIGATORIO |
| COD-08 | `print()` prohibido; usar `debugPrint` o el logger | PROHIBIDO lo contrario |
| COD-09 | Accesibilidad: áreas táctiles ≥ 48 dp, contraste AA, `Semantics` en íconos sin texto | OBLIGATORIO |

---

## 6. Versionamiento y flujo de trabajo en GitHub

### 6.1 Herramienta

**Git + GitHub** (repositorio `BookiaMobile`), con GitHub Issues, Projects (tablero Kanban), Milestones, Releases y Actions.

### 6.2 Roles en GitHub

El equipo no tiene experiencia previa con GitHub, así que **toda la administración la concentra Jaime** y los demás integrantes solo suben commits para su aprobación. La guía paso a paso está en `docs/GUIA_GITHUB.md`.

| ID | Rol | Quién | Puede | No puede |
| --- | --- | --- | --- | --- |
| ROL-01 | **Administrador (maintainer)** | Jaime de Jesús Fuentes Cruz | Crear y configurar el repo, proteger ramas, invitar colaboradores, crear issues y milestones, revisar, aprobar y fusionar PR, resolver conflictos, configurar Actions, Docker y secretos, crear releases y tags, y modificar la API (repo `bookia`) | Aprobar su propio PR |
| ROL-02 | **Colaborador (developer)** | Elizabeth, Ángel, Karol y Andrés | Crear su rama desde `develop`, hacer commits, hacer `git push` de su rama, abrir PR hacia `develop` y aprobar los PR de Jaime cuando le toque | Hacer push a `main` o `develop`, fusionar, crear tags o releases, cambiar `.github/`, `docker/` o `docker-compose.yml` |

### 6.3 Estrategia de ramas: GitFlow simplificado

🟡 **SUPUESTO S-2:** GitFlow simplificado (y no *trunk-based*) porque el docente pide control y registro del trabajo en equipo, y `develop` da un punto de integración visible antes de cada release semanal.

| Rama | Propósito | Se crea desde | Se integra en | Protección |
| --- | --- | --- | --- | --- |
| `main` | Código liberado; cada merge es un release con tag | | | PR obligatorio, CI verde, 1 aprobación, sin *push* directo |
| `develop` | Integración de la semana | `main` | `main` (viernes) | PR obligatorio, CI verde, 1 aprobación |
| `feature/<issue>-<slug>` | Una funcionalidad o pantalla | `develop` | `develop` | Vida máxima 3 días |
| `fix/<issue>-<slug>` | Corrección no urgente | `develop` | `develop` | |
| `hotfix/<issue>-<slug>` | Corrección urgente de un release | `main` | `main` y `develop` | Cuenta para DORA (ver 9) |
| `release/vX.Y.Z` | Congelar la semana y preparar el release | `develop` | `main` | Solo cambios de versión y CHANGELOG |
| `docs/<slug>`, `chore/<slug>`, `ci/<slug>` | Documentación, mantenimiento, pipelines | `develop` | `develop` | |

Ejemplo: `feature/23-book-detail-screen`.

### 6.4 Commits: Conventional Commits + *small commits*

Formato: `tipo(alcance): descripción en imperativo` y, en el cuerpo, `Refs #<issue>`.

Tipos permitidos: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
Alcances: el nombre de la *feature* (`search`, `books`, `stores`, ...) o del módulo (`core`, `network`, `api-auth`, `docker`, `ci`).

| ID | Regla | Nivel |
| --- | --- | --- |
| VER-01 | Todo commit sigue Conventional Commits; lo valida `commitlint` en la CI | OBLIGATORIO |
| VER-02 | ***Small commits*:** un solo propósito por commit y como máximo ~150 líneas cambiadas (sin contar archivos generados ni `pubspec.lock`) | OBLIGATORIO |
| VER-03 | Cada integrante hace commits con **su propia cuenta** de GitHub (correo configurado en `git config user.email`) | OBLIGATORIO |
| VER-04 | Cada commit compila y pasa las pruebas existentes | OBLIGATORIO |
| VER-05 | PR enlazado a un issue (`Closes #n`), con la plantilla llena, máximo ~400 líneas | OBLIGATORIO |
| VER-06 | Jaime revisa, aprueba y fusiona todos los PR de los colaboradores. Los PR de Jaime los aprueba un colaborador, por turno semanal. Nadie aprueba su propio PR | OBLIGATORIO |
| VER-07 | **Squash merge PROHIBIDO.** Se usa *Create a merge commit* para conservar cada commit pequeño y su autor en el historial | PROHIBIDO lo contrario |
| VER-08 | `git push --force` prohibido en `main` y `develop` | PROHIBIDO |
| VER-09 | Solo el administrador crea ramas `release/*`, `hotfix/*`, tags y releases | OBLIGATORIO |

### 6.5 Versionado semántico y releases

- Versiones `MAJOR.MINOR.PATCH` (SemVer) en `pubspec.yaml` (`version: 0.2.0+2`) y en tags `vX.Y.Z`.
- Un release por semana: `v0.1.0` (S01, 6 nov), `v0.2.0` (S02, 13 nov), `v0.3.0` (S03, 20 nov) y `v1.0.0` (S04, **entrega final el 27 de noviembre de 2026**). Los hotfix suben PATCH.
- `CHANGELOG.md` generado a partir de los commits (formato *Keep a Changelog*).

### 6.6 Gestión del trabajo

- Jaime crea **un issue por tarea** con etiquetas `type:*`, `screen:01`…`screen:17`, `area:app|api|devops|docs`, asignado a un integrante y a un *milestone* (`S01`…`S04`).
- Tablero de GitHub Projects con columnas: *Backlog → Por hacer → En progreso → En revisión → Hecho*.
- `CODEOWNERS` asigna como revisor al dueño de cada carpeta de *feature*.

---

## 7. Docker

| ID | Regla | Nivel |
| --- | --- | --- |
| DOC-01 | `docker compose up -d` (desde BookiaMobile) levanta **MongoDB + API** listos para que la app se conecte, sin instalar Node ni Mongo en la máquina | OBLIGATORIO |
| DOC-02 | La API se construye con `docker/api/Dockerfile` de BookiaMobile, que toma el código de `../bookia/api` como contexto adicional: *multi-stage* (dependencias → producción) con usuario no root, `HEALTHCHECK` contra `/api/health` y solo dependencias de producción | OBLIGATORIO |
| DOC-03 | La verificación de la app (`flutter analyze`, `flutter test`, `flutter build apk`) corre dentro de un contenedor con la versión de Flutter fijada (`docker compose --profile ci run --rm app-ci`) | OBLIGATORIO |
| DOC-04 | Secretos solo por `.env` (no versionado); se versiona `.env.example` | OBLIGATORIO |
| DOC-05 | Volumen nombrado para los datos de Mongo y servicio `seed` (perfil `tools`) para cargar los datos de prueba | OBLIGATORIO |
| DOC-06 | Las imágenes se construyen en la CI y se publican en GitHub Container Registry (`ghcr.io`) con el tag del release | OBLIGATORIO |
| DOC-07 | La build de iOS no se conteneriza (requiere macOS con Xcode); se documenta como excepción | Excepción registrada |

**`docker-compose.yml` (esqueleto)**

```yaml
services:
  mongo:
    image: mongo:7
    volumes: [mongo_data:/data/db]
    healthcheck:
      test: ["CMD", "mongosh", "--quiet", "--eval", "db.adminCommand('ping')"]
      interval: 10s
  api:
    build:
      context: ./docker/api
      additional_contexts:
        api_src: ${BOOKIA_API_PATH:-../bookia/api}   # código del repo imdestro1/bookia
    env_file: .env
    environment:
      MONGODB_URI: mongodb://mongo:27017/bookia
    image: bookiamobile-api
    ports: ["4000:4000"]
    depends_on:
      mongo: { condition: service_healthy }
  seed:
    image: bookiamobile-api            # reutiliza la imagen de la API
    command: npm run seed
    env_file: .env
    environment:
      MONGODB_URI: mongodb://mongo:27017/bookia
    depends_on: [mongo]
    profiles: [tools]
  app-ci:
    build: { context: ., dockerfile: docker/Dockerfile.flutter-ci }
    working_dir: /workspace/app
    volumes: [./app:/workspace/app]
    command: sh -c "flutter pub get && flutter analyze && flutter test --coverage"
    profiles: [ci]
volumes:
  mongo_data:
```

**`docker/api/Dockerfile` (esqueleto)**

```dockerfile
# El código llega desde ../bookia/api como contexto "api_src"
FROM node:24-alpine AS deps
WORKDIR /app
COPY --from=api_src package*.json ./
RUN npm ci --omit=dev

FROM node:24-alpine
WORKDIR /app
COPY --from=api_src . .
RUN rm -rf node_modules
COPY --from=deps /app/node_modules ./node_modules
USER node
EXPOSE 4000
HEALTHCHECK CMD wget -qO- http://localhost:4000/api/health || exit 1
CMD ["node", "server.js"]
```

**`docker/Dockerfile.flutter-ci`:** parte de la imagen `ghcr.io/cirruslabs/flutter:<versión fijada>`.

**Conexión de la app a la API en contenedor:** emulador de Android `http://10.0.2.2:4000/api`; teléfono físico en la misma red `http://<IP-de-la-PC>:4000/api`, pasado con `--dart-define=API_BASE_URL`.

---

## 8. CI/CD con GitHub Actions

| Workflow | Disparador | Qué hace | ¿Bloquea el merge? |
| --- | --- | --- | --- |
| `app-ci.yml` | PR y push a `develop`/`main` con cambios en `app/` | `dart format` check, `flutter analyze`, `flutter test --coverage`, falla si cobertura < 70 %, `flutter build apk --debug`, sube `lcov` como artefacto | Sí |
| `api-service.yml` | PR y push | Clona `imdestro1/bookia` en `bookia/`, levanta `docker compose up` con `BOOKIA_API_PATH=bookia/api` y comprueba `GET /api/health` | Sí |
| `docker.yml` | Push a `main` | Publica la imagen de la API y la de Flutter CI en `ghcr.io` | |
| `commitlint.yml` | PR | Valida Conventional Commits de todos los commits y del título del PR | Sí |
| `security.yml` | PR y semanal | Dependabot, `npm audit --omit=dev`, revisión de licencias | Aviso |
| `release.yml` | Tag `v*` en `main` | Build de APK release, GitHub Release con CHANGELOG, APK e imágenes Docker con el tag | |
| `dora.yml` | Cada viernes y manual | Calcula las 4 métricas DORA con la API de GitHub y actualiza `docs/DORA.md` | |

**Definición de "despliegue" (para DORA):** un *GitHub Release* publicado desde `main` con su APK y sus imágenes Docker. No hay servidor de producción en el alcance de la materia (🟡 **SUPUESTO S-3**).

| ID | Regla | Nivel |
| --- | --- | --- |
| CI-01 | `main` y `develop` exigen los checks marcados "Sí" antes de fusionar | OBLIGATORIO |
| CI-02 | Un pipeline roto en `develop` se corrige antes de cualquier otro trabajo | OBLIGATORIO |
| CI-03 | Ningún check se desactiva ni se marca como opcional para pasar un PR | PROHIBIDO |

---

## 9. Métricas DORA y de calidad

### 9.1 DORA

| Métrica | Cómo se mide aquí | Meta del equipo |
| --- | --- | --- |
| Frecuencia de despliegue | Releases publicados en `main` por semana | ≥ 1 por semana |
| Tiempo de entrega de cambios | Mediana desde el primer commit de un PR hasta el release que lo incluye | < 7 días (meta interna: PR abierto → fusionado en < 48 h) |
| Tasa de fallo de cambios | Releases que necesitaron `hotfix/*` o `revert` ÷ releases totales | ≤ 15 % |
| Tiempo de recuperación (MTTR) | Apertura → cierre de issues con etiqueta `incident` | < 24 h |

### 9.2 Calidad (heredadas del MVP y propias del móvil, mapeadas a ISO/IEC 25010)

| ID | Métrica | Meta | Herramienta | Característica ISO 25010 |
| --- | --- | --- | --- | --- |
| CAL-01 | Cobertura de pruebas de la app | ≥ 70 % de líneas en `domain/` y `data/` | `flutter test --coverage` + `lcov` | Mantenibilidad |
| CAL-02 | Cobertura de pruebas del backend | ≥ 70 % (el MVP terminó en 99.5 %) | Jest | Mantenibilidad |
| CAL-03 | Avisos del analizador | 0 | `flutter analyze`, ESLint | Mantenibilidad |
| CAL-04 | Tamaño de archivo | ≤ 300 líneas | revisión + script | Mantenibilidad |
| CAL-05 | Latencia de la API | p95 < 200 ms | autocannon contra el contenedor | Eficiencia de desempeño |
| CAL-06 | Arranque en frío de la app | < 3 s en Android de gama media | `flutter run --profile` + DevTools | Eficiencia de desempeño |
| CAL-07 | Sesiones sin fallos | ≥ 99 % | Firebase Crashlytics | Fiabilidad |
| CAL-08 | Tasa de éxito de la CI | ≥ 90 % de corridas en verde por semana | GitHub Actions | Fiabilidad del proceso |
| CAL-09 | Defectos abiertos de prioridad A | 0 al cerrar cada semana | Issues `bug` + `prio:A` | Adecuación funcional |
| CAL-10 | Cumplimiento de criterios de aceptación | 100 % de las pantallas de la semana | Auditoría con el formato del MVP (Requisito, Criterio, Prueba, Resultado, Evidencia, Defecto, Prioridad) | Adecuación funcional |
| CAL-11 | Accesibilidad | Áreas táctiles y contraste según COD-09 | Accessibility Scanner / revisión | Usabilidad |
| CAL-12 | Vulnerabilidades altas o críticas | 0 | Dependabot, `npm audit` | Seguridad |

### 9.3 Equidad del trabajo

| ID | Regla | Meta |
| --- | --- | --- |
| EQ-01 | Commits por integrante en el proyecto | Mismo número para todos: 12 de trabajo + 1 de bitácora o informe (13) |
| EQ-02 | Actividad semanal | Cada integrante: 3 commits, ≥ 1 PR propio y ≥ 1 revisión a otro integrante |

---

## 10. Seguridad

| ID | Regla | Nivel |
| --- | --- | --- |
| SEG-01 | El JWT en la app se guarda solo en `flutter_secure_storage` (Keychain/Keystore); nunca en `SharedPreferences` ni Hive | OBLIGATORIO |
| SEG-02 | Toda comunicación con la API fuera de desarrollo local es HTTPS | OBLIGATORIO |
| SEG-03 | Se conservan del MVP: bcrypt ≥ 10 rondas, RBAC con middlewares, sanitización de filtros, rate limit en auth, `audit_logs` | OBLIGATORIO |
| SEG-04 | La ubicación solo se usa para ordenar por distancia y trazar rutas; no se envía ni se guarda en el servidor (como dice la pantalla 02) | OBLIGATORIO |
| SEG-05 | Aviso de privacidad accesible desde Perfil (LFPDPPP) | OBLIGATORIO |

---

## 11. Pruebas

| ID | Tipo | Alcance mínimo | Nivel |
| --- | --- | --- | --- |
| PRU-01 | Unitarias | Casos de uso, mappers, controladores (Notifiers), validador de ISBN, estados de reserva | OBLIGATORIO |
| PRU-02 | De widget | Cada pantalla: estado de carga, vacío, error y con datos | OBLIGATORIO |
| PRU-03 | De integración (app) | Flujo buscar → ficha → librería, y flujo login → reservar → mis reservas, en `integration_test/` | OBLIGATORIO |
| PRU-04 | API | Jest + Supertest para cada endpoint nuevo (API-01 a API-05) | OBLIGATORIO |
| PRU-05 | Auditoría de calidad por entrega | Hoja de auditoría con el formato del MVP, con evidencia por caso | OBLIGATORIO |

**Definición de terminado (DoD) de una tarea:** código en `develop` por PR aprobado, CI verde, pruebas de la tarea escritas, criterios de aceptación del issue cumplidos, captura o GIF de la pantalla en el PR y fila registrada en la bitácora de la semana.

---

## 12. Supuestos por confirmar

| ID | Supuesto | Qué cambia si es distinto |
| --- | --- | --- |
| S-1 | ✅ Confirmado: la API se queda en su repo `imdestro1/bookia` (público), separada de la app, y se consume como servicio Docker | |
| S-2 | GitFlow simplificado (`main` + `develop` + ramas cortas) | Con *trunk-based* se quita `develop` y se libera desde `main` |
| S-3 | "Despliegue" = GitHub Release con APK e imágenes; no hay servidor público | Si hay servidor (Render, VPS), se agrega un job de despliegue y DORA se mide contra él |
| S-4 | ✅ Confirmado: 4 semanas, S01 (4–6 nov) a S04 (23–27 nov); entrega final el 27 de noviembre | |
| S-5 | Se usa Firebase (FCM y Crashlytics) con una cuenta de Google del equipo | Sin Firebase, la pantalla 13 se hace con notificaciones locales |
| S-6 | ✅ Confirmado: las bitácoras se entregan en **Word (.docx)**; una copia se guarda en `docs/bitacoras/` del repo | |
| S-7 | Al menos un integrante tiene Mac para compilar en iPhone; si no, la demo es en Android | Sin Mac, iOS queda fuera de la demo |
| S-8 | ✅ Confirmado: se agregan los ajustes API-01 a API-05 (escáner, códigos, ubicación, push, token) | |
