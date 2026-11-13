# Plan de calidad y métricas — BOOKIA Móvil

**Tarea:** I5-01 · S01 · **Responsable:** Andrés Alvarado Lazcano · **Fecha:** 2026-11-05
**Estado:** plan inicial; las metas son compromisos, no resultados medidos.

## 1. Objetivo, alcance y responsables

Este plan aplica las reglas de `docs/CONSTITUTION.md` a la app Flutter (Android e iOS), su consumo HTTP de la API externa, las pruebas, la seguridad, el rendimiento, la CI/CD, las entregas y la equidad del equipo. No modifica ni certifica la API del repositorio `bookia`: sus pruebas y mediciones corresponden a ese repositorio.

Cada integrante aporta pruebas, criterios de aceptación y evidencia en sus PR; quien redacta la bitácora semanal consolida los resultados. Andrés mantiene este plan y da seguimiento a calidad y contribuciones. Jaime administra GitHub, Docker, CI/CD, releases y los cambios a la API en su repositorio; revisa y fusiona los PR de los colaboradores. Los PR de Jaime los revisa un colaborador por turno. Nadie aprueba su propio PR (`docs/PLAN.md`, secciones 1, 2 y 6).

## 2. Métricas DORA: definición y registro

Se mide semanalmente, con corte en el release del viernes. **Despliegue** significa un GitHub Release publicado desde `main` con APK e imágenes Docker (Constitución, sección 8); un merge, un tag sin artefactos o un servicio local no cuentan. La suposición S-3 de la Constitución, que define el alcance de este despliegue, sigue pendiente de confirmación.

| Métrica | Definición operativa y fórmula | Meta | Fuente de evidencia | Frecuencia |
| --- | --- | --- | --- | --- |
| Frecuencia de despliegue | Número de releases que cumplen la definición anterior, publicados en la semana. | ≥ 1 por semana | GitHub Releases, tag en `main`, APK e imágenes del release | Semanal |
| Tiempo de entrega de cambios | Para cada PR incluido en un release: fecha/hora de publicación del release menos fecha/hora de su primer commit; reportar la **mediana** de esos intervalos en días. | < 7 días; meta interna: PR abierto → fusionado en < 48 h | Historial de commits, PR fusionados y fecha del GitHub Release | Semanal, por PR incluidos en releases de la semana |
| Tasa de fallo de cambios | Releases de la semana que necesitaron `hotfix/*` o `revert` ÷ total de releases de la semana × 100; cada release afectado cuenta una vez. | ≤ 15 % | GitHub Releases, PR/commits de hotfix o revert e issues vinculados | Semanal; actualizar si un fallo se conoce después del corte |
| Tiempo de recuperación (MTTR) | Para cada issue `incident` cerrado en la semana: fecha/hora de cierre menos fecha/hora de apertura; reportar la **media aritmética** de esas duraciones, en horas. | < 24 h | Fechas de apertura/cierre de GitHub Issues `incident` y enlace a la corrección | Semanal; reportar por separado incidentes aún abiertos |

Si no hay releases en la semana, la tasa de fallo y el tiempo de entrega quedan **no calculables**, no en 0 %. Si no hay incidentes cerrados, el MTTR queda **no calculable**, no en 0 h. Vincular cada incidente a su release y corrección; no inferir un incidente por la mera existencia de un `fix`. Los resultados y sus fuentes se registrarán en `docs/DORA.md` cuando exista y se resumirán en la bitácora.

**Resultado real al 2026-11-05:** no se han verificado releases, ejecuciones de pipelines ni mediciones DORA en esta auditoría; no se atribuye valor a ninguna de las cuatro métricas. `docs/DORA.md` y el workflow `dora.yml` no existen aún (I1-11 está planificado para S04).

## 3. Métricas de calidad (Constitución, CAL-01 a CAL-12)

Estas son **metas**, no valores observados. Al cerrar la semana, registrar para cada ID resultado, periodo, evidencia y estado (cumple / no cumple / no medido / no calculable); si falta la herramienta, consignar el motivo y responsable. No sustituir la ausencia de datos por cero.

| ID | Qué se comprueba y meta literal | Herramienta y evidencia prevista |
| --- | --- | --- |
| CAL-01 | Cobertura de pruebas de la app: ≥ 70 % de líneas en `domain/` y `data/`. | `flutter test --coverage` + `lcov`; calcular sobre esos directorios y adjuntar reporte. |
| CAL-02 | Cobertura de pruebas del backend: ≥ 70 % (el MVP terminó en 99.5 %; **no** es una medición actual). | Jest en el repositorio externo `bookia`; Jaime aporta resultado verificable. |
| CAL-03 | Avisos del analizador: 0. | `flutter analyze` y ESLint de la API; salidas de cada proyecto. Además COD-04 exige 0 errores y 0 warnings en Flutter. |
| CAL-04 | Tamaño de archivo: ≤ 300 líneas. | Revisión en PR + script cuando exista; anotar rutas que incumplan. |
| CAL-05 | Latencia de la API: p95 < 200 ms. | autocannon contra el contenedor; Jaime aporta condiciones de medición y resultado. |
| CAL-06 | Arranque en frío de la app: < 3 s en Android de gama media. | `flutter run --profile` + DevTools; anotar dispositivo y versión. |
| CAL-07 | Sesiones sin fallos: ≥ 99 %. | Firebase Crashlytics; periodo y sesiones observadas cuando esté integrado. |
| CAL-08 | Tasa de éxito de la CI: ≥ 90 % de corridas en verde por semana. | Historial de GitHub Actions; corridas verdes ÷ corridas totales × 100. |
| CAL-09 | Defectos abiertos de prioridad A: 0 al cerrar cada semana. | Issues `bug` + `prio:A`; verificar la etiqueta además de la prioridad elegida en el formulario. |
| CAL-10 | Cumplimiento de criterios de aceptación: 100 % de las pantallas de la semana. | Auditoría con el formato del MVP: Requisito, Criterio, Prueba, Resultado, Evidencia, Defecto, Prioridad. |
| CAL-11 | Accesibilidad: áreas táctiles y contraste según COD-09. | Accessibility Scanner / revisión: áreas ≥ 48 dp, contraste AA y `Semantics` en íconos sin texto. |
| CAL-12 | Vulnerabilidades altas o críticas: 0. | Dependabot y `npm audit`; conservar alertas y salida de auditoría. |

**Resultado real:** ninguna de estas 12 métricas se midió en esta auditoría de solo lectura. La presencia de un archivo o plantilla no demuestra cumplimiento de su meta.

## 4. Pruebas, controles y aceptación

- **PRU-01:** pruebas unitarias de casos de uso, mappers, controladores Riverpod, validador de ISBN y estados de reserva. **PRU-02:** pruebas de widget para cada pantalla en carga, vacío, error y con datos. **PRU-03:** pruebas en `integration_test/` de buscar → ficha → librería y login → reservar → mis reservas. **PRU-04:** Jaime verifica Jest + Supertest por cada endpoint nuevo API-01 a API-05 en el repo de la API. **PRU-05:** hoja de auditoría por entrega, con evidencia por caso.
- En PR con código Flutter, ejecutar desde `app/` `dart format .`, `flutter analyze` y `flutter test`; verificar formato sin cambios (`dart format --set-exit-if-changed .`) y cobertura (`flutter test --coverage` + `lcov`) antes de declarar CAL-01. En revisión comprobar `test/architecture_test.dart` para ARQ-01 cuando exista, dependencias entre capas ARQ-01 a ARQ-05, el límite ARQ-06, patrones aplicados con su ruta, nombres COD-01 a COD-03 y ausencia de `print()` (COD-08). No ejecutar estos comandos cuando no existe `app/`.
- Revisar seguridad antes de integrar: ningún secreto en repo ni `.env` versionado (COD-06, DOC-04); JWT solo en `flutter_secure_storage` (SEG-01); HTTPS fuera del entorno local (SEG-02), ubicación no enviada ni almacenada en el servidor (SEG-04) y aviso de privacidad accesible desde Perfil (SEG-05). **No dar por cumplida SEG-04** hasta resolver la contradicción con `GET /api/stores/near?lat&lng` (véase más abajo). Los controles del backend SEG-03 se verifican en su repositorio con Jaime. Revisar accesibilidad COD-09 con cada pantalla.
- La definición de terminado de la sección 11 exige: PR aprobado y fusionado en `develop`, CI verde, pruebas de la tarea, criterios del issue cumplidos, captura o GIF si hay pantalla y fila en la bitácora semanal. Los checks obligatorios `app-ci`, `api-service` y `commitlint` deben pasar cuando estén configurados; no se desactivan para aprobar un PR (CI-01 a CI-03). Un pipeline roto en `develop` se prioriza antes de otro trabajo. Para I5-01, adjuntar el documento y la evidencia de revisión; no presentar pruebas de app inexistente como aprobadas.

## 5. Equidad, defectos y evidencias

| ID | Meta de la Constitución | Verificación y tratamiento |
| --- | --- | --- |
| EQ-01 | Mismo número para todos: 12 commits de trabajo + 1 de bitácora o informe (**13**). | Comparar historial por autor con IDs de `docs/PLAN.md` y la salida de `scripts/commit-stats.sh` cuando exista; no contar merges como contribuciones individuales. |
| EQ-02 | Cada integrante: **3 commits, ≥ 1 PR propio y ≥ 1 revisión a otro integrante por semana**. | Contrastar commits, PR y revisiones en GitHub; registrar desfases y recuperación en la siguiente bitácora. |

Por cada defecto: abrir issue `bug`, anotar pasos, resultado esperado, dispositivo, prioridad A/M/B, pantalla/criterio y evidencia; asociar PR correctivo, responsable y fecha de verificación. Para CAL-09, confirmar `prio:A` explícitamente: el formulario `bug.yml` solicita prioridad, pero solo asigna automáticamente `type:bug`. Los fallos de release se registran además como `incident` con release afectado, horas de apertura/cierre y hotfix/revert si procede. Jaime coordina los incidentes y cambios de API; el dueño de la pantalla corrige y aporta la prueba de regresión; el redactor semanal registra pendientes y acciones correctivas. Un defecto A abierto al corte impide declarar cumplida CAL-09.

Evidencias: enlazar issue → PR → commit → prueba/captura o salida → verificación → release, según aplique. Conservar informes de cobertura, resultados de Actions, auditoría de aceptación y capturas identificadas como `EV-SNN-xx` en la bitácora Word (`docs/PLAN.md`, sección 6). Si una meta falla, registrar ID, valor observado o «no medido», causa, acción, responsable y próxima revisión; nunca inventar resultados.

## 6. Seguimiento semanal y estado verificado

Durante cada semana cada autor deja criterios, pruebas y evidencia en su PR; Jaime revisa y fusiona. En el corte del jueves (S04: miércoles 25), el redactor reúne incidencias, pruebas y estado de CAL/EQ. El viernes Jaime registra el release si se publica y entrega enlaces y estadísticas; el redactor incorpora DORA, CAL, EQ, decisiones, defectos y evidencias en `docs/bitacoras/Bitacora_SNN_AAAA-MM-DD.docx`. `docs/DORA.md` será el registro de cálculos y fuentes DORA, no el sustituto de la bitácora. Si no existe aún, registrar «pendiente de implementación» y las fuentes disponibles, sin fingir un resultado.

**Estado observado en este repositorio el 2026-11-05 (inspección de archivos; no se ejecutaron pruebas ni CI):**

| Componente | Estado comprobado / pendiente |
| --- | --- |
| Documentación y colaboración | En `origin/develop` existen `docs/CONSTITUTION.md`, `docs/PLAN.md`, la guía GitHub (introducida por Jaime), la plantilla y un borrador S01 `.docx`; hay plantillas de issues/PR, `CODEOWNERS`, Dependabot para GitHub Actions y `commitlint.yml`. Su presencia no verifica aprobaciones, protección de ramas ni éxito de CI. |
| App y pruebas | En `origin/develop` aún no existen `app/`, `.fvmrc`, `test/` ni `integration_test/`; hay ramas remotas de app pendientes de integración. Implementación de arquitectura, cobertura, rendimiento, Crashlytics y accesibilidad no se han verificado aquí. |
| API y Docker | La API está en su repositorio externo, sin auditar aquí. En `origin/develop` existen `docker-compose.yml`, `docker/api/Dockerfile` y `.env.example`; falta `docker/Dockerfile.flutter-ci`. No se comprobó que compose levante servicios ni que el endpoint de salud responda. |
| Scripts, CI y DORA | No existen `scripts/commit-stats.sh`, `scripts/dora.sh`, `docs/DORA.md` ni workflows `app-ci.yml`, `api-service.yml`, `dora.yml` o `release.yml`; solo está `commitlint.yml`, sin resultado verificado. Las mediciones quedan pendientes. |

**Discrepancia de planificación a resolver con Jaime:** S01 prevé `v0.1.0` (6 de noviembre), pero el APK requiere una app aún ausente; el pipeline de release está previsto para S03 (I1-09) y el workflow DORA para S04 (I1-11). La meta de un release semanal no demuestra que exista un despliegue DORA válido: solo contabilizar el release si cumple la definición con artefactos, o documentar el incumplimiento y la acción acordada. También queda pendiente confirmar el supuesto S-3 antes de cambiar el alcance de «despliegue».

**Contradicción de seguridad a resolver con Jaime:** SEG-04 prohíbe enviar la ubicación al servidor; OBJ-02 y API-02 prevén `GET /api/stores/near?lat&lng`, que transmite coordenadas a la API. La Constitución no resuelve esta incompatibilidad: documentar la decisión antes de declarar conforme la función de tiendas cercanas, sin cambiar aquí la regla ni el contrato.

**Fuentes rectoras:** `docs/CONSTITUTION.md` (secciones 3, 5, 8 a 11), `docs/PLAN.md` (calendario, I5-01 y bitácoras) y `docs/GUIA_GITHUB.md` (flujo de PR). No sustituir sus identificadores ni sus metas por este documento.
