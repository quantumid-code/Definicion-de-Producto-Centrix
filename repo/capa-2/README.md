# Capa 2 · Datos

Esquemas, retención y datos de prueba.

**Estado: parcial.** 2.1 y 2.6 quedaron desbloqueados. Los dos DDL llevan **bloque de revisión**
y **conservan el cuerpo ejecutado**: corrieron contra PostgreSQL 16 y sus invariantes se
probaron, así que los cambios se aplican y se vuelven a ejecutar en una sesión dedicada, no se
escriben a ciegas.

| Doc | Nombre | Archivo | Estado |
|---|---|---|---|
| 2.4, 2.5, 2.7 | Datos: esquemas, retención, tarjetas de prueba | `2.4-2.5-2.7-datos.md` | **4 pendientes en cabecera** |
| — | DDL transaccional | `ddl-v1.sql` — ejecutado contra PostgreSQL 16 | **10 pendientes en cabecera** |
| — | DDL del libro mayor | `ddl-ledger-v1.sql` — ejecutado contra PostgreSQL 16 | **5 pendientes en cabecera** |
| 2.1 | Migración | — | **desbloqueado, sin generar** |
| 2.6 | Datos de prueba | — | **desbloqueado, sin generar** |

## Los dos cambios de esquema que más pesan

**La tarifa no se indexa por código de giro.** El mismo giro aparece en familias tarifarias
distintas en el catálogo observado. La llave es la **categoría comercial declarada con
vigencia**; el giro pasa a ser atributo de ella. Indexar por giro funciona para la mayoría de
los comercios y falla exactamente en los de clasificación especial, que suelen ser los de mayor
volumen. Invariante C9.

**La cuenta de control de capturas pendientes de compensar.** Su saldo es dinero que el comercio
cree cobrado y que nadie ha compensado. No crece por un error del sistema: crece por una omisión
que no produce ninguna alarma externa. Invariantes L10 y L11.
