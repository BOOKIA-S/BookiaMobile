# Cómo contribuir a BOOKIA Móvil

Este documento resume las reglas de **ramas, commits y Pull Requests** del equipo. No reemplaza a los documentos completos:

- [docs/CONSTITUTION.md](docs/CONSTITUTION.md): reglas obligatorias (sección 6, Versionamiento y flujo de trabajo).
- [docs/GUIA_GITHUB.md](docs/GUIA_GITHUB.md): guía paso a paso de Git y GitHub.
- [docs/PLAN.md](docs/PLAN.md): qué commit le toca a cada integrante y en qué semana.
- [CLAUDE.md](CLAUDE.md): instrucciones para el Claude de cada integrante.

## Quién hace qué

| Rol | Quién | Puede | No puede |
| --- | --- | --- | --- |
| Administrador | Jaime de Jesús Fuentes Cruz | Configurar el repo, revisar, aprobar y fusionar PR, resolver conflictos, releases, tags, Docker, CI/CD y la API | Aprobar su propio PR |
| Colaborador | Elizabeth, Ángel, Karol y Andrés | Crear su rama, hacer commits, subir su rama y abrir PR hacia `develop` | Push a `main` o `develop`, fusionar PR, crear tags o releases, cambiar `.github/`, `docker/` o `docker-compose.yml` |

Los PR de Jaime los aprueba el redactor de la bitácora de esa semana. **Nadie aprueba su propio PR.**

## Ramas

Se usa GitFlow simplificado. Todo el trabajo sale de `develop` y vuelve a `develop` por Pull Request.

| Rama | Para qué | Ejemplo |
| --- | --- | --- |
| `main` | Código liberado; cada merge es un release | |
| `develop` | Integración de la semana | |
| `feature/<issue>-<slug>` | Una funcionalidad o pantalla (vida máxima: 3 días) | `feature/23-book-detail` |
| `fix/<issue>-<slug>` | Corrección no urgente | `fix/31-search-empty-state` |
| `docs/<slug>`, `chore/<slug>`, `ci/<slug>` | Documentación, mantenimiento, pipelines | `docs/contributing` |

Los nombres van en minúsculas, con guiones y en inglés. Las ramas `release/*` y `hotfix/*` las crea solo Jaime.

## Commits

Formato (Conventional Commits, **en inglés**): `tipo(alcance): descripción en imperativo`.

```bash
git commit -m "feat(books): add book detail screen with store comparison" -m "Refs #23"
```

- **Tipos:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- **Alcance:** la feature (`search`, `books`, `stores`, `staff`...) o el módulo (`core`, `network`, `docker`, `ci`).
- **Cuerpo:** `Refs #<número-del-issue>`.
- **Un solo propósito por commit**, de unas 150 líneas como máximo (sin archivos generados ni `pubspec.lock`).
- Cada commit compila y pasa las pruebas existentes.
- Haz los commits con **tu propia cuenta**: el correo de `git config user.email` debe ser el de tu cuenta de GitHub.
- Haz solo los commits que el Plan te asigna, con el mensaje que ahí aparece.

El workflow `commitlint` valida el formato en cada PR. Si marca error, corrige el mensaje con `git commit --amend -m "mensaje correcto"` (solo si aún no has hecho push).

## Pull Requests

1. **Crea el issue** de tu tarea, o usa el que Jaime te asignó. Anota su número.
2. **Parte de `develop` actualizado:**

   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b docs/10-contributing
   ```

3. **Revisa antes del commit** (en `app/`, cuando exista): `flutter analyze` sin avisos, `dart format .` y `flutter test`.
4. **Sube tu rama:** `git push -u origin <tu-rama>`.
5. **Abre el PR en GitHub** con **base `develop`** (nunca `main`):
   - El título es el mismo mensaje del commit.
   - La descripción usa la plantilla completa y lleva `Closes #<número-del-issue>`.
   - Máximo unas 400 líneas por PR.
   - Agrega una captura o GIF si cambia la interfaz.
6. **Espera la revisión de Jaime.** Si pide cambios, haz otro commit en la **misma rama** (por ejemplo `fix(...)`) y vuelve a hacer `git push`; el PR se actualiza solo.
7. **Jaime fusiona** con *Create a merge commit*. El *squash* está prohibido porque borra los commits pequeños y su autoría.
8. Cuando se fusione, limpia tu rama local: `git checkout develop && git pull origin develop && git branch -d <tu-rama>`.

## Prohibido

- `git push` directo a `main` o `develop`.
- `git push --force`.
- Fusionar PR, crear tags o releases.
- Cambiar `.github/`, `docker/` o `docker-compose.yml` sin pedírselo a Jaime.
- Subir el archivo `.env` o cualquier secreto.
- Copiar código de la API dentro de `app/` (la API vive en [imdestro1/bookia](https://github.com/imdestro1/bookia)).

## Si algo sale mal

| Situación | Qué hacer |
| --- | --- |
| `rejected ... (fetch first)` al hacer push | `git pull origin <tu-rama>` y repite `git push` |
| El PR dice **This branch has conflicts** | No lo resuelvas a ciegas: avisa a Jaime con el enlace del PR |
| Hiciste commit en `develop` por error | Antes del push: `git branch <nueva-rama>`, luego `git reset --hard origin/develop` y `git checkout <nueva-rama>` |
| Falla un check de la CI | Corre en tu equipo lo mismo que hace la CI, corrige y haz push |
| Necesitas un endpoint o campo que la API no tiene | No lo inventes: avisa a Jaime, que es quien cambia la API |
