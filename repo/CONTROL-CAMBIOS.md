# Centrix · Control de cambios del paquete de especificación

Registro de qué documento hay que regenerar, revisar o dejar intacto, y por qué.

**Existe para no perder trazabilidad.** Cada fila dice qué insumo obligó al cambio, con
versión y fecha, de manera que dentro de tres meses se pueda reconstruir por qué un
documento se rehizo. No sustituye a git: git dice *qué* cambió, esto dice *por qué*.

**Regla de uso.** Un documento no se toca hasta que su fila esté en estado `pendiente` con
causa registrada. Cuando se regenera, la fila pasa a `aplicado` con la fecha y el hash del
commit. Las filas aplicadas no se borran.

Clasificación: **interno confidencial**.

---

## Parte I · Insumos que motivan los cambios

Todos son documentos de terceros. **No viven en este repositorio** (regla 3 del README);
se registran aquí solo con su identidad y versión para poder citarlos.

| Ref | Insumo | Versión | Fecha | Estado |
|---|---|---|---|---|
| **I-1** | Prosa · Estándar Host POS Adquirente | **8.12.0** | 19/05/2026 | vigente · analizado parcialmente |
| **I-2** | Prosa · Especificación Online para Servicios de Agregadores | **3.8.0** | 24/02/2026 | vigente · analizado |
| **I-3** | Prosa · Especificación Estándar de Tokens | **0.17.0** | 19/05/2026 | vigente · **inventariado, no analizado** (233 pp) |
| **I-4** | Prosa · Mejores Prácticas de Códigos de Respuesta | **1.4.0** | 27/04/2026 | vigente · analizado parcialmente (58 pp) |
| **I-5** | E-Global · Anexo A Mensajería ISO Interredes | **9.0** | Agosto 2024 | vigente · analizado parcialmente |
| **I-6** | Prosa · Anexo 4I Indicadores campo 63 Tokens POS | s/v | s/f | **superado por I-3**; contenido válido, campo desplazado a P-57 |
| **I-7** | Plataforma origen · Guía de integración API Comercios | 2.0 | s/f | analizado · insumo de Capa 6 |
| **I-8** | Catálogo de giros · Anexo 53 | s/v | s/f | analizado · **procedencia y vigencia sin confirmar** |

### Insumos superados — no volver a usar

| Insumo | Versión analizada | Sustituido por | Nota |
|---|---|---|---|
| Prosa · Estándar Host POS Adquirente | 7.0.12 · nov 2022 | **I-1** | 3 años y medio de control de cambios de diferencia |
| Prosa · Especificación Servicio Agregadores | 2.1 · s/f | **I-2** | Conclusiones derivadas de esta versión están corregidas abajo |

### Insumos descartados — decisión registrada

| Insumo | Motivo del descarte |
|---|---|
| Banorte · Manual de Integración Agregadores e Integradores 2.3 | API propietaria de un adquirente, no norma de cámara. No hay que integrarse a esto. |
| Banorte · Manual Comercio Electrónico Agregadores y Aliados 2.4 | Igual que el anterior. |
| Proyecto Banorte Payworks TPV (plataforma origen) | Plan de proyecto de un tercero sobre host de adquirente. Contradice F0. |
| E-Global · Token PU, retiro sin tarjeta con QR | Riel de retiro de efectivo en interredes. **No cubre la promesa de pago con QR del sitio.** |

**Criterio de descarte, para reutilizar:** un manual de adquirente puede parecerse mucho a
uno de cámara sin serlo. El indicador que lo delata es si la mensajería es la norma ISO o
una API propietaria por encima.

### Insumos pendientes de obtener

| Ref | Insumo | Por qué se necesita | Bloquea |
|---|---|---|---|
| **X-1** | Prosa · Especificación para el intercambio Dinámico de Llaves | Detalle de campos del intercambio TR31 en mensajes 08xx | Máquina de estados de llaves · D1c · D35 |
| **X-2** | Prosa · especificación técnica del Token FA | Obligatoria para emisores internacionales sin AGP. Documento aparte, se solicita al contacto Prosa | Identidad de sub-afiliado hacia emisor internacional |
| **X-3** | Contrato de Intercambio Doméstico · Cap. XII sec. 6, Anexos 21 y 29 | Define los esquemas de agregación y las reglas de devolución doméstica | Motor de comisiones · operativa de devoluciones |
| **X-4** | Prosa · Estándar de Conectividad | Referenciado por el Anexo VII del estándar host | Capa 3 · conectividad |
| **X-5** | Documentación de marca patrocinada (N1) | Motivos de contracargo | Estados de contracargo |

---

## Parte II · Correcciones a conclusiones previas

Análisis hechos sobre insumos superados que resultaron equivocados. **Se registran para que
nadie los reutilice de memoria.**

| # | Lo que se concluyó | Lo que dice la fuente vigente | Fuente |
|---|---|---|---|
| C-1 | `AGRS` identifica la modalidad **con AGP** | `AGRS` = agregador **conectado a Prosa**; `AGRE` = agregador **no conectado**, vía adquirente. Codifica el **modo de acceso**, no la modalidad de agregación | I-2 · Consideraciones |
| C-2 | La modalidad de agregación se ve en la red lógica | Se ve en el subcampo **Originator del S-125**: `HOST`/`B24 ` con validación contra ACT, `INTR` sin validación en B24 | I-2 · S-125 |
| C-3 | Prosa **no** separa autorización de captura en POS | Sí separa, vía **Draft Capture Flag** del S-125 posición 14. Con valor `0` la compensación exige **archivo TEF batch** o no se liquida | I-2 · S-125 |
| C-4 | Los tokens viajan en el campo **P-63** | El **P-57** los sustituye y es **obligatorio para todo participante nuevo**, nacional e internacional, desde la v3.4.1 | I-1 · I-2 |
| C-5 | El token **FA** se eliminó por contradicción entre documentos | Se eliminó de I-2 porque *su uso no es exclusivo de agregadores*. Sigue siendo **obligatorio para emisores internacionales sin AGP**, subcampo `SUB-MRCH-ID`. Su especificación es documento aparte | I-2 v3.4.0 |
| C-6 | Los cinco esquemas de agregación eran invención de Banorte | Los esquemas 2 (tasa natural por excepción) y 3 (giro agregador) están **declarados en el CID** | I-2 · P-18 |
| C-7 | El eje 3 de la matriz es binario | Tres escenarios en Prosa: **con AGP · sin AGP · tasa natural**. Los esquemas 2 y 3 del CID reciben tratamiento de tasa natural | I-2 |

**Pregunta abierta derivada de C-3:** si la separación entre autorización y compensación es
una bandera del mensaje, la afirmación de que Centrix «sintetiza» la separación en el
adaptador de Prosa era innecesaria. Hay que rehacer ese análisis contra I-1 capítulo 7.

---

## Parte III · Estado de los documentos del paquete

Estados: `sin cambio` · `revisar` · `regenerar` · `bloqueado` · `aplicado`

### Capa 0 · Fundamentos

| Doc | Estado | Causa | Insumo |
|---|---|---|---|
| 0.1 Glosario canónico | **regenerar** | Términos ausentes: red lógica (`AGRS`/`AGRE`), FIID de adquirente patrocinador, escenario de agregación, tasa natural, draft capture, fichero TEF, buffer de tokens, facilitador de pagos, TR31. Glosario de Prosa define **Agregador = PSP + Facilitador de Pagos** | I-1, I-2 |
| 0.2 Modelo canónico | **regenerar** | Falta la máquina de estados de llaves de terminal (DUKPT + TR31, inicialización, ISO 39 `70`/`71`). Falta el identificador de facilitador de pagos por marca como entidad. El escenario de agregación es atributo de la afiliación, no del comercio. Falta gobierno de reintentos | I-1, I-2, I-5 |
| 0.3 Registro de decisiones | **bloqueado · prerrequisito** | **La copia del paquete está desactualizada**: define hasta D22 y no tiene Parte VI. El resto del paquete cita D39–D46 y el README apunta a una Parte VI inexistente. **Ningún otro documento se toca antes de reemplazar este** | — |
| 0.4 Reglas irrevocables | **revisar** | Candidato a control nuevo: rechazo estructural con `ES` subcampo 3 = `00`. **Verificar antes contra I-1 capítulo 5**, la conclusión venía de la 7.0.12. Segundo candidato: ninguna transacción con draft capture `0` se considera compensada sin confirmación de fichero | I-1 |
| 0.5 Modelo monetario | **revisar** | Importe autorizado que contiene comisión de un tercero desglosada en token aparte | I-5 |
| 0.6 Motor de comisiones | **regenerar** | Tres escenarios de agregación con consecuencia tarifaria distinta. Esquemas del CID. Codificación de promociones del token Q6 (gracia · parcialidades · tipo). Duplicidad de MCC con familia y tarifa distintas | I-2, I-3, I-8, X-3 |
| 0.7 Modelo contable | **regenerar** | **La compensación no es automática**: con draft capture `0` depende de un fichero TEF batch. Cambia el asiento y su momento | I-2 |
| 0.8 Movimiento conciliatorio | **regenerar** | S-125 como fuente de liquidación. Fichero TEF. Enlace de transacciones relacionadas: tokens `HV`/`HW` en Prosa, token `RZ` en E-Global — ambas cámaras tienen dónde alojar los identificadores de intención e intento | I-2, I-3, I-5 |
| 0.9 Método y riel | **regenerar** | Capacidades por riel: P-57 contra P-63, escenarios de agregación, Discover como red aceptada, operativas del capítulo 7 de I-1 | I-1, I-2 |
| 0.10 Identidad multitenant | **revisar** | Multiadquirencia del agregador identificada por FIID en el P-60. Tres identidades en un solo campo: patrocinador, agregador, sub-afiliado | I-2 |
| 0.11 Máquina de estados de llaves | **pendiente de generar** | Se desbloquea con I-1 cap. 5 e I-3. Falta X-1 para el detalle de campos | I-1, I-3, X-1 |
| 0.12 Prohibiciones para agentes | sin cambio | — | — |

### Capa 1 · Contratos

| Doc | Estado | Causa | Insumo |
|---|---|---|---|
| `openapi-publica.yaml` | **revisar** | Cita D39, D40, D43, D44, D45 — **referencias colgadas** hasta que se reemplace 0.3. Exponer promociones y 3DS | — |
| `asyncapi-eventos.yaml` | **revisar** | Cita D39, D40, D41 — referencias colgadas | — |
| 1.5 Tabla de mapeo por dialecto | **pendiente de generar** | Desbloqueado. Requiere antes la decisión de forma del archivo declarativo | I-1, I-2, I-3, I-5 |
| 1.6 Catálogo de códigos de respuesta | **pendiente de generar** | Desbloqueado por I-4. Incluye taxonomía de categorías y reglas de reintento | I-4, I-5 |
| 1.7–1.8 Webhooks y versionado | sin cambio | — | — |

### Capa 2 · Datos

| Doc | Estado | Causa | Insumo |
|---|---|---|---|
| `ddl-v1.sql` | **regenerar** | `COMMENT ON` cita D43 — referencia colgada. Faltan campos de identidad: facilitador por marca, escenario de agregación, FIID patrocinador | I-2 |
| `ddl-ledger-v1.sql` | **revisar** | Estado de compensación por fichero frente a compensación integrada | I-2 |
| 2.4–2.5–2.7 Datos | **revisar** | Retención de contenido de tarjeta en el aviso 0220 | I-1 |
| 2.1 Migración | **pendiente de generar** | Desbloqueado por I-7 | I-7 |
| 2.6 Datos de prueba | **pendiente de generar** | Desbloqueado. Códigos de rechazo por campo: ISO `30` Format Error, ISO `03` Invalid Merchant | I-2, I-4 |

### Capa 3 · Arquitectura e infraestructura

| Doc | Estado | Causa | Insumo |
|---|---|---|---|
| 3.1–3.4 Servicios y alcance | **revisar · prioridad alta** | **Decide alcance PCI.** En el 0200 el Track 2 va cifrado en token `EZ` por normativa CNBV; en el 0220 el texto admite track2 recortado con PAN completo. I-2 afirma que P-35 y P-45 quedan protegidos por TLS 1.2. Las dos lecturas dan alcances distintos | I-1, I-2 |
| 3.5–3.8 Infraestructura | **revisar** | Verificar timers y topologías de nodo contra I-1. La versión analizada era la 7.0.12 | I-1 |
| 3.9–3.11 Seguridad | **regenerar** | **TR31 mandatorio** (ANS X9.24) con intercambio en 08xx vía `S-110 TR-31 Key Block` y `S-120 RED Key Management`. PIN Online obligatorio por Mastercard y PCI PIN. Impacta D35 | I-1, I-2, X-1 |

### Capa 4 · Andamiaje y calidad

| Doc | Estado | Causa | Insumo |
|---|---|---|---|
| 4.1 Estructura de repositorios | **puede generarse ya** | Sin dependencias pendientes | — |
| 4.6 Definición de terminado y revisión | **puede generarse ya** | Sin dependencias pendientes. Es donde se enfrenta el problema del segundo revisor (E5) | — |
| 4.4 Simulador del procesador | **bloqueado por 1.5** | El README de capa 4 marca `1.5 ✓` y **es falso**: 1.5 no existe. Material disponible para guiones: códigos de rechazo por campo, ISO 39 `70`/`71`, respuesta tardía con reverso | I-1, I-2, I-4 |
| 4.2, 4.3, 4.5, 4.7 | pendientes | Dependencias internas | — |

---

## Parte IV · Decisiones nuevas por registrar en 0.3

No se pueden registrar hasta reemplazar 0.3. Se listan aquí para no perderlas.

| # | Decisión propuesta | Origen |
|---|---|---|
| N-1 | El buffer de tokens es **P-57**, no P-63. Obligatorio para participante nuevo. P-63 solo lectura de legado | I-2 |
| N-2 | Forma del archivo declarativo de dialecto **con tres niveles**: norma ISO, cámara, extensión de adquirente | I-5 |
| N-3 | El escenario de agregación es **atributo de la afiliación**, con vigencia, y determina la tarifa | I-2 |
| N-4 | El identificador de facilitador de pagos **por marca** es entidad propia, distinta de afiliación y sub-afiliación | I-2, I-5 |
| N-5 | **Gobierno de reintentos** como atributo calculado del canónico, no decisión del integrador | I-4, I-5 |
| N-6 | La compensación con draft capture `0` **exige confirmación de fichero**; sin ella no hay liquidación | I-2 |
| N-7 | TR31 como método de intercambio de llaves; revisar D35 en consecuencia | I-1, I-2 |

## Parte V · Preguntas nuevas para Prosa

| # | Pregunta | Por qué importa |
|---|---|---|
| Q-1 | En el aviso 0220, ¿el track2 recortado puede tokenizarse, o el PAN viaja necesariamente en el campo P-35? | **Define el alcance PCI de Centrix.** Es la pregunta más importante del paquete |
| Q-2 | ¿Cuál es el procedimiento y el plazo para el encendido del campo P-57 por indicación del adquirente patrocinador? | Condiciona el calendario del conector |
| Q-3 | Solicitud formal de X-1 y X-2 | Bloquean 0.11 y la identidad hacia emisor internacional |

---

## Parte VI · Bitácora de aplicación

Ronda **9 de septiembre de 2026**. Estados: `aplicado` = documento regenerado ·
`bloque` = bloque de revisión antepuesto, cuerpo sin modificar · `bloqueado` = no se toca.

| Doc | Acción | Versión | Qué se aplicó |
|---|---|---|---|
| 0.1 | **aplicado** | v0.2 | Doce términos nuevos · apartado 2 nuevo (modo de acceso y escenario de agregación) · corrección de la entrada «Agregador» · cierre de dos preguntas abiertas · el giro deja de ser llave de tarifa |
| 0.2 | **aplicado** | v0.2 | Entidad de identificador de facilitador · máquina de estados criptográficos de terminal · apartado 5.1b de captura diferida · invariantes I16, I17, I18 · matiz al principio P2 |
| 0.3 | **bloqueado** | — | Prerrequisito. Define hasta D22, sin Parte VI |
| 0.4 | **aplicado** | v0.2 | R3 reescrita con evidencia · R2 ampliada al mensaje de aviso · apartado 9 con dos candidatas **no promovidas** · siguen siendo ocho reglas |
| 0.5 | **aplicado** | v0.2 | Apartado 6 de importe compuesto · prorrateo de promoción a plazos · cuota fija como unidad · M8 y M9 |
| 0.6 | **aplicado** | v0.2 | Apartado 4 de escenario de agregación · categoría comercial sustituye al giro como llave · promoción de tres ejes · modo simulación · C8, C9, C10 |
| 0.7 | **aplicado** | v0.2 | Cuenta de control de capturas pendientes · asientos de captura diferida y de fichero · tercera condición de bloqueo · L10 y L11 |
| 0.8 | **aplicado** | v0.2 | Nivel N0 de llave · granularidad conciliable cerrada · cuarta conciliación (de compensación) · K9 |
| 0.9 | **aplicado** | v0.2 | Apartado 4.1 de capacidades que distinguen cámaras · advertencia sobre los dos usos del código · R7 |
| 0.10 | **aplicado** | v0.2 | Apartado 2.2 de identidades de emisor externo · material criptográfico · tercer poder externo · T12 y T13 |
| `openapi-publica.yaml` | **bloque** | — | 7 pendientes. Cuerpo validado intacto (regla 4) |
| `asyncapi-eventos.yaml` | **bloque** | — | 4 pendientes. Cuerpo validado intacto |
| 1.7–1.8 | **bloque** | — | Revisado sin cambios de fondo. Precisión sobre los dos sentidos de «reintento» |
| `ddl-v1.sql` | **bloque** | — | 10 pendientes. Cuerpo ejecutado intacto |
| `ddl-ledger-v1.sql` | **bloque** | — | 5 pendientes. Cuerpo ejecutado intacto |
| 2.4–2.5–2.7 | **bloque** | — | 4 pendientes |
| 3.1–3.4 | **bloque** | — | Prioridad alta. No se regenera: fijaría un perímetro sobre lectura no confirmada |
| 3.5–3.8 | **bloque** | — | 4 pendientes. Advertencia de vigencia de la fuente |
| 3.9–3.11 | **bloque** | — | 5 pendientes. Método de protección de llaves mandatorio |
| `explorador.html` | **aplicado** | — | Campo de estado por documento, badges, leyenda y banner de estado |
| `README.md` raíz y de capa | **aplicado** | — | Reglas 6 y 7, aviso de integridad, estado corregido |

### Por qué los artefactos ejecutables llevan bloque y no regeneración

La regla 4 del repositorio exige que todo artefacto ejecutable haya corrido antes de subirse. El
DDL corrió contra PostgreSQL 16 con sus invariantes probados; el contrato pasó por un validador
real. **Reescribirlos sin volver a ejecutarlos incumpliría la regla que hace confiable al
paquete.** El bloque de cabecera registra qué cambiar y por qué; el cambio se aplica y se
revalida en una sesión dedicada.

### Convención de identificadores provisionales

Las decisiones de esta ronda llevan `N-1` a `N-7` (Parte IV). **No se inventan números `D##`**
mientras 0.3 esté desactualizado: hacerlo produciría exactamente las referencias colgadas que
este documento existe para eliminar. La sustitución es mecánica cuando llegue 0.3.

### Qué quedó sin hacer, y es deliberado

| Pendiente | Por qué |
|---|---|
| Pase completo de la Especificación Estándar de Tokens (233 pp) | Inventariada, no analizada. Va antes de 1.5 |
| Pase completo de Mejores Prácticas de Códigos de Respuesta (58 pp) | Solo verificada la estructura de categorías. Va antes de 1.6 |
| Delta de los capítulos de operativas y de cumplimiento con marcas | Condiciona qué cabe en el piloto |
| Regeneración de 3.1–3.4 | Depende de Q-1 |
| Regeneración de los DDL | Requiere sesión de ejecución contra PostgreSQL 16 |
| Promoción de las dos candidatas a regla irrevocable | C1 no está verificada contra fuente vigente; C2 no es automatizable en pipeline |

---

*Centrix · Control de cambios del paquete · Interno confidencial*
