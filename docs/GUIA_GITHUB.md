# Guía de Git y GitHub para el equipo · BOOKIA Móvil

**Versión:** 0.1 · **Fecha:** 2026-11-04

> ### 🤖 Instrucciones para tu Claude
> Si le pasas este documento a Claude, pásale también el archivo `CLAUDE.md` de la raíz del repo BookiaMobile. En resumen:
> - La API de BOOKIA **no se programa aquí**. Vive en el repo público https://github.com/imdestro1/bookia (carpeta `api/`). Se clona junto a BookiaMobile, se levanta con `docker compose up -d` y la app Flutter **solo la consume por HTTP**.
> - Tu integrante solo hace 4 cosas en GitHub: crear su rama desde `develop`, hacer commits pequeños con Conventional Commits en inglés, subir la rama con `git push` y abrir el Pull Request hacia `develop`.
> - Está prohibido hacer push a `main` o `develop`, hacer merges, crear releases o cambiar la configuración. Eso lo hace **Jaime**, el administrador, que además aprueba cada PR.
> - Ayuda paso a paso, con los comandos exactos de esta guía, y no supongas que tu integrante ya sabe Git.

## 1. Quién hace qué

| Tarea | Integrantes (Elizabeth, Ángel, Karol, Andrés y Jaime en sus pantallas) | Jaime (administrador) |
| --- | --- | --- |
| Crear la rama, hacer commits, subir la rama y abrir el PR | ✅ | ✅ |
| Aprobar Pull Requests | Solo los PR de Jaime (los revisa uno por semana, por turno) | ✅ todos los demás |
| Fusionar PR, resolver conflictos difíciles | ❌ | ✅ |
| Crear el repo, ramas protegidas, colaboradores, etiquetas, tablero, issues | ❌ | ✅ |
| GitHub Actions, Docker, secretos, releases y tags | ❌ | ✅ |
| Cambios a la API (repo `bookia`) | ❌ | ✅ |

## 2. Preparación (una sola vez, ~30 minutos)

1. **Crear la cuenta de GitHub** en https://github.com/signup y enviar el usuario a Jaime.
2. **Aceptar la invitación** al repo BookiaMobile. Llega por correo o aparece en https://github.com/notifications.
3. **Instalar:**
   - **Git:** https://git-scm.com/downloads. En Windows incluye *Git Bash*, que es la terminal que usaremos.
   - **Docker Desktop:** https://www.docker.com/products/docker-desktop. Hay que abrirlo antes de usar `docker`.
   - **Flutter**, en la versión que diga `.fvmrc`, y Android Studio con un emulador.
   - **VS Code** con las extensiones Flutter y Dart.
4. **Decirle a Git quién eres.** Usa el mismo correo de tu cuenta de GitHub; si no, tus commits no cuentan como tuyos:

   ```bash
   git config --global user.name "Nombre Apellido"
   git config --global user.email "tu-correo-de-github@ejemplo.com"
   git config --global pull.rebase false
   ```

5. **Clonar los dos repos uno junto al otro:**

   ```bash
   mkdir mis-proyectos && cd mis-proyectos
   git clone https://github.com/imdestro1/bookia.git
   git clone https://github.com/imDestro1/BookiaMobile.git
   cd BookiaMobile
   ```

   La primera vez que hagas `git push`, Windows abrirá una ventana para iniciar sesión en GitHub. Acepta.

6. **Levantar la API con Docker:**

   ```bash
   cp .env.example .env
   ```

   Llena `JWT_SECRET` y `ADMIN_PASSWORD` en `.env` y luego:

   ```bash
   docker compose up -d
   docker compose --profile tools run --rm seed
   ```

   Para comprobarlo, abre http://localhost:4000/api/health en el navegador.

## 3. El flujo de cada commit (todas las semanas)

**Paso 1. Ver tu tarea.** En GitHub, en *Projects* o *Issues*, busca el issue con tu nombre y anota su número (por ejemplo `#23`). El mensaje de commit exacto está en el Plan de commits.

**Paso 2. Ponerte al día y crear tu rama:**

```bash
git checkout develop
git pull origin develop
git checkout -b feature/23-book-detail
```

**Paso 3. Programar** (con ayuda de tu Claude) y revisar:

```bash
cd app
flutter analyze
dart format .
flutter test
cd ..
```

**Paso 4. Guardar el commit:**

```bash
git status                 # muestra qué archivos cambiaste
git add app/lib/features/books app/test/features/books
git commit -m "feat(books): add book detail screen with store comparison" -m "Refs #23"
```

**Paso 5. Subir tu rama:**

```bash
git push -u origin feature/23-book-detail
```

**Paso 6. Abrir el Pull Request:**

1. En la página del repo aparece un botón amarillo **Compare & pull request**. Dale clic.
2. Revisa que diga **base: `develop`** ← **compare: `feature/23-book-detail`**. Nunca `main`.
3. El título es el mismo que el commit. En la descripción llena la plantilla y escribe `Closes #23`.
4. Agrega una captura de la pantalla funcionando.
5. Dale clic a **Create pull request**.

**Paso 7. Esperar la revisión de Jaime.**

- Si te pide cambios, haz el ajuste en la **misma rama**, otro commit (por ejemplo `fix(books): ...`) y vuelve a correr `git push`. El PR se actualiza solo.
- Cuando Jaime lo fusione, puedes borrar tu rama local:

  ```bash
  git checkout develop
  git pull origin develop
  git branch -d feature/23-book-detail
  ```

## 4. Cómo aprobar un PR de Jaime (cuando te toque)

1. Abre el PR y entra a la pestaña **Files changed**.
2. Lee los cambios. Puedes dejar comentarios en una línea con el botón **+**.
3. Dale clic a **Review changes** → **Approve** → **Submit review**.

## 5. Problemas comunes

| Mensaje o situación | Qué hacer |
| --- | --- |
| `rejected ... (fetch first)` al hacer push | `git pull origin <tu-rama>` y repite `git push` |
| El PR dice **This branch has conflicts** | No lo arregles a ciegas: avisa a Jaime en el grupo con el enlace del PR |
| Hiciste commit en `develop` por error | Antes de hacer push: `git branch feature/<n>-<nombre>`, luego `git reset --hard origin/develop` y `git checkout feature/<n>-<nombre>` |
| Te equivocaste en el mensaje del último commit (aún sin push) | `git commit --amend -m "mensaje correcto"` |
| El check rojo **commitlint** | El mensaje no sigue el formato. Pide a tu Claude que te ayude a corregirlo y avisa a Jaime |
| El check rojo **app-ci** | Corre `flutter analyze` y `flutter test` en tu máquina, corrige y vuelve a hacer push |
| `docker: command not found` o error de conexión | Abre Docker Desktop y espera a que diga *Running* |

## 6. Lista de configuración de Jaime (administrador)

**Antes del viernes 6 de noviembre**

1. Crear el repo **BookiaMobile** en *github.com/new*, **público** (en repos privados de cuentas gratuitas no se pueden proteger ramas; con el GitHub Student Developer Pack sí). Inicializarlo con README.
2. Crear la rama `develop` desde `main`.
3. **Settings → Collaborators → Add people:** invitar a los 4 integrantes.
4. **Settings → General → Pull Requests:**
   - dejar solo **Allow merge commits**;
   - desmarcar *squash* y *rebase*;
   - activar **Automatically delete head branches**.
5. **Settings → Rules → Rulesets → New branch ruleset** para `main` y `develop`:
   - *Restrict deletions*;
   - *Require a pull request before merging* con 1 aprobación;
   - *Require status checks to pass* (agregar `app-ci` y `commitlint` cuando existan);
   - *Block force pushes*.
6. **Issues → Labels:** `type:feat`, `type:fix`, `type:docs`, `area:app`, `area:devops`, `screen:01`…`screen:17`, `prio:A/M/B`, `incident`.
7. **Issues → Milestones:** `S01` (6 nov), `S02` (13 nov), `S03` (20 nov), `S04` (27 nov).
8. **Projects → New project → Board** "BOOKIA Móvil" con las columnas *Por hacer, En progreso, En revisión, Hecho*.
9. Crear los issues de S01 (uno por commit del Plan), asignados a cada integrante.
10. Subir tus 3 commits de S01, que incluyen `CLAUDE.md`, las plantillas, commitlint y el `docker-compose.yml`.

**Cada semana**

- **Lunes:** crear y asignar los issues de la semana.
- **Lunes a jueves:** revisar y fusionar PR con *Create a merge commit*, y resolver conflictos.
- **Viernes:**
  1. crear `release/vX.Y.Z` desde `develop`;
  2. abrir el PR a `main` y fusionarlo;
  3. crear el tag y el release (*Releases → Draft a new release*);
  4. correr `scripts/commit-stats.sh`;
  5. entregarle los números al redactor de la bitácora.
- **API:** los cambios API-01 a API-05 se hacen en el repo `bookia`, en su propia rama y PR:
  - Bearer, `?isbn=` y `/stores/near`, antes del lunes 9 de noviembre;
  - `/devices`, antes del 16;
  - `/alerts`, antes del 23.

**Acceso al repo de la API:** `imdestro1/bookia` es **público**, así que los integrantes **no necesitan permisos** para clonarlo y usarlo. No hace falta invitarlos. Si algún día lo haces privado, tendrías que invitarlos como colaboradores, y en un repo personal eso les da permiso de escritura, no solo de lectura.
