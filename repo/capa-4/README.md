# Capa 4 · Andamiaje y calidad

**Objetivo activo. Cero de siete.**

Es lo que hace que el método asistido por IA produzca código verificable en vez de
volumen. Sin esta capa, el cuello de botella de revisión se vuelve insalvable.

Dependencia de lenguaje: sí. Resuelta por **D14 (Go)**.

| Doc | Nombre | Depende de | Estado |
|---|---|---|---|
| 4.1 | Estructura de repositorios y propiedad | 3.1 ✓ | **puede arrancar ya** |
| 4.2 | Plantilla de servicio | 1.4, 4.1 | pendiente |
| 4.3 | Pipeline y los cinco controles automatizados | 0.4 ✓, 4.2 | pendiente |
| 4.4 | Especificación del simulador del procesador | **1.5 ✗** | **bloqueado** |
| 4.5 | Estrategia de pruebas | 1.4, 4.4 | pendiente |
| 4.6 | Definición de terminado y proceso de revisión | 0.4 ✓ | **puede arrancar ya** |
| 4.7 | Convenciones de código y análisis estático | 4.1 | pendiente |

## Corrección de estado

La versión anterior de este archivo marcaba **4.4 con dependencia `1.5 ✓` y lo listaba entre los
que pueden arrancar. Era falso**: el documento 1.5 no existe. Los que pueden arrancar sin
dependencias pendientes son **4.1 y 4.6**.

## 4.6 es donde hay que enfrentar el problema

La regla R7 exige revisión de código por persona distinta al autor, documentada, y **un agente no
puede firmarla**. Con un solo revisor hay punto único de falla y techo de velocidad, y con
desarrollo asistido se produce más rápido de lo que se puede verificar. Escribir 4.6 obliga a
nombrar el problema en vez de descubrirlo en la semana tres. Compuerta E5.

## 4.4 ya tiene material de sobra, en cuanto se libere

De los manuales vigentes salen guiones de certificación reales: códigos de rechazo por campo con
su semántica, resultados de fallo criptográfico, respuesta tardía con reverso originado por la
propia cámara, terminal sin inicializar, y el ciclo de gestión de red con su umbral de fallos
consecutivos. La ventana semanal acotada del ambiente de pruebas hace del simulador su única
mitigación.
