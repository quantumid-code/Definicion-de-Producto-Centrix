# Centrix · Paquete de especificación

Documentos de **salida** del paquete de especificación de Centrix, organizados por capa.

Clasificación: **interno confidencial**. Repositorio privado.

## Reglas del repositorio

1. **Markdown es la fuente de verdad.** Los `.docx` para comité se generan desde el
   Markdown, nunca al revés. Si existen dos versiones, gana la de este repositorio.
2. **Una sola versión vigente por documento.** Las correcciones sobrescriben el archivo.
   El histórico vive en git; no se conservan copias intermedias ni sufijos de versión.
3. **Aquí solo viven salidas.** Los insumos —documentación de terceros, especificaciones
   de procesador, manuales de plataforma origen— no entran a este repositorio. Su
   identidad y versión se registran en `CONTROL-CAMBIOS.md`, Parte I.
4. **Los artefactos ejecutables se validan antes de subirse.** El DDL corre contra
   PostgreSQL 16; el OpenAPI pasa por validador real; el AsyncAPI por verificación
   estructural. Lo que no corre, no se sube.
5. **Fuente única de verdad por tipo de información.** Todas las decisiones viven en
   `capa-0/0.3-registro-decisiones.md` con identificador `D##`; todas las preguntas
   abiertas en su Parte VI con identificador `P##`. No se duplican en otros documentos.
6. **Todo cambio se registra antes de hacerse.** `CONTROL-CAMBIOS.md` dice qué documento
   hay que rehacer y por qué insumo, con versión y fecha. Git dice *qué* cambió; el
   control de cambios dice *por qué*. Un documento no se toca sin su fila.
7. **Los insumos se citan con versión.** Nunca «el manual de Prosa»: siempre
   «Estándar Host POS Adquirente 8.12.0 · 19/05/2026». Un análisis sin versión de origen
   no es verificable y se descarta.
8. **Convención de commit:** `<id> <nombre corto> · <qué cambió>`.
   Ejemplo: `4.4 simulador del procesador · versión inicial`.

## Estado

**31 de 62 documentos.**

> **Aviso de integridad.** El paquete tiene tres inconsistencias conocidas, registradas en
> `CONTROL-CAMBIOS.md`. Hasta resolverlas, el estado por capa de abajo es indicativo:
>
> 1. **`0.3-registro-decisiones.md` está desactualizado.** Define hasta D22 y no contiene
>    la Parte VI. El resto del paquete cita D39, D40, D41, D43, D44, D45 y D46 —incluido
>    un `COMMENT ON` del DDL ejecutado— y la regla 5 apunta a una sección inexistente.
>    **Es prerrequisito de cualquier otro cambio.**
> 2. **Capa 0 no está completa.** Son 12 documentos, no 11. Falta 0.11.
> 3. ~~El README de capa 4 marca `1.5 ✓`.~~ **Corregido en esta ronda.** 4.4 sigue bloqueado por
>    1.5; los que pueden arrancar sin dependencias son **4.1 y 4.6**.

| Capa | Nombre | Estado |
|---|---|---|
| 0 | Fundamentos | 11 de 12 · **9 regenerados a v0.2** · falta 0.11 |
| 1 | Contratos | parcial · **bloque de revisión aplicado** · 1.5 y 1.6 desbloqueados |
| 2 | Datos | parcial · **bloque de revisión aplicado** · 2.1 y 2.6 desbloqueados |
| 3 | Arquitectura e infraestructura | **bloque de revisión aplicado en los tres** |
| 4 | Andamiaje y calidad | **objetivo activo · 0 de 7** · 4.1 y 4.6 pueden arrancar |
| 5 | Guía para agentes | pendiente |
| 6–7 | Operación, cliente y cumplimiento | pendiente |

**Ronda del 9 de septiembre de 2026.** Nueve documentos de Capa 0 regenerados contra los
manuales vigentes de Prosa y E-Global; nueve artefactos de Capas 1 a 3 con bloque de revisión en
cabecera. Bitácora completa en `CONTROL-CAMBIOS.md` Parte VI.

**Los artefactos ejecutables conservan su cuerpo validado.** El DDL corrió contra PostgreSQL 16;
el contrato pasó por validador real. Reescribirlos sin volver a ejecutarlos incumpliría la regla
4, así que llevan los pendientes en la cabecera y se aplican en sesión dedicada.

## Insumos vigentes

Los manuales de cámara están completos. Detalle y versiones en `CONTROL-CAMBIOS.md`.

- **Prosa** · Estándar Host POS Adquirente 8.12.0 · Especificación Online para Servicios
  de Agregadores 3.8.0 · Especificación Estándar de Tokens 0.17.0 · Mejores Prácticas de
  Códigos de Respuesta 1.4.0
- **E-Global** · Anexo A Mensajería ISO Interredes 9.0

Pendientes de obtener: Especificación para el intercambio Dinámico de Llaves,
especificación técnica del Token FA, Contrato de Intercambio Doméstico, Estándar de
Conectividad de Prosa, documentación de marca patrocinada.

## Orden de trabajo vigente

1. **Reemplazar `0.3`** con la versión vigente, incluida la Parte VI. Prerrequisito.
2. **Decidir la forma del archivo declarativo de dialecto**, con tres niveles: norma ISO,
   cámara, extensión de adquirente. No depende de terceros y condiciona 1.5 y 1.6.
3. **Escribir 4.1 y 4.6**, que no tienen dependencias pendientes.
4. ~~Aplicar las regeneraciones de Capa 0.~~ **Hecho el 9 de septiembre.**
5. **Completar el pase** de la Especificación Estándar de Tokens y de Mejores Prácticas de
   Códigos de Respuesta, que están inventariadas pero no analizadas. Va antes de 1.5 y 1.6.
6. **Escribir 1.5 y 1.6**, y con ello desbloquear 4.4.
7. **Reejecutar los DDL** contra PostgreSQL 16 con los cambios de sus cabeceras.

`explorador.html` es el artefacto vivo: los 62 documentos con grafo de dependencias,
olas topológicas, ruta crítica y estado. Se actualiza con cada documento terminado.
