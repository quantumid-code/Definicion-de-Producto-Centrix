# Centrix · Delta de consolidación · Rieles, rutas y programas de aceptación

**Documento de enmienda** · Versión 1.0 · 25 de agosto de 2026 · Interno confidencial

Enmienda a: 0.9 Método y riel · 0.2 Modelo canónico · 0.3 Registro de decisiones · 0.4 Reglas irrevocables · 1.5 Contrato del puerto de procesador

> **Este no es un documento nuevo del paquete de 62.** Es un delta. Su contenido se aplica dentro de
> los documentos que enmienda y después se archiva. No debe convertirse en una fuente paralela de
> verdad: eso es exactamente lo que la regla de fuente única prohíbe.

---

## 0 · Numeración — resuelta

El desfase de versiones se reconcilió el 25 de agosto. El `0.3` vigente es la versión 0.5: **36
decisiones con ficha, 14 abiertas en tabla, hasta D51**, y 57 preguntas en la Parte VI.

**D23 está ocupada** por «Nube y región», que es una decisión abierta. La numeración nueva de este
delta arranca en **D52**. La regla candidata arranca en **R9**.

Verificado por script: cero referencias colgantes en el paquete consolidado.

---

## 1 · Por qué existe este delta

Tres insumos consecutivos —el catálogo tarifario, las especificaciones de Prosa y E-Global, y ahora la
documentación de Amex— han empujado en la misma dirección: **la ruta por la que se procesa una
transacción no es un detalle de configuración, es una dimensión del dominio.**

Hasta ahora el proyecto la trataba como dos preguntas separadas: qué cámara y con qué modalidad de
agregación. La documentación de Amex añade una tercera —bajo qué programa de aceptación está afiliado
el comercio— y, más importante, demuestra que **las tres son ortogonales y que la elegibilidad puede
cambiar durante la vida del comercio**.

Ese último punto es el que obliga a modelarlo. Un comercio que crece cruza un umbral y cambia de
programa. Si el programa está cableado en la afiliación, ese comercio se migra a mano. Si está
modelado, es un evento.

**Esto es la promesa de universalidad expresada en arquitectura.** No es «aceptamos todas las marcas»
como afirmación comercial: es que el modelo admite que la misma marca se alcance por rutas distintas
según el comercio, y que la ruta cambie sin tocar el núcleo.

---

## 2 · El modelo de tres coordenadas

Una **ruta** queda determinada por tres coordenadas independientes. Ninguna implica a las otras.

| Coordenada | Qué responde | Valores conocidos hoy |
|---|---|---|
| **Riel** | Dónde se conmuta el mensaje | Prosa · E-Global · red de marca · riel alternativo |
| **Programa de aceptación** | Bajo qué reglas comerciales se afilia el comercio | Estándar de marca · OptBlue · agregación registrada · agregación no registrada |
| **Modo de acceso** | Cómo llega Centrix al riel | Mediado por habilitador · directo certificado |

**Criterio de admisión (D21).** Una dimensión se admite en el modelo solo si se pueden nombrar dos
casos reales que varían en ese eje. Las tres lo cumplen:

- **Riel:** Prosa y E-Global, con dialectos distintos del estándar.
- **Programa:** un comercio pequeño por OptBlue y un comercio grande por el programa estándar de la
  marca. Umbral de por medio.
- **Modo de acceso:** Fase 0 mediada, Fase 1 directa. Ya es la decisión estructural del proyecto.

Las tres son dimensiones del modelo, no campos.

---

## 3 · Capacidades por ruta

Cada combinación de coordenadas tiene un conjunto de capacidades distinto. **No todas las rutas
soportan todas las operaciones**, y ese es el hallazgo que más consecuencias tiene sobre el puerto.

La capacidad se declara, no se infiere. Una operación que la ruta no soporta debe fallar en frontera
con causa canónica —no intentarse y fallar en el dialecto—, porque un rechazo del tercero por
capacidad ausente es indistinguible de un rechazo de negocio y contamina la tasa de aprobación por
causa, que es el argumento de venta de la plataforma (documento 0.11).

**Regla de modelado.** La tabla de capacidades vive en datos maestros de operación (D21, nivel de base
de datos, editable con vigencia y bitácora). Las especificaciones de dialecto que la implementan viven
en configuración de despliegue (D21, nivel de repositorio, no editable desde el portal). **Nunca se
mezclan los dos niveles.**

---

## 4 · Mapa de rutas conocidas

Estado de diseño frente a estado real. Modelar no es construir.

| Ruta | Coordenadas | En el modelo | Se construye |
|---|---|---|---|
| Visa, Mastercard, Carnet por cámara | Prosa · agregación · mediado | Sí | Fase 0 |
| Amex por OptBlue | Prosa · OptBlue · mediado | Sí | Fase 0, sujeto a umbral |
| Amex por programa estándar | red de marca · estándar · directo | Sí | **No hasta que exista comercio que lo exija** |
| Marcas por E-Global | E-Global · agregación · según eje | Sí | Fase 1 |
| Comercio electrónico y botones | según riel · agregación · mediado | Sí | Fase 0 |
| QR de otros rieles | riel alternativo · — · — | Puerto P10, sin contrato | Fase 2 |

**La distinción entre las dos últimas columnas es la que protege el calendario.** Preparar el riel
significa que el canónico, el puerto y la taxonomía admiten la ruta. Construirlo significa adaptador,
dialecto y certificación. Lo primero es barato y se hace ahora. Lo segundo es caro y espera a que haya
demanda real. Confundirlos llena la Fase 0 de extremos muertos que hay que revisar y mantener sin que
nadie los use, y la revisión es el cuello de botella (R7).

---

## 5 · Elegibilidad: la ruta la determina el comercio, no el cliente

Esta es la pieza que no estaba modelada y que cambia el diseño.

Bajo un programa de aceptación como OptBlue existe un **criterio de elegibilidad del comercio** —
**supuesto a verificar: un techo de facturación anual**— por encima del cual el comercio debe
afiliarse bajo el programa estándar de la marca. La consecuencia:

**El programa de aceptación no es un atributo estático de la afiliación. Es el resultado de evaluar al
comercio contra un criterio, y ese resultado puede cambiar.**

De ahí salen cuatro requisitos de modelado:

**1. El criterio de elegibilidad es una entidad, no una constante.** Tiene vigencia, versión y fuente
documental. Cambia por decisión de la marca, no de Centrix.

**2. La evaluación de elegibilidad es un proceso con periodicidad, no un paso de alta.** Se evalúa al
afiliar y se reevalúa. La periodicidad y el disparador quedan por definir (ver Parte 8).

**3. El cambio de programa es un evento con fecha de corte, nunca una edición.** Cambiar el programa
altera tarifa, reglas de presentación y a veces el número de afiliación. Editar el campo en sitio
destruiría la reproducibilidad de una disputa a seis meses, que es exactamente lo que D21 protege.

**4. Ninguna transacción ya presentada se recalcula por un cambio de programa posterior.** Cada
transacción registra la versión de configuración aplicada (D21). El cambio de programa aplica desde su
fecha de corte hacia adelante y nunca hacia atrás.

### Candidato a invariante — provisional

> **Una afiliación pertenece a exactamente un programa de aceptación por marca y riel en un momento
> dado. El cambio de programa se registra como transición con fecha de corte y nunca como edición del
> registro vigente.**

Va a 0.2 como invariante de la entidad afiliación. Si se confirma, sube a 0.4 como regla.

---

## 6 · Decisión nueva

### D52 · Amex se opera por cámara vía OptBlue, no por conexión directa

**Estado: cerrada para Fase 0.**

Amex se alcanza a través de la cámara con la que Centrix se certifica, bajo el programa OptBlue. No se
abre relación de certificación directa con la red de marca.

**Contexto.** Abrir una segunda relación de certificación mientras se opera mediado por habilitador
multiplica el trabajo de certificación sin resolver ninguna compuerta abierta. La autoridad de
comportamiento queda donde D22 la pone: el manual de la cámara con la que se certifica.

**Alternativa descartada: conexión directa a la red de marca.** Descartada para Fase 0, **no
descartada para el modelo**. Es una ruta legítima que el canónico debe admitir, porque es la salida
obligada para el comercio que cruza el umbral de elegibilidad.

**Consecuencia sobre la documentación de marca.** Las especificaciones de autorización y de
presentación de la red de marca dejan de ser especificación de implementación y pasan a ser **fuente
de vocabulario y de segundo mapeo**. Su valor para el proyecto no disminuye: siguen siendo la prueba
de que el puerto es abstracción y no hipótesis (R8), porque hablan una versión del estándar distinta
de la que habla la cámara.

**Consecuencia sobre la propuesta de valor.** La cobertura de Amex bajo esta ruta está acotada por el
criterio de elegibilidad del comercio. Debe redactarse con ese límite explícito antes de comprometerse
por escrito con un agregador.

---

## 7 · Ampliación del alcance del puerto P1

El alcance vigente de 1.5 —autorización, cancelación, devolución, reverso, cierre de lote y consulta—
**es insuficiente**. La documentación de marca exige operaciones que no están contempladas, y una de
ellas es obligatoria para facilitadores de pago en determinados giros.

| Operación | Origen | Por qué entra al puerto |
|---|---|---|
| **Ajuste de autorización** | Marca | Libera el remanente cuando la venta final es menor que lo autorizado. **Obligatoria para facilitadores de pago** en giros con importe indeterminado al inicio |
| **Autorización estimada** | Marca | El importe final no se conoce al iniciar. Cambia la semántica de la intención |
| **Autorización incremental** | Marca | Aumenta un importe ya autorizado sin generar una segunda transacción |
| **Reverso parcial** | Marca | Reversa una fracción. Distinto del reverso total ya contemplado |
| **Verificación de cuenta a valor cero** | Marca | Valida el instrumento sin cargo. Necesaria para alta de instrumento en recurrentes |

**Por qué esto no puede esperar a Fase 1.** El puerto no se dimensiona por lo que la Fase 0 usa: se
dimensiona por lo que debe sobrevivir sin reescritura. Si estas cinco operaciones no están en el
contrato, el primer comercio de hotelería, renta de autos o combustible obliga a modificar el puerto —
y modificar el puerto después de que existan adaptadores es el riesgo E10 materializado.

**Lo que sí puede esperar:** su implementación. El puerto las declara; la ruta de Fase 0 las marca
como capacidad ausente hasta que se confirme lo contrario (ver Parte 8).

**Impacto en la máquina de estados.** La autorización estimada y la incremental rompen el supuesto de
que el importe de la intención es inmutable. Esto es enmienda a 0.2, no solo a 1.5. Debe resolverse
**antes** de escribir 1.5, no después.

---

## 8 · Candidato a invariante desde la presentación

La documentación de presentación de la marca impone una condición de integridad que no es negociable
por contrato ni por urgencia: **los importes de detalle deben cuadrar con los totales de lote y con el
resumen de archivo; un archivo descuadrado se rechaza completo.**

Esto no es una regla de negocio. Es una condición externa cuya violación produce rechazo total de un
lote de liquidación.

### Candidato a regla

> **R9 · Ningún archivo de presentación se transmite sin cuadre interno verificado.**
>
> **Prohíbe.** Emitir un archivo hacia cámara o marca sin verificación previa de que el detalle cuadra
> con los totales de lote y con el resumen de archivo.
>
> **Control.** Verificación en el propio proceso de generación, antes de la transmisión, con la
> transmisión bloqueada si el cuadre falla. Nunca posterior a la transmisión.
>
> **Si falla.** El archivo no sale. Se registra incidente de conciliación y se resuelve antes de
> reintentar.

Aplica a 0.8 y al servicio de conciliación. Elévese a 0.4 si se confirma. Sería la novena regla.

---

## 9 · Preguntas abiertas nuevas

Van a 0.3, Parte VI. Las 57 existentes llegan hasta P57, así que estas son P58 a P62. **Cada una lleva destinatario, porque una pregunta sin destinatario no se cierra nunca.**

| Ref | Pregunta | Destinatario | Bloquea |
|---|---|---|---|
| **P58** | ¿Cuál es el criterio de elegibilidad de OptBlue en México, en qué unidad se mide y con qué periodicidad se evalúa? | Marca o cámara | Propuesta de valor. Prioridad de la ruta directa |
| **P59** | ¿La ruta OptBlue por cámara expone ajuste, estimada, incremental, reverso parcial y verificación a valor cero? ¿Con qué mensajes? | Cámara | Capacidades de ruta en 1.5 |
| **P60** | Bajo OptBlue en Fase 0, ¿de quién es el padrón de números de comercio de la marca: del habilitador o de Centrix? | Habilitador | Propiedad del padrón. Mismo problema que motivó la preferencia por la ruta registrada |
| **P61** | ¿Qué ocurre operativamente cuando un comercio cruza el umbral a mitad de periodo de liquidación? ¿Corte inmediato o al cierre? | Marca o cámara | Máquina de estados del cambio de programa |
| **P62** | La especificación de notificación de archivos disponible es de 2017 mientras las demás son de 2026. ¿Existe versión vigente? | Marca | Lazo de realimentación de conciliación |

**P58 es la de mayor apalancamiento.** Si el umbral es alto, la ruta directa es teórica durante todo el
piloto y baja de prioridad de construcción, aunque se quede modelada. Si es bajo, hay que saber ya
cuántos comercios del agregador piloto quedan fuera de cobertura Amex.

---

## 10 · Lo que este delta no decide

- **No decide el ruteo.** Qué ruta se elige ante varias elegibles es materia de 1.5 y del servicio de
  ruteo. Aquí solo se establece que la ruta es una dimensión y que las capacidades se declaran.
- **No decide tarifas por programa.** Depende del catálogo tarifario y de respuestas pendientes.
- **No abre trabajo de construcción.** Ninguna ruta marcada como «no se construye» genera tarea.
- **No modifica H1.** Los documentos de marca son insumos analíticos que afinan el diseño propio de
  Centrix. No redirigen la premisa del proyecto.

---

## 11 · Orden de aplicación

1. ~~Reconciliar versiones.~~ **Hecho el 25 de agosto.**
2. Aplicar la enmienda de la máquina de estados de la intención a **0.2** — importe mutable bajo
   autorización estimada e incremental. **Bloquea a 1.5.**
3. Aplicar coordenadas de ruta y capacidades a **0.9**.
4. Registrar D52 y las cinco preguntas en **0.3**.
5. Evaluar R9 para **0.4**.
6. Escribir **1.5** con el alcance ampliado y tres dialectos reales de contraste.
7. Escribir **4.4** derivado de 1.5.

**El paso 2 es el que no puede saltarse.** Escribir 1.5 sobre una máquina de estados que supone
importe inmutable produce un puerto que hay que reabrir en cuanto aparezca el primer hotel.

---

*Centrix · Documento de enmienda · Interno confidencial*
