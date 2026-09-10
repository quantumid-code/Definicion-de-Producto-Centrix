# Capa 3 · Arquitectura e infraestructura

Descomposición en servicios, alcance de cumplimiento, despliegue y seguridad.

**Estado: los tres documentos llevan bloque de revisión.** Se escribieron cuando la única fuente
disponible era una versión del manual de cámara **superada por tres años y medio de control de
cambios**. No se regeneran todavía porque el pase completo de los capítulos correspondientes
está pendiente.

| Doc | Nombre | Archivo | Estado |
|---|---|---|---|
| 3.1–3.4 | Servicios y alcance de cumplimiento | `3.1-3.4-servicios-y-alcance.md` | **prioridad alta** |
| 3.5–3.8 | Infraestructura, multitenant y observabilidad | `3.5-3.8-infraestructura.md` | 4 pendientes |
| 3.9–3.11 | Secretos, llaves, IaC y modelo de amenazas | `3.9-3.11-seguridad.md` | 5 pendientes |

## Por qué 3.1–3.4 no se regenera todavía

**Define el alcance de cumplimiento, y ese alcance tiene hoy una zona sin resolver.**
Regenerarlo exigiría fijar un perímetro sobre una lectura que aún no está confirmada, y un
perímetro mal fijado es peor que uno pendiente.

Lo verificado: en el mensaje de **autorización** el contenido de pista no viaja en el campo, va
cifrado, y el manual atribuye el cambio a normativa del regulador bancario mexicano. D1b se
sostiene ahí **por mandato regulatorio, no por acuerdo comercial**.

Lo no resuelto — **Q-1**: en el mensaje de **aviso** el manual admite pista recortada con número
de cuenta completo, mientras la especificación de agregadores afirma que esos campos quedan
protegidos por el cifrado del canal. Las dos lecturas dan perímetros distintos. Es la pregunta
más importante del paquete.

## Lo que cambia en 3.9–3.11

El método de protección de llaves es **mandatorio en cámara**, no una buena práctica, y su
intercambio ocurre por la propia mensajería financiera. La decisión sobre el módulo criptográfico
se tomó sin conocerlo: cambia los requisitos de la pieza y sus plazos de adquisición, así que el
impacto es de calendario. El detalle de campos vive en un documento de cámara que **no tenemos**
(X-1) y bloquea el documento 0.11.
