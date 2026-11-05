# CLAUDE.md · BookiaMobile

> Este archivo vive en la **raíz del repositorio BookiaMobile**. Claude Code lo lee automáticamente al abrir el proyecto. Si usas Claude en el navegador o en la app, pega este archivo completo al inicio de la conversación.

## 1. Qué es este proyecto

BOOKIA Móvil es una app **Flutter** (Android e iOS) hecha por un equipo de 5 estudiantes para la materia Desarrollo de Aplicaciones Móviles 2 (TecNM Huauchinango). La app muestra qué librerías y papelerías de Huauchinango, Puebla tienen cada libro, a qué precio y con cuántas existencias, y permite apartarlo para recogerlo en la tienda. La entrega final es el **27 de noviembre de 2026**. El docente evalúa la **calidad del resultado y el uso correcto de las tecnologías** (arquitectura, patrones, Git/GitHub, Docker, CI/CD, bitácoras), no solo el código.

| Integrante | Rol | Pantallas |
| --- | --- | --- |
| Jaime de Jesús Fuentes Cruz | **Administrador de GitHub**, Docker, CI/CD y dueño de la API | 01, 02, 13 |
| Elizabeth de la Cruz Ramírez | Core de la app y búsqueda | 03, 04, 05 |
| Ángel de Jesús López Temporal | Libros, escáner y documentación técnica | 06, 07, 12 |
| Karol Hernán López Ortega | Librerías, mapa y panel de tienda | 08, 09, 16, 17 |
| Andrés Alvarado Lazcano | Cuentas, reservas y calidad | 10, 11, 14, 15 |

## 2. La API de BOOKIA: un servicio aparte que solo se consume

- La API **ya existe** y **no se programa en este repo**. Vive en **https://github.com/imdestro1/bookia**, en la carpeta `api/` (Express + MongoDB). El repo es público, así que cualquiera puede clonarlo.
- Se corre como **servicio independiente en Docker**. La app Flutter solo la consume por HTTP. **Nunca copies código de la API dentro de `app/`** y no modifiques la carpeta `bookia/`.
- Si una pantalla necesita un endpoint o un campo que la API no tiene, **no lo inventes**: detente y dile a tu integrante que avise a Jaime. Él cambia la API en su repo.
- El contrato completo de la API (rutas, campos, errores) está en `bookia/api/API_CONTRACT.md`, y su resumen para la app en `docs/API_USAGE.md`.

### Cómo levantar la API (una sola vez por computadora)

Las dos carpetas deben quedar **una junto a la otra**:

```
mis-proyectos/
├── bookia/         ← API (repo de Jaime, solo se clona y se usa)
└── BookiaMobile/   ← este repo (app Flutter, Docker, docs)
```

```bash
cd mis-proyectos
git clone https://github.com/imdestro1/bookia.git
git clone https://github.com/imDestro1/BookiaMobile.git
cd BookiaMobile
cp .env.example .env          # en Windows PowerShell: copy .env.example .env
# Escribe en .env un JWT_SECRET largo y un ADMIN_PASSWORD
docker compose up -d          # levanta MongoDB + API
docker compose --profile tools run --rm seed   # carga los datos de prueba (solo la primera vez)
```

Para comprobar que funciona, abre `http://localhost:4000/api/health` y debe responder `{"status":"ok"}`.

- **Emulador de Android:** la app usa `http://10.0.2.2:4000/api`.
- **Teléfono físico (misma red Wi-Fi):** la app usa `http://<IP-de-la-PC>:4000/api`.
- La URL se pasa al correr la app: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api`.
- No ejecutes `npm install` dentro de `bookia/api`: Docker instala todo.
- Para traer cambios nuevos de la API: `cd ../bookia && git pull && cd ../BookiaMobile && docker compose up -d --build api`.

## 3. Reglas de código (resumen de `docs/CONSTITUTION.md`)

- **Arquitectura:** Clean Architecture *feature-first* con MVVM y Riverpod.
  - `app/lib/features/<feature>/data` contiene los DTO, los *datasources* y la implementación de los repositorios.
  - `app/lib/features/<feature>/domain` contiene las entidades, las interfaces de repositorio y los casos de uso. **No importa** Flutter, Dio ni nada de `data/`.
  - `app/lib/features/<feature>/presentation` contiene las pages, los widgets y los controllers (Notifier de Riverpod).
  - Lo compartido va en `app/lib/core/` (red, almacenamiento, ubicación, errores, widgets).
- **Patrones obligatorios** (cada uno en su lugar, ver la sección 4 de la Constitución): Repository, MVVM, Provider/DI, Singleton, Factory (`fromJson`), Observer, Adapter (mappers), Chain of Responsibility (interceptores de Dio), Strategy (orden de resultados), State (estados de reserva) y Facade (ubicación, push).
- **Paquetes aprobados:** `flutter_riverpod`, `go_router`, `dio`, `freezed`, `json_serializable`, `flutter_secure_storage`, `hive_ce`, `google_maps_flutter`, `geolocator`, `permission_handler`, `mobile_scanner`, `qr_flutter`, `firebase_messaging`, `firebase_crashlytics`, `url_launcher`, `intl`, `mocktail`. Para cualquier otro paquete hay que preguntar antes.
- **Nombres:** clases en `UpperCamelCase`, variables en `lowerCamelCase`, archivos en `snake_case.dart`. El código y los commits van en inglés, y los textos de pantalla en español.
- **Límites:** ningún archivo pasa de 300 líneas. `flutter analyze` debe quedar sin avisos y `dart format .` aplicado.
- **Pruebas:** cada commit de `feat` trae o va seguido de su prueba. La cobertura debe ser de al menos 70 % en `domain/` y `data/`.
- **Seguridad:** el token se guarda solo en `flutter_secure_storage`. Nada de secretos en el código.

## 4. Cómo trabajar con Git y GitHub

**Tú solo haces 4 cosas: crear tu rama, hacer commits, subir tu rama y abrir el Pull Request.** Todo lo demás (aprobar, fusionar, resolver conflictos difíciles, releases, configuración) lo hace **Jaime**.

```bash
git checkout develop
git pull origin develop
git checkout -b feature/<numero-de-issue>-<nombre-corto>   # ej. feature/23-book-detail
# ... programa ...
git add <archivos>
git commit -m "feat(books): add book detail screen with store comparison" -m "Refs #23"
git push -u origin feature/23-book-detail
# Abre el Pull Request en GitHub hacia develop y pon "Closes #23" en la descripción
```

- **Formato de commit (Conventional Commits, en inglés):** `tipo(alcance): descripción`. Los tipos son `feat`, `fix`, `test`, `docs`, `refactor`, `style`, `chore`, `build`, `ci` y `perf`. El alcance es la *feature*, por ejemplo `books`, `stores`, `auth` o `search`.
- **Commits pequeños y completos:** cada commit tiene un solo propósito, compila y trae sus pruebas.
- **Haz solo los commits asignados a tu integrante** en `docs/PLAN.md`, con el mensaje que ahí aparece, en la semana que corresponde.
- **PROHIBIDO:**
  - hacer `git push` a `main` o a `develop`;
  - hacer `git push --force`;
  - fusionar Pull Requests;
  - crear tags o releases;
  - cambiar `.github/`, `docker-compose.yml` o `docker/` sin pedírselo a Jaime;
  - subir el archivo `.env`.
- Si `git push` o un PR marca un **conflicto**, no lo resuelvas a ciegas: avisa a Jaime.
- Antes de hacer el commit, ejecuta `flutter analyze`, `dart format .` y `flutter test`.

## 5. Cómo debe ayudar Claude

1. Antes de escribir código, pregunta o confirma **qué integrante eres** y **qué commit del Plan** vas a hacer.
2. Propón primero los archivos a crear o cambiar, respetando las carpetas de la sección 3.
3. Escribe el código **y** sus pruebas, y muestra los comandos exactos de Git de la sección 4 con el mensaje de commit del Plan.
4. No toques la API, ni la configuración de GitHub, ni Docker. Si hace falta algo de eso, redacta el mensaje para Jaime.
5. Al terminar, deja un resumen de 3 líneas para la bitácora semanal: qué se hizo, el commit y el número de PR.
