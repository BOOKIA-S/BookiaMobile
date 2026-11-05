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

## Documentación

| Documento | Para qué |
| --- | --- |
| [CLAUDE.md](CLAUDE.md) | Instrucciones para el Claude de cada integrante. Léelo primero |
| [docs/CONSTITUTION.md](docs/CONSTITUTION.md) | Reglas obligatorias del proyecto (arquitectura, patrones, Git, Docker, CI/CD, métricas) |
| [docs/PLAN.md](docs/PLAN.md) | Calendario, reparto de commits por integrante y bitácoras semanales |
| [docs/GUIA_GITHUB.md](docs/GUIA_GITHUB.md) | Guía paso a paso de Git y GitHub para el equipo |
| [docs/bitacoras/](docs/bitacoras/) | Plantilla y bitácoras semanales en Word |
| [docs/word/](docs/word/) | Copias en Word de la Constitución, el Plan y la Guía (la versión vigente es la `.md`) |

La guía completa de instalación de Flutter y Docker llega con el commit I4-01 del Plan.

## Licencia

[MIT](LICENSE).
