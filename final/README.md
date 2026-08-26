# Centrix · Paquete de especificación

Documentos de **salida** del paquete de especificación de Centrix, organizados por capa.

Clasificación: **interno confidencial**. Repositorio privado.

> **Este paquete es el punto de partida consolidado del 25 de agosto de 2026.**
> Reemplaza cualquier carpeta local anterior. Verificado por script: cero referencias colgantes
> entre decisiones, preguntas y documentos. Ver `VERIFICACION.md`.

## Reglas del repositorio

1. **Markdown es la fuente de verdad.** Los `.docx` para comité se generan desde el Markdown, nunca
   al revés. Si existen dos versiones, gana la de este repositorio.
2. **Una sola versión vigente por documento.** Las correcciones sobrescriben el archivo. El histórico
   vive en git; no se conservan copias intermedias ni sufijos de versión.
3. **Aquí solo viven salidas.** Los insumos —documentación de cámara, de marca, de plataforma origen—
   no entran a este repositorio.
4. **Los artefactos ejecutables se validan antes de subirse.** El DDL corre contra PostgreSQL 16; el
   OpenAPI pasa por validador real. Lo que no corre, no se sube.
5. **Fuente única de verdad por tipo de información.** Todas las decisiones y todas las preguntas
   abiertas viven en `capa-0/0.3-registro-decisiones.md`. Las preguntas, en la Parte VI, con
   identificador `P##`. No se duplican en ningún otro documento.
6. **Nada se descarga a una carpeta local como versión de trabajo.** Es la causa raíz del desfase que
   costó reconciliar este paquete: había versiones en carpetas de descarga y ninguna era la buena.
7. **Convención de commit:** `<id> <nombre corto> · <qué cambió>`.

## Estado

**34 de 62 documentos.**

| Capa | Nombre | Estado |
|---|---|---|
| 0 | Fundamentos | 11 de 12 · falta 0.11, bloqueado |
| 1 | Contratos | 4 de 10 |
| 2 | Datos | 5 de 7 |
| 3 | Arquitectura e infraestructura | 11 de 11 · completa |
| 4 | Andamiaje y calidad | **3 de 7 · objetivo activo** |
| 5 | Guía para agentes | 0 de 3 |
| 6 | Operación y cliente | 0 de 8 |
| 7 | Cumplimiento y riesgo | 0 de 4 |

`explorador.html` es el artefacto vivo: los 62 documentos con grafo de dependencias, olas
topológicas, ruta crítica y estado. Se actualiza con cada documento terminado.

`enmiendas/` contiene deltas pendientes de aplicar. Un delta aplicado se archiva; un delta sin
aplicar es trabajo abierto.
