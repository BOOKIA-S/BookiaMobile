# SPECS · BOOKIA Móvil

> Especificación funcional de las 17 pantallas de la propuesta aprobada (`BOOKIA_Movil_Propuesta.pdf`, mockups para iPhone 17, 402 × 874 pt).
> Endpoints detallados en `docs/API_USAGE.md`; reglas del proyecto en `docs/CONSTITUTION.md`.

## 1. Usuarios

| Perfil | Rol en la API | Qué hace en la app |
| --- | --- | --- |
| Visitante | sin sesión | Busca, escanea, ve fichas y mapa. No necesita cuenta |
| Lector | `reader` | Lo anterior + reservar, favoritos, "Avisarme" y perfil |
| Encargado de tienda | `store_owner` | Confirma o rechaza reservas, entrega con QR y edita precio y stock **de su tienda** |
| Administrador | `admin` | Igual que el encargado, en todas las tiendas |

## 2. Navegación

- Barra inferior en las pantallas públicas: **Inicio (03) · Buscar (04) · Mapa (08) · Reservas (12) · Perfil (15)**.
- `01 Splash` → `02 Permiso` (primera vez) → `03 Inicio`.
- `03` → buscar → `04` → filtrar `05` · tocar libro → `07`. Ícono ISBN → `06` → ISBN detectado → `07`.
- `07` → tocar librería → `09` · Reservar → (sin sesión `14`) → `10` → confirmar → `11` → `12`.
- `08` → tocar pin → `09`. `13` (push) → abrir aviso → `12` o `07`.
- Zona staff: `14` "Acceso staff" → `16 Panel de tienda` → `17 Editar oferta`.
- Las rutas que requieren lector (10, 11, 12, 15) redirigen a 14 si no hay sesión (guard de `go_router`).

## 3. Pantallas

Cada pantalla cumple PRU-02: estados de **carga, vacío, error y con datos**. Textos en español (es-MX); precios en MXN con `intl` (`$75.00`).

| # | Pantalla | Responsable | Semana | Endpoints |
| --- | --- | --- | --- | --- |
| 01 | Splash | Jaime | S02 | `GET /auth/me` |
| 02 | Permiso de ubicación | Jaime | S03 | — (`geolocator`, `permission_handler`) |
| 03 | Inicio | Elizabeth | S02 · S04 | `GET /books`, `GET /books/filters`, `GET /stores/near`* |
| 04 | Resultados | Elizabeth | S02 | `GET /books?q=...&page=` |
| 05 | Filtros | Elizabeth | S03 | `GET /books/filters`, `GET /stores` |
| 06 | Escanear ISBN | Ángel | S03 | `GET /books?isbn=`* |
| 07 | Ficha de libro | Ángel | S02 · S04 | `GET /books/:id`, `/favorites`, `/alerts`* |
| 08 | Mapa de librerías | Karol | S03 | `GET /stores/near`* |
| 09 | Ficha de librería | Karol | S02 | `GET /stores/:id` |
| 10 | Reservar | Andrés | S03 | `POST /reservations` |
| 11 | Reserva lista (QR) | Andrés | S03 · S04 | `GET /reservations/mine` |
| 12 | Mis reservas | Ángel | S03 | `GET /reservations/mine`, `PATCH /reservations/:id/cancel` |
| 13 | Notificaciones push | Jaime | S04 | `POST /devices`* |
| 14 | Login / registro | Andrés | S02 | `POST /auth/login`, `POST /auth/register` |
| 15 | Perfil | Andrés | S04 | `GET/PATCH /auth/me`, `PATCH /auth/password`, `POST /auth/logout` |
| 16 | Panel de tienda | Karol | S03 · S04 | `GET /reservations/manage`, `PATCH /reservations/:id/status`, `GET /stores/:id` |
| 17 | Editar oferta | Karol | S04 | `PUT /offers/:id` |

\* Endpoint pendiente de API-01 a API-05 (ver §5).

### Criterios de aceptación

**01 Splash.** Muestra el logo BOOKIA mientras valida la sesión guardada con `GET /auth/me`. Con sesión válida va a 03 con el usuario cargado; con 401 borra el token y va a 03 como visitante. La primera vez pasa por 02. Arranque en frío < 3 s (CAL-06).

**02 Permiso de ubicación.** Explica *antes* del aviso del sistema: "Usamos tu ubicación solo para ordenar las librerías por distancia y trazar la ruta. Nunca la guardamos." Botones **Permitir ubicación** y **Ahora no**. Si el usuario rechaza, la app funciona sin distancias. La ubicación nunca se envía ni se guarda en el servidor (SEG-04).

**03 Inicio.** Barra "Título, autor o ISBN" con acceso directo al escáner (06), chips de **Géneros** (de `/books/filters`), carrusel **Más buscados** con "desde $X" y **Librerías cerca de ti** con distancia y estado.

**04 Resultados.** Lista paginada (20 por página, scroll infinito) con título, autor, editorial, "desde $X" (`min_price`), número de librerías y piezas (`total_stock`). Chips rápidos **Disponible · Más barato · Más cerca**. Disponibilidad por color: verde (hay), ámbar (pocas, ≤ 2), gris (agotado). Contador "N libros encontrados". Vacío: invita a escanear el ISBN.

**05 Filtros.** Hoja inferior con **Género**, **Establecimiento** (`store_id`), **Precio** $50–$300 (`min_price`/`max_price`), **Solo disponibles** y **Ordenar por distancia** (requiere ubicación). Botones **Limpiar** y **Ver N resultados**. El orden usa Strategy: `SortByPrice`, `SortByDistance`, `SortByTitle` (PAT-09).

**06 Escanear ISBN.** La cámara (`mobile_scanner`) lee el EAN-13 de la contraportada ("Apunta al código de barras de la contraportada"). Solo acepta códigos 978/979 con dígito verificador válido. Al detectarlo muestra "ISBN detectado · {título} · En N librerías · desde $X" y abre 07. Si no existe en el catálogo: "No encontramos este libro en Huauchinango". Pide permiso de cámara con explicación.

**07 Ficha de libro.** Portada, título, autor, editorial y género. Sección **Dónde comprarlo**: una fila por oferta, ordenada por precio, con tienda, dirección, distancia, precio y existencias ("6 disponibles", "Últimas 2", "Agotado"). Botón **Reservar** si `is_available`, **Avisarme** si está agotado. Tocar la tienda abre 09. Acciones de favorito y compartir (S04).

**08 Mapa de librerías.** Google Maps con un pin por tienda y la ubicación del usuario. Buscador, chips **Abiertas ahora** y **Tienen "{libro}"** cuando se llega desde 07. Tocar un pin muestra una ficha rápida con nombre, dirección, distancia, "N min a pie", **Llamar** y **Cómo llegar** (abre Google Maps o Apple Maps con `url_launcher`).

**09 Ficha de librería.** Nombre, dirección, teléfono, horario, **Llamar**, **Cómo llegar**, **Ver en mapa** y **Catálogo (N)** con el precio y las existencias de cada libro (de `GET /stores/:id`). Tocar un libro abre 07.

**10 Reservar.** Requiere lector. Muestra libro, tienda, selector **Cantidad** de 1 a 5 (sin pasar del stock: "6 disponibles · máx. 5 por reserva"), precio unitario, **Total a pagar en tienda**, vigencia de 48 horas y la nota "Sin pago en línea. Puedes cancelar cuando quieras." Avisa del máximo de 10 reservas activas. 409 → "Ya no hay suficientes ejemplares".

**11 Reserva lista.** "¡Libro apartado!", código corto (ej. `BK-4F7Q`) y **código QR** (`qr_flutter`) para mostrar en mostrador; libro, cantidad, total, fecha y hora de vencimiento; **Cómo llegar** y **Agregar recordatorio** (S04).

**12 Mis reservas.** Pestañas **Activas (N)** (`pendiente`, `confirmada`) e **Historial** (`entregada`, `cancelada`, `vencida`). Cada tarjeta muestra el estado con color, código, libro, tienda y tiempo restante (cuenta regresiva hasta `expires_at`). Solo se ofrecen las acciones válidas para el estado (PAT-10): **Cancelar** (con confirmación) y **Ver código** (abre 11).

**13 Notificaciones push.** FCM entrega "Tu libro está listo" (reserva confirmada), "Tu reserva vence pronto" y "¡Ya llegó!" (libro de vuelta en stock). Al tocar el aviso abre 12 o 07 (deep link). Se registra el token del dispositivo al iniciar sesión.

**14 Login / registro.** Correo y contraseña; pestaña **Crear cuenta** con nombre (contraseña de 8 a 200 caracteres). Texto: "Para reservar libros y guardar favoritos. Buscar no requiere cuenta." Enlace **Acceso staff** (login con `portal: "admin"`). El JWT se guarda solo en `flutter_secure_storage` (SEG-01). Mensajes para 401, 409 y 429.

**15 Perfil.** Nombre, correo, rol y fecha de alta. **Mi actividad**: reservas activas y favoritos. Accesos a Mis reservas, Favoritos y Alertas. **Preferencias**: notificaciones push y usar mi ubicación (guardadas en el teléfono). **Cambiar contraseña**, **Cerrar sesión** y **Aviso de privacidad** (SEG-05).

**16 Panel de tienda.** Requiere `store_owner` o `admin`. Saludo con el nombre de la tienda. Indicadores: reservas por confirmar, títulos en catálogo, ofertas agotadas y monto apartado del mes (calculados desde `/reservations/manage` y `/stores/:id`). Lista **Por confirmar** con **Confirmar** y **Rechazar** (`cancelada`). Acción **Escanear QR de entrega**: lee el QR de 11 y marca la reserva como `entregada`. Si la cuenta tiene que cambiar su contraseña (403 `PASSWORD_CHANGE_REQUIRED`), la manda a cambiarla primero.

**17 Editar oferta.** Libro (título, autor, editorial, ISBN), **Precio (MXN)** y **Existencias** con − / +, aviso "N apartadas en reservas" y **Guardar** (`PUT /offers/:id`). Valida precio ≥ 0 y stock entero ≥ 0.

## 4. Requisitos no funcionales

| Tema | Requisito | Regla |
| --- | --- | --- |
| Plataformas | Android API 24+ (referencia) e iOS 15+ | TEC-03 |
| Diseño | Material 3 con tema BOOKIA; colores y textos desde el tema | TEC-04, COD-07 |
| Accesibilidad | Áreas táctiles ≥ 48 dp, contraste AA, `Semantics` en íconos | COD-09 |
| Sin conexión | Se conservan las últimas búsquedas y las reservas activas (`hive_ce`) | I2-10 |
| Seguridad | Token en Keychain/Keystore; HTTPS fuera de local; URL por `--dart-define` | SEG-01, SEG-02, COD-06 |
| Desempeño | Arranque < 3 s; API p95 < 200 ms | CAL-05, CAL-06 |
| Calidad | ≥ 70 % de cobertura en `domain/` y `data/`; `flutter analyze` sin avisos | CAL-01, CAL-03 |

## 5. Huecos entre los mockups y la API (por resolver con Jaime)

| Pantalla | Lo que muestra el mockup | Situación en la API | Propuesta |
| --- | --- | --- | --- |
| 03, 08, 09 | Distancia y "librerías cerca de ti" | No hay coordenadas | API-02 (`/stores/near`) |
| 06 | Buscar por ISBN exacto | Solo `q=` | API-03 (`?isbn=`) |
| 10–17 | Sesión con token | Solo cookie | API-01 (Bearer) |
| 13 | Push | No hay `/devices` | API-04 |
| 07, 15, 16 | "Avisarme", alertas, "N lectores pidieron aviso" | No hay `/alerts` | API-05 |
| 11, 12 | Código corto `BK-4F7Q` | La reserva no tiene código | Mostrar `BK-` + últimos 4 caracteres del `_id`; el QR lleva el `_id` completo |
| 03, 08 | "Abierto / Abiertas ahora" | `schedule` es texto libre | Mostrar el horario como texto; el filtro "abiertas ahora" queda fuera salvo que la API dé horario estructurado |
| 03 | "Más buscados" | No hay endpoint | Por definir (I2-11, S04) |
| 08 | "Libros · Papelería" | No hay tipo de tienda | Omitir la etiqueta |
| 14 | Continuar con Apple / Google, "¿Olvidaste tu contraseña?" | No existen | Fuera del MVP; se ocultan |
| 16 | "Últimos cambios" | `/audit-logs` es solo para admin | Solo se muestra al admin |
| 16 | "Nuevo libro" | `POST /books` es solo para admin | Solo se muestra al admin |
| 17 | Editar edición y "Visible para lectores" | Edición es del libro (solo admin); no hay campo de visibilidad | Se editan solo precio y stock |
