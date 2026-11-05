# Plan de bitácoras semanales y reparto de commits · BOOKIA Móvil

**Repositorio:** `github.com/imDestro1/BookiaMobile` · **Versión:** 0.1 · **Fecha:** 2026-11-04

> ### 🤖 Instrucciones para tu Claude
>
> - Proyecto: BOOKIA Móvil, app Flutter (Android/iOS) de un equipo de 5 estudiantes. Muestra qué librerías de Huauchinango, Puebla tienen cada libro, su precio y existencias, y permite apartarlo.
> - La API de BOOKIA ya existe y NO se programa en este repo: vive en https://github.com/imdestro1/bookia (carpeta api/, repo público). Clónala junto a BookiaMobile y levántala como servicio con Docker: docker compose up -d (MongoDB + API en http://localhost:4000/api). Flutter solo la consume por HTTP; nunca copies código de la API dentro de app/.
> - Si una pantalla necesita algo que la API no tiene, no lo inventes ni lo programes: avisa a Jaime (administrador), que es quien cambia la API en su repo.
> - Arquitectura obligatoria: Clean Architecture feature-first + MVVM con Riverpod. Carpetas app/lib/features/<feature>/{data,domain,presentation}. Lee docs/CONSTITUTION.md antes de escribir código; cada regla tiene un ID (ARQ-01, PAT-01, VER-01...).
> - Trabajo en GitHub: crea una rama feature/<issue>-<nombre> desde develop, haz commits pequeños con Conventional Commits en inglés (feat(books): add ...), sube tu rama con git push y abre un Pull Request hacia develop. NUNCA hagas push a main ni a develop, ni merges, ni releases: eso lo hace solo Jaime.
> - Haz solo los commits asignados a tu integrante en el Plan de commits (docs/PLAN.md). Cada commit debe compilar y traer sus pruebas.
> - Este documento dice qué commit le toca a cada integrante y cada semana (tabla 4). Ayuda a tu integrante a hacer **solo sus commits**, con el mensaje exacto de la tabla, y dale los comandos de Git de la guía `docs/GUIA_GITHUB.md`.

Este plan acompaña a la Carta Constitución (`docs/CONSTITUTION.md`). Define quién hace qué, cuántos commits le tocan a cada integrante cada semana, cómo se nombran ramas y commits, y cómo se llena la bitácora semanal en Word para sustentar todo el proyecto ante el docente.

> ✅ **Confirmado:** la entrega final es el **viernes 27 de noviembre de 2026**. Son 4 bitácoras (6, 13, 20 y 27 de noviembre). El lunes 16 es feriado, por eso S03 empieza el 17.

## 1. Equipo, roles y módulos

| Clave | Integrante | Rol | Módulos y pantallas |
| --- | --- | --- | --- |
| I1 | Jaime de Jesús Fuentes Cruz | Líder técnico y DevOps | Administrador de GitHub (repo, ramas, revisiones, merges, releases), Docker, CI/CD, DORA y cambios a la API en el repo bookia · 01 Splash, 02 Permiso de ubicación, 13 Notificaciones |
| I2 | Elizabeth de la Cruz Ramírez | Core de la app y búsqueda | Proyecto Flutter, tema, rutas, red · 03 Inicio, 04 Resultados, 05 Filtros |
| I3 | Ángel de Jesús López Temporal | Libros, escáner y documentación técnica | SPECS, ADR, guía de uso de la API · 06 Escanear ISBN, 07 Ficha de libro, 12 Mis reservas |
| I4 | Karol Hernán López Ortega | Librerías, mapa y panel de tienda | README, CONTRIBUTING · 08 Mapa, 09 Ficha de librería, 16 Panel de tienda, 17 Editar oferta |
| I5 | Andrés Alvarado Lazcano | Cuentas, reservas y calidad | Plan de calidad, guía de GitHub, estadísticas · 14 Login, 15 Perfil, 10 Reservar, 11 Reserva lista |

El rol define a quién se le pregunta primero, no que esa persona haga sola todo ese tema: todos programan pantallas, todos hacen pruebas y todos escriben una bitácora.

## 2. Calendario

| Semana | Fechas | Objetivo | Release (viernes) | Redacta la bitácora |
| --- | --- | --- | --- | --- |
| S01 | 4–6 nov | Arranque desde cero: repo, reglas, documentación, esqueleto Flutter, API del MVP como servicio Docker | `v0.1.0` | Andrés Alvarado Lazcano |
| S02 | 9–13 nov | CI completa, red de la app y primeras pantallas: 01, 03, 04, 07, 09, 14 | `v0.2.0` | Jaime de Jesús Fuentes Cruz |
| S03 | 17–20 nov | Escáner, ubicación, mapa, filtros y reservas: 02, 05, 06, 08, 10, 11, 12, 16 | `v0.3.0` | Elizabeth de la Cruz Ramírez |
| S04 | 23–27 nov | Push, panel de oferta, QR de entrega, perfil, pruebas E2E y entrega final: 13, 15, 17 | `v1.0.0` | Ángel de Jesús López Temporal · informe final: Karol Hernán López Ortega |

**Ritmo de cada semana**

1. **Lunes:** Jaime crea y asigna los issues de la semana en el tablero (uno por commit o grupo de commits de la tabla 4).
2. **Lunes a jueves:** cada quien trabaja en su rama, hace sus commits, sube la rama (`git push`) y abre su PR hacia `develop`. **Jaime revisa, aprueba y fusiona**; si hay conflictos, él los resuelve.
3. **Jueves 20:00:** corte (en S04 el corte es el miércoles 25 para dejar el jueves a pruebas finales). Todo lo de la semana debe estar fusionado en `develop`.
4. **Viernes:** Jaime crea `release/vX.Y.Z`, se fusiona a `main`, se etiqueta el release (eso es el despliegue que cuenta para DORA), se corre `scripts/commit-stats.sh` y el redactor de la semana llena la bitácora en Word y la sube a `docs/bitacoras/` con su propio commit.

## 3. Convenciones de ramas y commits

**Ramas:** `main` (releases), `develop` (integración), `feature/<issue>-<slug>`, `fix/…`, `hotfix/…`, `release/vX.Y.Z`, `docs/…`, `chore/…`, `ci/…`, `build/…`. Ejemplo: `feature/23-book-detail`.

**Commits (Conventional Commits, en inglés):**

```
feat(books): add book detail screen with store comparison

Shows price and stock per store using the offers of GET /api/books/:id.

Refs #23
```

| Regla | Detalle |
| --- | --- |
| ✔ | Un propósito por commit, ~150 líneas como máximo (sin generados ni `pubspec.lock`) |
| ✔ | Cada commit compila y pasa las pruebas |
| ✔ | Cada commit con la cuenta de GitHub de su autor (revisar `git config user.name` y `user.email` antes del primer commit) |
| ✔ | Cuerpo con `Refs #<issue>`; el PR lleva `Closes #<issue>` |
| ✔ | Jaime revisa, aprueba y fusiona los PR de todos. Los PR de Jaime los aprueba el redactor de la bitácora de esa semana. Nadie aprueba su propio PR |
| ✔ | Solo Jaime fusiona, con *Create a merge commit*. **Squash prohibido** (borra los commits pequeños y su autoría) |
| ✔ | Si un commit de la tabla resulta muy grande, se parte en dos; si queda muy chico, se junta con el siguiente del mismo autor. Nunca se pasa trabajo de un integrante a otro sin anotarlo en la bitácora |

Tipos: `feat` funcionalidad · `fix` corrección · `test` pruebas · `docs` documentación · `build` Docker y dependencias · `ci` workflows · `chore` mantenimiento · `refactor` · `perf` · `style`.

## 4. Reparto de commits por integrante

Cada integrante tiene **12 commits de trabajo (3 por semana) + 1 commit de documento = 13 commits**. Cada commit entrega algo completo: una pantalla funcionando, un endpoint con sus pruebas o un pipeline listo. Las dependencias entre integrantes están ordenadas para que nadie espere: lo que otros necesitan va al inicio de la semana (por ejemplo la red de la app de Elizabeth y el token Bearer de Andrés en S02).

### Resumen de balance

| Integrante | S01 | S02 | S03 | S04 | Bitácora o informe | Total | feat | test | docs/ci/build/chore |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Jaime de Jesús Fuentes Cruz | 3 | 3 | 3 | 3 | 1 | **13** | 4 | 0 | 8 |
| Elizabeth de la Cruz Ramírez | 3 | 3 | 3 | 3 | 1 | **13** | 10 | 2 | 0 |
| Ángel de Jesús López Temporal | 3 | 3 | 3 | 3 | 1 | **13** | 8 | 1 | 3 |
| Karol Hernán López Ortega | 3 | 3 | 3 | 3 | 1 | **13** | 7 | 2 | 3 |
| Andrés Alvarado Lazcano | 3 | 3 | 3 | 3 | 1 | **13** | 7 | 2 | 3 |
| **Equipo** | 15 | 15 | 15 | 15 | 5 | **65** | | | |

### I1 · Jaime de Jesús Fuentes Cruz (Líder técnico y DevOps)

| ID | Semana | Rama | Mensaje de commit |
| --- | --- | --- | --- |
| I1-01 | S01 | `chore/repo-setup` | `chore(repo): initialize repository with README, LICENSE, .gitignore and CLAUDE.md` |
| I1-02 | S01 | `ci/github-setup` | `ci(github): add PR/issue templates, CODEOWNERS and commitlint workflow` |
| I1-03 | S01 | `build/docker` | `build(docker): add compose with mongo and BOOKIA API service built from the bookia repo` |
| I1-04 | S02 | `ci/pipelines` | `ci(app): add Flutter format, analyze, test and coverage workflow` |
| I1-05 | S02 | `ci/pipelines` | `ci(docker): build and smoke-test the API service with compose in CI` |
| I1-06 | S02 | `feature/splash` | `feat(splash): add splash screen with stored session check` |
| I1-07 | S03 | `feature/location-permission` | `feat(onboarding): add location permission screen and LocationService` |
| I1-08 | S03 | `feature/push-token` | `feat(notifications): register FCM device token with /api/devices` |
| I1-09 | S03 | `ci/release` | `ci(release): build release APK and publish images on version tags` |
| I1-10 | S04 | `feature/push` | `feat(notifications): integrate FCM push with reservation deep links` |
| I1-11 | S04 | `ci/dora` | `ci(dora): add workflow that writes docs/DORA.md` |
| I1-12 | S04 | `release/v1.0.0` | `chore(release): bump version to 1.0.0 and update CHANGELOG` |
| I1-B | S02 | `docs/bitacora-s02` | `docs(bitacora): add weekly log S02` |

### I2 · Elizabeth de la Cruz Ramírez (Core de la app y búsqueda)

| ID | Semana | Rama | Mensaje de commit |
| --- | --- | --- | --- |
| I2-01 | S01 | `feature/app-scaffold` | `feat(app): scaffold Flutter project with feature-first folders, FVM and lints` |
| I2-02 | S01 | `feature/theme` | `feat(theme): add BOOKIA design tokens and Material 3 theme` |
| I2-03 | S01 | `feature/router` | `feat(router): configure go_router with bottom navigation shell` |
| I2-04 | S02 | `feature/network` | `feat(network): add ApiClient with interceptors and Failure mapping` |
| I2-05 | S02 | `feature/home` | `feat(home): add home screen with search bar and genres` |
| I2-06 | S02 | `feature/search-results` | `feat(search): add paginated results list with availability badges` |
| I2-07 | S03 | `feature/search-results` | `test(search): add tests for search controller and repository` |
| I2-08 | S03 | `feature/filters` | `feat(filters): add filters bottom sheet fed by /books/filters` |
| I2-09 | S03 | `feature/filters` | `feat(search): add sort strategies by price, distance and title` |
| I2-10 | S04 | `feature/offline-cache` | `feat(cache): cache recent searches offline with hive_ce` |
| I2-11 | S04 | `feature/home` | `feat(home): show nearby stores and most searched books` |
| I2-12 | S04 | `test/e2e` | `test(e2e): add integration test for search, book and store flow` |
| I2-B | S03 | `docs/bitacora-s03` | `docs(bitacora): add weekly log S03` |

### I3 · Ángel de Jesús López Temporal (Libros, escáner y documentación técnica)

| ID | Semana | Rama | Mensaje de commit |
| --- | --- | --- | --- |
| I3-01 | S01 | `docs/specs` | `docs(specs): add mobile SPECS with screens and API usage` |
| I3-02 | S01 | `docs/adr` | `docs(adr): add ADR-001 architecture and ADR-002 state management` |
| I3-03 | S01 | `docs/api-usage` | `docs(api): add API_USAGE.md on running the BOOKIA API service and its endpoints` |
| I3-04 | S02 | `feature/book-detail` | `feat(books): add Book entity, DTO, mapper and repository` |
| I3-05 | S02 | `feature/book-detail` | `feat(books): add book detail screen with store comparison` |
| I3-06 | S02 | `feature/isbn-lookup` | `feat(books): add book lookup by ISBN consuming /api/books?isbn=` |
| I3-07 | S03 | `feature/isbn-scanner` | `feat(scanner): add ISBN barcode scanner with mobile_scanner` |
| I3-08 | S03 | `feature/isbn-scanner` | `feat(scanner): validate EAN-13 and open book detail, with tests` |
| I3-09 | S03 | `feature/my-reservations` | `feat(reservations): add my reservations list with cancel and countdown` |
| I3-10 | S04 | `feature/notify-me` | `feat(books): add notify-me alert for out-of-stock books via /api/alerts` |
| I3-11 | S04 | `feature/book-actions` | `feat(books): add favorite and share actions` |
| I3-12 | S04 | `feature/my-reservations` | `test(reservations): add tests for my reservations` |
| I3-B | S04 | `docs/bitacora-s04` | `docs(bitacora): add weekly log S04` |

### I4 · Karol Hernán López Ortega (Librerías, mapa y panel de tienda)

| ID | Semana | Rama | Mensaje de commit |
| --- | --- | --- | --- |
| I4-01 | S01 | `docs/readme` | `docs(readme): add setup guide for Flutter and Docker` |
| I4-02 | S01 | `docs/contributing` | `docs(contributing): add branch, commit and PR rules` |
| I4-03 | S01 | `chore/env` | `chore(docker): add .env.example and seed instructions` |
| I4-04 | S02 | `feature/store-detail` | `feat(stores): add store repository and store detail screen` |
| I4-05 | S02 | `feature/stores-near` | `feat(stores): add stores list ordered by distance from /api/stores/near` |
| I4-06 | S02 | `feature/store-detail` | `feat(stores): add call and directions actions` |
| I4-07 | S03 | `feature/stores-map` | `feat(map): add Google Map with store markers and quick card` |
| I4-08 | S03 | `feature/staff-panel` | `feat(staff): add store panel to confirm or reject reservations` |
| I4-09 | S03 | `feature/stores-map` | `test(stores): add tests for store detail and map` |
| I4-10 | S04 | `feature/edit-offer` | `feat(staff): edit offer price and stock` |
| I4-11 | S04 | `feature/qr-pickup` | `feat(staff): scan reservation QR code to mark pickup` |
| I4-12 | S04 | `feature/edit-offer` | `test(staff): add tests for staff panel, offer form and QR pickup` |
| I4-B | S04 | `docs/final-report` | `docs(release): add final delivery report` |

### I5 · Andrés Alvarado Lazcano (Cuentas, reservas y calidad)

| ID | Semana | Rama | Mensaje de commit |
| --- | --- | --- | --- |
| I5-01 | S01 | `docs/quality` | `docs(quality): add QUALITY.md with metrics and DORA definitions` |
| I5-02 | S01 | `docs/github-guide` | `docs(github): add beginner Git and GitHub guide for the team` |
| I5-03 | S01 | `chore/scripts` | `chore(scripts): add commit-stats.sh for per-member report` |
| I5-04 | S02 | `feature/auth-repository` | `feat(auth): add AuthRepository and session model for /api/auth` |
| I5-05 | S02 | `feature/token-storage` | `feat(storage): add secure TokenStorage and AuthInterceptor` |
| I5-06 | S02 | `feature/auth` | `feat(auth): add login and register screen` |
| I5-07 | S03 | `feature/reserve` | `feat(reservations): add reserve screen with quantity and use case` |
| I5-08 | S03 | `feature/reserve` | `feat(reservations): add reservation ready screen with QR code` |
| I5-09 | S03 | `feature/auth` | `test(auth): add tests for auth and reserve flows` |
| I5-10 | S04 | `feature/profile` | `feat(profile): add profile screen with name edit and privacy notice` |
| I5-11 | S04 | `feature/reserve` | `feat(reservations): add calendar reminder` |
| I5-12 | S04 | `feature/profile` | `test(profile): add profile widget tests` |
| I5-B | S01 | `docs/bitacora-s01` | `docs(bitacora): add weekly log S01` |

### Trabajo de administración de Jaime (no cuenta como commits)

Jaime acepta la carga extra de GitHub y de la API para que el resto del equipo solo programe y suba commits. Este trabajo se registra en la bitácora de cada semana, en la sección de PR y revisiones.

| Semana | Administración de GitHub | Cambios a la API (repo `bookia`, rama y PR propios) |
| --- | --- | --- |
| S01 | Crear BookiaMobile y `develop`, invitar colaboradores, reglas de ramas, sin squash, etiquetas, milestones, tablero, issues de S01 y S02, revisar y fusionar los PR de S01, release `v0.1.0` | API-01 Bearer, API-02 `/stores/near`, API-03 `?isbn=` (listos antes del lunes 9) |
| S02 | Issues de S03, revisiones y merges, checks obligatorios (`app-ci`, `commitlint`, `api-service`), release `v0.2.0` | API-04 `/devices` (antes del lunes 16) |
| S03 | Issues de S04, revisiones y merges, secretos de Firebase y Maps en Actions, release `v0.3.0` | API-05 `/alerts` (antes del lunes 23) |
| S04 | Revisiones y merges finales, release `v1.0.0` con APK, reporte DORA final | Ajustes de la API que surjan en las pruebas |

## 5. Cobertura de las 17 pantallas

| Pantalla | Responsable | Semana en que se cierra |
| --- | --- | --- |
| 01 Splash | Jaime de Jesús Fuentes Cruz | S02 |
| 02 Permiso de ubicación | Jaime de Jesús Fuentes Cruz | S03 |
| 03 Inicio | Elizabeth de la Cruz Ramírez | S02 (base) · S04 (cercanas y más buscados) |
| 04 Resultados | Elizabeth de la Cruz Ramírez | S02 |
| 05 Filtros | Elizabeth de la Cruz Ramírez | S03 |
| 06 Escanear ISBN | Ángel de Jesús López Temporal | S03 |
| 07 Ficha de libro | Ángel de Jesús López Temporal | S02 (base) · S04 (favorito, Avisarme, compartir) |
| 08 Mapa de librerías | Karol Hernán López Ortega | S03 |
| 09 Ficha de librería | Karol Hernán López Ortega | S02 |
| 10 Reservar | Andrés Alvarado Lazcano | S03 |
| 11 Reserva lista (código QR) | Andrés Alvarado Lazcano | S03 · S04 (recordatorio) |
| 12 Mis reservas | Ángel de Jesús López Temporal | S03 |
| 13 Notificaciones push | Jaime de Jesús Fuentes Cruz | S04 |
| 14 Login / registro | Andrés Alvarado Lazcano | S02 |
| 15 Perfil | Andrés Alvarado Lazcano | S04 |
| 16 Panel de tienda (+ escanear QR de entrega) | Karol Hernán López Ortega | S03 · S04 |
| 17 Editar oferta | Karol Hernán López Ortega | S04 |

## 6. Bitácora semanal (Word)

Archivo: `Bitacora_SNN_AAAA-MM-DD.docx` en `docs/bitacoras/`. Plantilla: `docs/bitacoras/Plantilla_Bitacora_Semanal.docx`. La redacta un integrante distinto cada semana (tabla 2), con la información que cada quien deja en sus PR. Como son 4 bitácoras y 5 integrantes, Karol redacta el informe final de entrega (27 de noviembre) para que todos tengan el mismo número de commits.

| Sección | Qué lleva | De dónde sale |
| --- | --- | --- |
| 1. Datos generales | Semana, fechas, release, redactor, enlace al tablero | Calendario |
| 2. Objetivo de la semana | Una o dos frases y pantallas comprometidas | Sección 2 de este plan |
| 3. Resumen de avance | Qué se logró y qué no, en lenguaje simple | Tablero de GitHub Projects |
| 4. Registro de commits por integrante | ID del plan, hash corto, mensaje, rama, PR, estado | `git log` / `scripts/commit-stats.sh` |
| 5. Pull requests y revisiones | PR, autor, revisor, fecha de fusión, horas abierto | Pestaña Pull requests |
| 6. Elementos de la Constitución aplicados | IDs de reglas cumplidas (ARQ, PAT, DOC, CI, VER) y evidencia | Código y workflows |
| 7. Métricas de la semana | Commits por integrante, PRs, CI en verde, cobertura, DORA | Actions, `docs/DORA.md` |
| 8. Defectos e incidentes | ID, descripción, prioridad A/M/B, estado | Issues `bug` e `incident` |
| 9. Problemas, riesgos y decisiones | Bloqueos, ADR nuevos, cambios al plan | Reunión del viernes |
| 10. Plan de la siguiente semana | Commits asignados de la tabla 4 | Este plan |
| 11. Evidencias | Capturas de pantallas, CI, release, Docker | Capturas con nombre `EV-SNN-xx` |
| 12. Firmas | Nombre y visto bueno de cada integrante | Todos |

## 7. Cómo se sustenta el trabajo de cada quien

- `scripts/commit-stats.sh` imprime commits, líneas agregadas y quitadas por autor y semana (`git shortlog -sne --no-merges --since --until` y `git log --numstat`). Su salida se pega en la sección 7 de la bitácora.
- La pestaña *Insights → Contributors* de GitHub sirve de evidencia independiente.
- Meta de equidad (Constitución EQ-01 y EQ-02): todos con 13 commits y, cada semana, 3 commits, ≥ 1 PR y ≥ 1 revisión por integrante. Si alguien se atrasa, se anota en la bitácora y se recupera la semana siguiente.
