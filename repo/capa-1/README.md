# Capa 1 · Contratos

Lo que terceros integran contra Centrix.

**Estado: parcial.** 1.5 y 1.6 quedaron desbloqueados el 9 de septiembre de 2026 al llegar los
manuales vigentes. Los artefactos ejecutables llevan **bloque de revisión** y **conservan el
cuerpo validado**: la regla 4 del repositorio exige que lo que se sube haya corrido.

| Doc | Nombre | Archivo | Estado |
|---|---|---|---|
| 1.7–1.8 | Webhooks y versionado | `1.7-1.8-webhooks-versionado.md` | revisado, sin cambios de fondo |
| — | API pública | `openapi-publica.yaml` — OpenAPI 3.1, validado | **7 pendientes en cabecera** |
| — | Eventos | `asyncapi-eventos.yaml` — AsyncAPI 3.0 | **4 pendientes en cabecera** |
| 1.5 | Tabla de mapeo por dialecto | — | **desbloqueado, sin generar** |
| 1.6 | Catálogo de códigos de respuesta | — | **desbloqueado, sin generar** |

## Antes de escribir 1.5

Falta una decisión que condiciona su formato: **la forma del archivo declarativo de dialecto**,
que tiene **tres niveles** y no dos —norma internacional, variante de cámara, y extensión de
adquirente sobre esa variante—. Decisión provisional **N-2**. Escribir 1.5 asumiendo dos
niveles obliga a reescribirla entera.

## Una confusión que hay que evitar

La política de **reintentos de entrega de webhook** de 1.7–1.8 es de transporte. **No tiene
nada que ver con el gobierno de reintentos de una transacción declinada**, que es normativo, lo
publica cada cámara y vive en 0.2 §3.3 con el invariante I18. Reutilizar el mismo vocabulario
sería un error con consecuencia ante marca.
