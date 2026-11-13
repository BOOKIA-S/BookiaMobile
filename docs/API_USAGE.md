# Uso de la API de BOOKIA desde la app

> Resumen para la app Flutter. El contrato completo y vigente es `BookiaAPI/API_CONTRACT.md` (SRV-05). Si este documento y el contrato no coinciden, **manda el contrato**.
> La API no se programa en este repo (SRV-01). Si una pantalla necesita algo que no está aquí, avisa a Jaime.

## 1. Levantar la API (una vez por computadora)

Las dos carpetas van una junto a la otra:

```
mis-proyectos/
├── BookiaAPI/      ← API (repo BOOKIA-S/BookiaAPI, solo se clona)
└── BookiaMobile/   ← este repo
```

```bash
cd mis-proyectos
git clone https://github.com/BOOKIA-S/BookiaAPI.git
cd BookiaMobile
cp .env.example .env            # PowerShell: copy .env.example .env
docker compose up -d            # MongoDB 7 + API
docker compose --profile tools run --rm seed   # datos de prueba (solo la primera vez)
```

Variables de `.env` que usa la API:

| Variable | Obligatoria | Nota |
| --- | --- | --- |
| `JWT_SECRET` | Sí | Cadena larga y aleatoria |
| `ADMIN_EMAIL` | Sí (seed) | Correo de la cuenta admin que crea el seed |
| `ADMIN_PASSWORD` | Sí (seed) | Mínimo 8 caracteres |
| `JWT_EXPIRES_IN_SECONDS` | No | Por defecto 28800 (8 h) |
| `MONGODB_URI` | No | La pone `docker-compose.yml` |

Comprobación: `http://localhost:4000/api/health` responde `{"status":"ok"}`.

Traer cambios nuevos de la API:

```bash
cd ../BookiaAPI && git pull && cd ../BookiaMobile && docker compose up -d --build api
```

No ejecutes `npm install` dentro de `BookiaAPI`: Docker instala todo.

## 2. Conectar la app

La URL **nunca** va escrita en el código (COD-06); se pasa al correr la app:

| Dónde corre la app | `API_BASE_URL` |
| --- | --- |
| Emulador de Android | `http://10.0.2.2:4000/api` |
| Teléfono físico (misma Wi-Fi) | `http://<IP-de-la-PC>:4000/api` |

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api
```

```dart
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
```

Toda petición pasa por `core/network/ApiClient` (SRV-03). Las pages y controllers nunca llaman a Dio (ARQ-02).

Sesión en la app (API-01): `login` y `register` se mandan con `client: "mobile"`. La respuesta trae `token` y `expires_in` (segundos) y no pone cookie. El token se guarda en `flutter_secure_storage` (SEG-01) y `AuthInterceptor` lo manda en cada petición como `Authorization: Bearer <token>`. Un header `Authorization` mal formado recibe 401. Para cerrar sesión, la app borra el token guardado (`logout` solo limpia la cookie de la web).

## 3. Reglas del formato

- JSON en **snake_case** (`store_id`, `min_price`, `expires_at`). Los DTO usan `@JsonSerializable(fieldRename: FieldRename.snake)` (COD-02).
- Los ids vienen en `_id`: en el DTO, `@JsonKey(name: '_id') final String id;`.
- Los errores llegan como `{ "message": string, "code"?: string }` con su código HTTP.
- Cada oferta trae `is_available` (= `stock > 0`), de solo lectura.
- `min_price` es el precio más bajo **entre ofertas con existencias** (o `null`); `total_stock` es la suma de `stock`.

## 4. Endpoints que usa la app

### Públicos (sin sesión)

| Método y ruta | Pantallas | Respuesta |
| --- | --- | --- |
| `GET /health` | 01 | `{ status: "ok" }` |
| `GET /books?q=&isbn=&genre=&publisher=&store_id=&min_price=&max_price=&page=1&limit=20` | 03, 04, 05, 06 | `{ items: [Book + offers + min_price + total_stock], total, page, limit }` |
| `GET /books/filters` | 05 | `{ genres: [], publishers: [] }` |
| `GET /books/:id` | 07 | `Book + offers[{ _id, price, stock, is_available, store: Store }] + total_stock` |
| `GET /stores` | 05, 08 | `Store[]` ordenadas por nombre |
| `GET /stores/near?lat=&lng=&radius_km=5` | 03, 08, 09 | `[ { ...Store, distance_km } ]`, de la más cercana a la más lejana |
| `GET /stores/:id` | 09 | `Store + offers[{ ..., book: { _id, title, author } }]` |

- `q` busca en título, autor e ISBN. `genre` y `publisher` son coincidencia exacta. `limit` máximo 100.
- Si se manda `store_id`, `min_price` o `max_price`, los libros sin oferta que cumpla quedan fuera.
- `isbn` es búsqueda exacta (para el escáner): ignora guiones y espacios, y las formas ISBN-10 e ISBN-13 del mismo libro coinciden. Un ISBN mal formado o con dígito verificador incorrecto da 400 `Invalid isbn`.
- `Store` trae `lat` y `lng` (`null` si no se conocen). `/stores/near` usa `radius_km` 5 por defecto (máximo 50) y no lista tiendas sin coordenadas; `distance_km` es la distancia en línea recta, redondeada a 2 decimales. 400 si faltan `lat`/`lng` o están fuera de rango.

### Sesión

| Método y ruta | Pantallas | Nota |
| --- | --- | --- |
| `POST /auth/register` `{ name, email, password, client: "mobile" }` | 14 | 201 `{ user, token, expires_in }`, rol `reader`. 409 si el correo existe |
| `POST /auth/login` `{ email, password, portal?, client: "mobile" }` | 14 | `{ user, token, expires_in }`. Con `portal: "admin"` solo entran `admin` y `store_owner` (acceso staff) |
| `POST /auth/logout` | 15 | 204. En la app basta con borrar el token |
| `GET /auth/me` | 01, 15 | `{ user }` o 401 |
| `PATCH /auth/me` `{ name }` | 15 | Cambia solo el nombre |
| `PATCH /auth/password` `{ current_password, new_password }` | 15 | 8–200 caracteres |

`user` = `{ _id, email, name, role, store_id, must_change_password, created_at }`.

### Lector (`reader`)

| Método y ruta | Pantallas | Nota |
| --- | --- | --- |
| `GET /favorites` · `PUT /favorites/:bookId` · `DELETE /favorites/:bookId` | 07, 15 | Máx. 200. `store_owner` recibe 403 |
| `POST /reservations` `{ offer_id, quantity }` | 10 | 201 con estado `pendiente`. 409 sin copias suficientes; 400 con 10 reservas activas |
| `GET /reservations/mine` | 11, 12 | `{ items: Reservation[] }`, más reciente primero |
| `PATCH /reservations/:id/cancel` | 12 | 409 si ya no está activa |

### Staff (`store_owner` en su tienda, o `admin`)

| Método y ruta | Pantallas | Nota |
| --- | --- | --- |
| `GET /reservations/manage?status=&store_id=` | 16 | El encargado solo ve su tienda |
| `PATCH /reservations/:id/status` `{ status }` | 16 | Confirmar, entregar (QR) o rechazar (`cancelada`) |
| `PUT /offers/:id` `{ price, stock }` | 17 | 403 si la oferta es de otra tienda |
| `POST /offers` `{ book_id, store_id, price, stock }` | 16 | 409 si la tienda ya tiene oferta de ese libro |

## 5. Reservas: estados y reglas

| Estado en la API | Clase en la app (PAT-10) | Acciones del lector | Acciones del staff |
| --- | --- | --- | --- |
| `pendiente` | `Pending` | Cancelar | Confirmar, entregar, rechazar |
| `confirmada` | `Confirmed` | Cancelar | Entregar, rechazar |
| `entregada` | `Delivered` | — | — |
| `cancelada` | `Cancelled` | — | — |
| `vencida` | `Expired` | — | — |

- Cantidad de 1 a 5; vence 48 h después (`expires_at`). La API la marca `vencida` sola.
- Reservar descuenta el stock al instante; cancelar o vencer lo devuelve.
- La reserva trae `book { _id, title, author }` y `store { _id, name, address, phone, schedule }`.

## 6. Errores → `Failure` (ARQ-05)

| HTTP | Cuándo | `Failure` sugerido |
| --- | --- | --- |
| 400 | Validación, id mal formado, `Invalid isbn` | `ValidationFailure(message)` |
| 401 | Sin sesión, token vencido o header `Authorization` mal formado | `UnauthorizedFailure` → borrar token e ir a 14 |
| 403 | Rol sin permiso | `ForbiddenFailure` |
| 403 + `code: PASSWORD_CHANGE_REQUIRED` | Encargado creado por admin que no ha cambiado su contraseña | `PasswordChangeRequiredFailure` → cambiar contraseña |
| 404 | No existe | `NotFoundFailure` |
| 409 | Sin copias, estado no permitido, duplicado | `ConflictFailure(message)` |
| 429 | Demasiados intentos de login (20 cada 15 min) | `RateLimitFailure` |
| 500 / sin red | Error del servidor o de conexión | `ServerFailure` / `NetworkFailure` |

## 7. Ajustes pendientes en la API (los hace Jaime)

API-01 (Bearer), API-02 (`/stores/near`) y API-03 (`?isbn=`) ya están en la API y se describen en las secciones 2 y 4. Faltan estos; hasta que existan, usa la alternativa:

| ID | Cambio | Para el | Alternativa mientras tanto |
| --- | --- | --- | --- |
| API-04 | `POST /devices` (token FCM) | 16 nov | Notificaciones locales |
| API-05 | `POST/DELETE /alerts` ("Avisarme") | 23 nov | Se omite "Avisarme" |

Cuando Jaime publique cada cambio, este documento se actualiza con su ruta y respuesta exactas.

## 8. Datos de prueba

- El seed crea la cuenta **admin** (`ADMIN_EMAIL` / `ADMIN_PASSWORD`) y el catálogo de libros, librerías y ofertas.
- No crea encargados de tienda. Para probar las pantallas 16 y 17, el admin crea uno con `POST /api/users` `{ name, email, password, store_id }`. Esa cuenta entra con `must_change_password: true`.
- Las cuentas de lector se crean desde la propia app (pantalla 14).
