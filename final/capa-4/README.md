# Capa 4 · Andamiaje y calidad

**Objetivo activo. Tres de siete.**

Es lo que hace que el método asistido por IA produzca código verificable en vez de volumen. Sin esta
capa, el cuello de botella de revisión se vuelve insalvable.

Dependencia de lenguaje: sí. Resuelta por **D14 (Go)**.

| Doc | Nombre | Depende de | Estado |
|---|---|---|---|
| 4.1 | Estructura de repositorios y propiedad | 3.1 ✓ | **generado** |
| 4.2 | Plantilla de servicio | 1.4, 4.1 ✓ | pendiente |
| 4.3 | Pipeline y los cinco controles automatizados | 0.4 ✓, 4.2 | pendiente |
| 4.4 | Especificación del simulador del procesador | 1.5 | **bloqueado por 1.5** · con D49 pasa a ejecutor de guiones de certificación |
| 4.5 | Estrategia de pruebas | 1.4, 4.4 | pendiente |
| 4.6 | Definición de terminado y proceso de revisión | 0.4 ✓ | **generado** |
| 4.7 | Convenciones de código y análisis estático | 4.1 ✓ | **generado** |

## Qué falta y por qué

**4.2** necesita 1.4 (esquemas JSON compartidos), que sigue pendiente en Capa 1.

**4.3** depende de 4.2. Los cinco controles de proceso se definen sobre la plantilla, no antes.

**4.4** está bloqueado por 1.5. Escribir el simulador antes que el contrato del puerto haría que el
banco de pruebas adoptara la forma del habilitador de Fase 0, y ese molde se arrastraría al adaptador.
Es el riesgo E10 entrando por la puerta de atrás.

**4.5** depende de 4.4.

## Decisiones tomadas en esta capa

- **Tres repositorios**, no uno ni trece: plataforma, dialectos, infraestructura. Razonado en 4.1.
- **Terminado es verificable por un tercero**, no declarado por el autor. Razonado en 4.6.
- **Lista de permitidos, no lista de prohibidos**, para el registro estructurado. Razonado en 4.7.
