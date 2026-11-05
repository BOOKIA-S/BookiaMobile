# BOOKIA Móvil

App **Flutter** (Android e iOS) que muestra qué librerías y papelerías de Huauchinango, Puebla tienen cada libro, a qué precio y con cuántas existencias, y permite apartarlo para recogerlo en la tienda.

Proyecto de equipo de la materia **Desarrollo de Aplicaciones Móviles 2**. Entrega final: **27 de noviembre de 2026**.

| Integrante | Rol |
| --- | --- |
| Jaime de Jesús Fuentes Cruz | Administrador de GitHub, Docker, CI/CD y API |
| Elizabeth de la Cruz Ramírez | Core de la app y búsqueda |
| Ángel de Jesús López Temporal | Libros, escáner y documentación técnica |
| Karol Hernán López Ortega | Librerías, mapa y panel de tienda |
| Andrés Alvarado Lazcano | Cuentas, reservas y calidad |

## La API

La app consume la API REST de BOOKIA (Express + MongoDB), que vive en su propio repo público: [imdestro1/bookia](https://github.com/imdestro1/bookia). No se copia aquí: se clona en `../bookia` y se levanta con Docker desde este repo.

```
mis-proyectos/
├── bookia/         ← API (solo se clona)
└── BookiaMobile/   ← este repo
```

## Puesta en marcha

Guía para dejar listo tu equipo, una sola vez. Los comandos se escriben tal cual; en Windows usa **Git Bash** (viene con Git).

### 1. Herramientas necesarias

| Herramienta | Para qué | Dónde obtenerla |
| --- | --- | --- |
| Git | Control de versiones | [git-scm.com/downloads](https://git-scm.com/downloads) |
| Docker Desktop | Levanta MongoDB y la API | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop) |
| Flutter (versión de `.fvmrc`) | Compilar la app | [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) |
| FVM | Usar la misma versión de Flutter que el equipo | [fvm.app](https://fvm.app) |
| Android Studio + emulador | Probar la app en Android | [developer.android.com/studio](https://developer.android.com/studio) |
| VS Code con extensiones Flutter y Dart | Editor | [code.visualstudio.com](https://code.visualstudio.com) |

Docker Desktop debe estar **abierto y en estado Running** antes de usar `docker`.

### 2. Clonar los dos repositorios

Las carpetas `bookia` y `BookiaMobile` deben quedar **una junto a la otra**:

```bash
mkdir mis-proyectos && cd mis-proyectos
git clone https://github.com/imdestro1/bookia.git
git clone https://github.com/BOOKIA-S/BookiaMobile.git
cd BookiaMobile
git checkout develop
```

Antes de tu primer commit, configura tu identidad con el **mismo correo de tu cuenta de GitHub**:

```bash
git config user.name "Nombre Apellido"
git config user.email "tu-correo-de-github@ejemplo.com"
```

### 3. Instalar la versión fijada de Flutter

La versión exacta de Flutter se fija en `.fvmrc` (regla TEC-02). Cuando el archivo exista en `app/`:

```bash
cd app
fvm install
fvm flutter --version
flutter doctor     # revisa que Android Studio y el emulador estén detectados
```

### 4. Levantar la API con Docker

```bash
cp .env.example .env          # en PowerShell: copy .env.example .env
```

Abre `.env` y llena las variables obligatorias. **Nunca subas `.env` al repositorio.**

| Variable | ¿Obligatoria? | Qué poner |
| --- | --- | --- |
| `JWT_SECRET` | Sí | Cadena larga y aleatoria. En Git Bash: `openssl rand -hex 48` |
| `ADMIN_PASSWORD` | Sí | Contraseña del admin, mínimo 8 caracteres |
| `ADMIN_EMAIL` | Sí (ya viene llena) | Correo del admin; por defecto `admin@bookia.local` |
| `JWT_EXPIRES_IN_SECONDS`, `BCRYPT_SALT_ROUNDS`, `CLIENT_URL` | No | Déjalas como vienen |
| `BOOKIA_API_PATH` | No | Solo si el build no encuentra la carpeta `api/` de `bookia` |

```bash
docker compose up -d          # levanta MongoDB + API
```

Comprueba que funciona abriendo `http://localhost:4000/api/health`; debe responder `{"status":"ok"}`.

#### Datos de prueba (seed)

Con la API arriba, carga el catálogo de prueba:

```bash
docker compose --profile tools run --rm seed
```

El seed crea la cuenta **admin** (`ADMIN_EMAIL` / `ADMIN_PASSWORD`) y deja libros, librerías y ofertas de ejemplo. Se corre **solo la primera vez**: si lo repites, reemplaza el catálogo completo y borra las cuentas de encargado de tienda. Si falla con `Missing required environment variables`, revisa que `.env` tenga `ADMIN_PASSWORD` llena.

Para traer cambios nuevos de la API:

```bash
cd ../bookia && git pull && cd ../BookiaMobile
docker compose up -d --build api
```

No ejecutes `npm install` dentro de `bookia/api`: Docker instala todo.

### 5. Correr la app

La URL de la API se pasa al ejecutar, nunca se escribe en el código:

| Dónde corre la app | `API_BASE_URL` |
| --- | --- |
| Emulador de Android | `http://10.0.2.2:4000/api` |
| Teléfono físico (misma red Wi-Fi) | `http://<IP-de-la-PC>:4000/api` |

```bash
cd app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api
```

### 6. Antes de cada commit

```bash
cd app
flutter analyze        # debe quedar sin avisos
dart format .
flutter test
```

Las reglas de ramas, commits y Pull Requests están en [docs/GUIA_GITHUB.md](docs/GUIA_GITHUB.md).

### Problemas comunes

| Situación | Qué hacer |
| --- | --- |
| `docker: command not found` o error de conexión | Abre Docker Desktop y espera a que diga Running |
| `/api/health` no responde | Revisa con `docker compose ps` que `mongo` y `api` estén `healthy`, y que `bookia` esté junto a `BookiaMobile` |
| La app no llega a la API en el emulador | Usa `10.0.2.2`, no `localhost` |

## Documentación

| Documento | Para qué |
| --- | --- |
| [CLAUDE.md](CLAUDE.md) | Instrucciones para el Claude de cada integrante. Léelo primero |
| [docs/CONSTITUTION.md](docs/CONSTITUTION.md) | Reglas obligatorias del proyecto (arquitectura, patrones, Git, Docker, CI/CD, métricas) |
| [docs/PLAN.md](docs/PLAN.md) | Calendario, reparto de commits por integrante y bitácoras semanales |
| [docs/GUIA_GITHUB.md](docs/GUIA_GITHUB.md) | Guía paso a paso de Git y GitHub para el equipo |
| [docs/bitacoras/](docs/bitacoras/) | Plantilla y bitácoras semanales en Word |
| [docs/word/](docs/word/) | Copias en Word de la Constitución, el Plan y la Guía (la versión vigente es la `.md`) |

## Licencia

[MIT](LICENSE).
