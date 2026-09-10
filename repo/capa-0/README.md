# Capa 0 · Fundamentos

Vocabulario, modelo canónico, decisiones e invariantes. Lo que ninguna otra capa
puede contradecir.

**Estado: 11 de 12.** Nueve documentos regenerados a **v0.2** el 9 de septiembre de 2026
contra los manuales vigentes de Prosa y E-Global. Trazabilidad en `CONTROL-CAMBIOS.md`.

| Doc | Nombre | Estado |
|---|---|---|
| 0.1 | Glosario canónico | **v0.2** · doce términos nuevos; apartado 2 nuevo |
| 0.2 | Modelo canónico | **v0.2** · entidad e invariantes nuevos (I16–I18) |
| 0.3 | Registro de decisiones — incluye Parte VI, preguntas abiertas `P##` | **bloqueado · desactualizado** |
| 0.4 | Reglas irrevocables | **v0.2** · siguen siendo ocho; dos candidatas no promovidas |
| 0.5 | Modelo monetario | **v0.2** · importe compuesto; M8 y M9 |
| 0.6 | Motor de comisiones | **v0.2** · escenario de agregación; C8–C10 |
| 0.7 | Modelo contable | **v0.2** · compensación por fichero; L10 y L11 |
| 0.8 | Movimiento conciliatorio | **v0.2** · nivel N0; cuarta conciliación; K9 |
| 0.9 | Método y riel | **v0.2** · capacidades que distinguen cámaras; R7 |
| 0.10 | Identidad multi-tenant | **v0.2** · identidades de emisor externo; T12 y T13 |
| 0.11 | Máquina de estados de llaves de terminal | **desbloqueado, sin generar** |
| 0.12 | Prohibiciones para agentes | vigente, sin cambios |

## Aviso sobre 0.3

**Es prerrequisito de todo lo demás.** La copia de este repositorio define hasta D22 y no
contiene la Parte VI, pero el resto del paquete cita hasta D46 y la regla 5 del README raíz
apunta a esa sección inexistente.

Consecuencia práctica: las decisiones nuevas de esta ronda llevan **identificador provisional
`N-1` a `N-7`**, definidos en `CONTROL-CAMBIOS.md` Parte IV. Se sustituyen por `D##` cuando se
reemplace 0.3. **No se inventan números de decisión.**

## Los tres invariantes nuevos que más pesan

- **I16** — ninguna terminal sin llaves inicializadas emite. Una sola arrastra a Centrix al
  alcance máximo de cumplimiento, y nadie lo decide: es el estado de fábrica.
- **I17** — nada se marca compensado sin fichero confirmado. Es **la única pérdida del modelo
  que no produce ninguna señal de error**.
- **I18** — todo declinado lleva categoría de rechazo, y lo definitivo no se reintenta. El
  exceso tiene consecuencia ante marca sobre la afiliación entera.
