<!-- Título del PR en Conventional Commits, en inglés. Ej.: feat(books): add book detail screen -->

## Qué cambia

<!-- Una o dos frases en español. -->

Closes #<!-- número del issue -->

**ID del Plan:** <!-- ej. I3-05 (docs/PLAN.md, tabla 4) -->
**Pantalla(s):** <!-- ej. 07 Ficha de libro, o "no aplica" -->

## Evidencia

<!-- Captura o GIF de la pantalla (obligatorio si cambia la UI), o salida de la prueba/comando. -->

## Lista de revisión (docs/CONSTITUTION.md)

- [ ] Commits pequeños en Conventional Commits, con mi propia cuenta (VER-01, VER-02, VER-03)
- [ ] `flutter analyze` sin avisos y `dart format .` aplicado (COD-04)
- [ ] `flutter test` en verde y pruebas nuevas de lo que agregué (PRU-01, PRU-02)
- [ ] `domain/` no importa Flutter, Dio, Hive ni `data/` (ARQ-01)
- [ ] La vista no llama a Dio ni a un datasource (ARQ-02); errores como `Failure` (ARQ-05)
- [ ] Ningún archivo pasa de 300 líneas (ARQ-06)
- [ ] Sin secretos ni `.env` en el PR (COD-06, DOC-04)
- [ ] No toqué `.github/`, `docker/` ni `docker-compose.yml` (salvo que sea un PR de Jaime)
- [ ] Patrón(es) aplicados y su archivo: <!-- ej. PAT-01 Repository → lib/features/books/... -->

## Para la bitácora

<!-- 3 líneas: qué se hizo, ID del Plan y commits. -->
