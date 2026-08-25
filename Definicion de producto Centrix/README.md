# Centrix · Paquete de especificación

Documentos de **salida** del paquete de especificación de Centrix, organizados por capa.

Clasificación: **interno confidencial**. Repositorio privado.

## Reglas del repositorio

1. **Markdown es la fuente de verdad.** Los `.docx` para comité se generan desde el
   Markdown, nunca al revés. Si existen dos versiones, gana la de este repositorio.
2. **Una sola versión vigente por documento.** Las correcciones sobrescriben el archivo.
   El histórico vive en git; no se conservan copias intermedias ni sufijos de versión.
3. **Aquí solo viven salidas.** Los insumos —documentación de terceros, especificaciones
   de procesador, manuales de plataforma origen— no entran a este repositorio.
4. **Los artefactos ejecutables se validan antes de subirse.** El DDL corre contra
   PostgreSQL 16; el OpenAPI pasa por validador real; el AsyncAPI por verificación
   estructural. Lo que no corre, no se sube.
5. **Fuente única de verdad por tipo de información.** Todas las preguntas abiertas viven
   en `capa-0/0.3-registro-decisiones.md`, Parte VI, con identificador `P##`. No se
   duplican en otros documentos.
6. **Convención de commit:** `<id> <nombre corto> · <qué cambió>`.
   Ejemplo: `4.4 simulador del procesador · versión inicial`.

## Estado

**31 de 62 documentos.** Capas 0 a 3 completas. Capa 4 es el objetivo activo.

| Capa | Nombre | Estado |
|---|---|---|
| 0 | Fundamentos | completa |
| 1 | Contratos | parcial |
| 2 | Datos | parcial |
| 3 | Arquitectura e infraestructura | completa |
| 4 | Andamiaje y calidad | **objetivo activo · 0 de 7** |
| 5 | Guía para agentes | pendiente |
| 6–9 | — | pendiente |

`explorador.html` es el artefacto vivo: los 62 documentos con grafo de dependencias,
olas topológicas, ruta crítica y estado. Se actualiza con cada documento terminado.
