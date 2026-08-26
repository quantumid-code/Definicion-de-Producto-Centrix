# Verificación del paquete consolidado

Ejecutada el 2026-08-25 sobre el árbol completo, por script.

Este archivo es la constancia de que el paquete se subió comprobado y no confiado. Se regenera
con cada consolidación.

---

## 1 · Fuente única

Todas las decisiones y todas las preguntas viven en `capa-0/0.3-registro-decisiones.md`.

| | |
|---|---|
| Decisiones con ficha razonada | **36**, hasta D51 |
| Decisiones abiertas en tabla | **14** |
| Preguntas en la Parte VI | **57**, de P1 a P57 |

## 2 · Referencias colgantes en el paquete canónico

Verificados **30** archivos de las capas 0 a 4, incluidos los tres artefactos ejecutables.

- Referencias a decisiones inexistentes: **0**
- Referencias a preguntas inexistentes: **0**

> **Cero referencias colgantes.** Toda `D##` y toda `P##` citada en cualquier documento
> existe declarada en 0.3.

## 3 · Identificadores propuestos en enmiendas sin aplicar

No son referencias rotas: son identificadores **reservados** por un delta pendiente. Dejan de
aparecer aquí cuando el delta se aplica a 0.3.

- `D52` — propuesto en `enmiendas/README.md`
- `P58` — propuesto en `enmiendas/README.md`
- `P59` — propuesto en `enmiendas/delta-rieles-rutas-programas-v1.md`
- `P60` — propuesto en `enmiendas/delta-rieles-rutas-programas-v1.md`
- `P61` — propuesto en `enmiendas/delta-rieles-rutas-programas-v1.md`
- `P62` — propuesto en `enmiendas/README.md`

## 4 · Procedencia

El paquete se consolidó a partir de dos carpetas que contenían generaciones distintas.

| Archivo | Origen | Versión |
|---|---|---|
| `capa-0/0.1-glosario-canonico.md` | paquete 19/08 | 0.3 |
| `capa-0/0.10-identidad-multitenant.md` | paquete 24/08 | 0.1 |
| `capa-0/0.12-prohibiciones-agentes.md` | paquete 19/08 | 0.3 |
| `capa-0/0.2-modelo-canonico.md` | paquete 19/08 | 0.4 |
| `capa-0/0.3-registro-decisiones.md` | paquete 19/08 | 0.5 |
| `capa-0/0.4-reglas-irrevocables.md` | paquete 24/08 | 0.1 |
| `capa-0/0.5-modelo-monetario.md` | paquete 24/08 | 0.1 |
| `capa-0/0.6-motor-comisiones.md` | paquete 19/08 | 0.3 |
| `capa-0/0.7-modelo-contable.md` | paquete 19/08 | 0.3 |
| `capa-0/0.8-movimiento-conciliatorio.md` | paquete 24/08 | 0.1 |
| `capa-0/0.9-metodo-y-riel.md` | paquete 19/08 | 0.3 |
| `capa-1/1.7-1.8-webhooks-versionado.md` | paquete 24/08 | 0.1 |
| `capa-1/asyncapi-eventos.yaml` | paquete 19/08 | — |
| `capa-1/openapi-publica.yaml` | paquete 19/08 | — |
| `capa-2/2.4-2.5-2.7-datos.md` | paquete 19/08 | 0.3 |
| `capa-2/ddl-ledger-v1.sql` | paquete 19/08 | 0.1 |
| `capa-2/ddl-v1.sql` | paquete 19/08 | 0.1 |
| `capa-3/3.1-3.4-servicios-y-alcance.md` | paquete 19/08 | 0.3 |
| `capa-3/3.5-3.8-infraestructura.md` | paquete 24/08 | 0.1 |
| `capa-3/3.9-3.11-seguridad.md` | paquete 19/08 | 0.3 |
| `capa-4/4.1-estructura-repositorios.md` | **generado 25/08** | 0.1 |
| `capa-4/4.6-definicion-terminado-revision.md` | **generado 25/08** | 0.1 |
| `capa-4/4.7-convenciones-analisis-estatico.md` | **generado 25/08** | 0.1 |
| `enmiendas/delta-rieles-rutas-programas-v1.md` | **generado 25/08** | 1.0 |
| `explorador.html` | paquete 19/08, actualizado 25/08 | — |

**Los archivos marcados 24/08 son los que no cambiaron en la pasada final del 19.** Se
verificó que ninguno cita decisiones por encima de las que declara 0.3.

## 5 · Inventario

- Archivos de contenido: **32** más el explorador
- Documentos del paquete cubiertos: **34 de 62**
- Artefactos ejecutables: DDL contra PostgreSQL 16, OpenAPI 3.1 validado, AsyncAPI 3.0
