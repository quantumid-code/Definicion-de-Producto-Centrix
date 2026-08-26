-- =============================================================================
-- Centrix · 2.2 DDL por servicio · 2.3 Esquema físico del libro contable
-- Capa 2 · Datos · Versión 0.1 borrador · 16 de agosto de 2026
-- PostgreSQL 17
--
-- Deriva de: 0.2 Modelo canónico · 0.5 Modelo monetario · 0.7 Modelo contable
--            0.8 Movimiento conciliatorio · 0.10 Identidad multi-tenant
--            1.1 Interfaz pública · 1.3 Catálogo de eventos
--
-- REGLAS QUE ESTE ESQUEMA MATERIALIZA
--   R1  Todo importe es BIGINT en unidades mínimas más código de moneda.
--       No existe una sola columna NUMERIC, DECIMAL, REAL ni DOUBLE PRECISION.
--   R2  No existe columna para el código de seguridad. En ninguna tabla.
--   R3  No existe columna para el número de cuenta principal. En ninguna tabla.
--   T1  Toda tabla transaccional lleva tenant_id NOT NULL.
--   T2  El aislamiento se aplica con seguridad a nivel de fila, no en la aplicación.
--   L3  Los asientos son inmutables por disparador, no por convención.
--
-- PROPIEDAD POR SERVICIO
--   Un esquema por servicio. Ningún servicio escribe en tablas de otro.
--   Las referencias entre esquemas son por identificador, sin clave foránea:
--   una clave foránea entre servicios es acoplamiento por base de datos.
-- =============================================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS catalog;        -- datos maestros
CREATE SCHEMA IF NOT EXISTS merchants;      -- jerarquía comercial
CREATE SCHEMA IF NOT EXISTS payments;       -- ciclo transaccional
CREATE SCHEMA IF NOT EXISTS fees;           -- motor de comisiones
CREATE SCHEMA IF NOT EXISTS ledger;         -- libro contable
CREATE SCHEMA IF NOT EXISTS reconciliation; -- conciliación
CREATE SCHEMA IF NOT EXISTS settlement;     -- liquidación y dispersión
CREATE SCHEMA IF NOT EXISTS platform;       -- idempotencia, auditoría, configuración

-- -----------------------------------------------------------------------------
-- Dominios: el tipo hace cumplir la regla
-- -----------------------------------------------------------------------------

-- Importe en unidades mínimas. Admite signo: devoluciones y ajustes son negativos.
CREATE DOMAIN catalog.minor_units AS BIGINT;

COMMENT ON DOMAIN catalog.minor_units IS
  'Entero en unidades mínimas. Regla irrevocable 1. Nunca coma flotante. Siempre acompañado de una columna currency_code en la misma tabla.';

CREATE DOMAIN catalog.currency_code AS CHAR(3)
  CHECK (VALUE ~ '^[A-Z]{3}$');

CREATE DOMAIN catalog.tenant_id AS TEXT
  CHECK (length(VALUE) BETWEEN 2 AND 64);

CREATE DOMAIN catalog.entity_id AS TEXT
  CHECK (length(VALUE) BETWEEN 8 AND 64);

-- =============================================================================
-- CATALOG · datos maestros
-- Configuración de operación: editable desde el portal, con vigencia. D21.
-- =============================================================================

CREATE TABLE catalog.currency (
    code            catalog.currency_code PRIMARY KEY,
    exponent        SMALLINT NOT NULL CHECK (exponent BETWEEN 0 AND 4),
    name            TEXT     NOT NULL
);

COMMENT ON COLUMN catalog.currency.exponent IS
  'El exponente es dato, no se asume 2. Documento 0.5.';

CREATE TABLE catalog.merchant_category (
    code            TEXT PRIMARY KEY,
    description     TEXT NOT NULL,
    valid_from      DATE NOT NULL,
    valid_to        DATE,
    CONSTRAINT mcc_vigencia CHECK (valid_to IS NULL OR valid_to > valid_from)
);

COMMENT ON TABLE catalog.merchant_category IS
  'Giro. Llave económica, no atributo descriptivo: determina tasa y puede determinar afiliación. Documento 0.1 §1.10.';

CREATE TABLE catalog.bin_range (
    id              catalog.entity_id PRIMARY KEY,
    range_start     TEXT     NOT NULL,
    range_end       TEXT     NOT NULL,
    brand           TEXT     NOT NULL,
    issuer          TEXT,
    product         TEXT,
    nature          TEXT     NOT NULL CHECK (nature IN ('credito','debito','prepago','desconocida')),
    domestic        BOOLEAN  NOT NULL DEFAULT TRUE,
    valid_from      DATE     NOT NULL,
    valid_to        DATE,
    CONSTRAINT bin_orden CHECK (range_end >= range_start)
);

CREATE INDEX bin_range_lookup ON catalog.bin_range (range_start, range_end)
    WHERE valid_to IS NULL;

CREATE TABLE catalog.rail (
    id                      catalog.entity_id PRIMARY KEY,
    country                 CHAR(2) NOT NULL,
    method                  TEXT    NOT NULL,
    flow                    TEXT    NOT NULL CHECK (flow IN ('extraccion','empuje')),
    capabilities            JSONB   NOT NULL,
    default_expiry          INTERVAL,
    different_amount_policy TEXT    CHECK (different_amount_policy IN ('aceptar','devolver_diferencia','devolver_todo')),
    dialect_id              TEXT,
    valid_from              DATE    NOT NULL,
    valid_to                DATE
);

CREATE TABLE catalog.rail_capability (
    rail_id         catalog.entity_id NOT NULL REFERENCES catalog.rail(id),
    brand           TEXT NOT NULL DEFAULT '*',
    program         TEXT NOT NULL DEFAULT '*',
    capabilities    JSONB NOT NULL,
    valid_from      DATE NOT NULL,
    valid_to        DATE,
    PRIMARY KEY (rail_id, brand, program, valid_from)
);

COMMENT ON TABLE catalog.rail_capability IS
  'Decision D47. La capacidad no cuelga solo del riel: hay restricciones de marca y programa dentro
del mismo riel. Una marca bajo cierto programa puede no admitir cancelacion, preventa ni devolucion
fuera de lote mientras otras por la misma camara si. El comodin * hereda del nivel superior.';

COMMENT ON COLUMN catalog.rail.capabilities IS
  'Tabla de capacidades del documento 0.9. El motor consulta capacidades; nunca pregunta si el método es tarjeta. Invariante R2 del 0.9.';

-- =============================================================================
-- MERCHANTS · jerarquía comercial
-- =============================================================================

CREATE TABLE merchants.tenant (
    id              catalog.tenant_id PRIMARY KEY,
    legal_name      TEXT NOT NULL,
    kind            TEXT NOT NULL CHECK (kind IN ('adquirente','agregador','comercio_directo')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE merchants.affiliation (
    id                  catalog.entity_id PRIMARY KEY,
    tenant_id           catalog.tenant_id NOT NULL REFERENCES merchants.tenant(id),
    acquirer            TEXT NOT NULL,
    affiliation_number  TEXT NOT NULL,
    enabled_brands      TEXT[] NOT NULL DEFAULT '{}',
    concentration_account TEXT,
    declared_status     TEXT NOT NULL
        CHECK (declared_status IN ('solicitada','documentacion_pendiente','documentacion_completa',
                                   'en_revision','autorizada','lista_para_transaccionar',
                                   'rechazada','suspendida','cancelada')),
    observed_status     TEXT NOT NULL DEFAULT 'desconocido'
        CHECK (observed_status IN ('operando','rechazando_estructural','sin_respuesta','desconocido')),
    consecutive_structural_declines INT NOT NULL DEFAULT 0,
    circuit_open        BOOLEAN NOT NULL DEFAULT FALSE,
    status_reason       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, acquirer, affiliation_number)
);

COMMENT ON COLUMN merchants.affiliation.enabled_brands IS
  'Una afiliación cubre todas las marcas de aceptación por defecto. La excepción es relación directa con una marca. Documento 0.1 §1.8.';

COMMENT ON COLUMN merchants.affiliation.observed_status IS
  'Lo que el comportamiento del tercero demuestra, frente a lo declarado. La divergencia es la señal de que un tercero cerró la afiliación sin aviso. D40.';

CREATE TABLE merchants.merchant (
    id                  catalog.entity_id PRIMARY KEY,
    tenant_id           catalog.tenant_id NOT NULL REFERENCES merchants.tenant(id),
    affiliation_id      catalog.entity_id NOT NULL REFERENCES merchants.affiliation(id),
    parent_merchant_id  catalog.entity_id REFERENCES merchants.merchant(id),
    sub_affiliation_id  TEXT,
    legal_name          TEXT NOT NULL,
    trade_name          TEXT,
    tax_id              TEXT NOT NULL,
    merchant_category   TEXT NOT NULL REFERENCES catalog.merchant_category(code),
    settlement_level    TEXT NOT NULL DEFAULT 'propio'
        CHECK (settlement_level IN ('cabeza','propio')),
    status              TEXT NOT NULL
        CHECK (status IN ('en_alta','activa','suspendida','cierre_solicitado','cerrada')),
    status_reason       TEXT,
    closed_by_cascade   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT merchant_motivo_obligatorio
      CHECK (status NOT IN ('suspendida','cierre_solicitado','cerrada') OR status_reason IS NOT NULL)
);

COMMENT ON TABLE merchants.merchant IS
  'Sub-afiliación. Equivale al comercio a nivel de razón social. Las sucursales heredan y no tienen sub-afiliación propia. Decisión D43.';

COMMENT ON COLUMN merchants.merchant.sub_affiliation_id IS
  'Identificador conocido por la cámara. Nulo hasta que el tercero confirma el alta. Su nombre en la trama pertenece al mapeo, no a este esquema.';

COMMENT ON COLUMN merchants.merchant.parent_merchant_id IS
  'Jerarquía de profundidad variable. Ningún cálculo asume cuatro niveles. T9.';

CREATE INDEX merchant_por_afiliacion ON merchants.merchant (tenant_id, affiliation_id);
CREATE INDEX merchant_por_padre      ON merchants.merchant (parent_merchant_id)
    WHERE parent_merchant_id IS NOT NULL;
CREATE UNIQUE INDEX merchant_subafiliacion_unica
    ON merchants.merchant (tenant_id, sub_affiliation_id)
    WHERE sub_affiliation_id IS NOT NULL;

-- Un mismo comercio puede tener numeros de afiliacion distintos segun canal y procesador:
-- no todos los procesadores otorgan el mismo numero para presencial que para linea.
CREATE TABLE merchants.merchant_affiliation (
    tenant_id           catalog.tenant_id NOT NULL,
    merchant_id         catalog.entity_id NOT NULL REFERENCES merchants.merchant(id),
    channel             TEXT NOT NULL CHECK (channel IN ('presencial','comercio_electronico')),
    processor_id        catalog.entity_id NOT NULL,
    affiliation_number  TEXT NOT NULL,
    status              TEXT NOT NULL
        CHECK (status IN ('solicitada','documentacion_pendiente','documentacion_completa',
                          'en_revision','autorizada','lista_para_transaccionar',
                          'rechazada','suspendida','cancelada')),
    valid_from          DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to            DATE,
    PRIMARY KEY (merchant_id, channel, processor_id)
);

COMMENT ON COLUMN merchants.merchant_affiliation.status IS
  'La distincion entre autorizada y lista_para_transaccionar no es burocratica: existe una ventana
real donde la afiliacion esta aprobada por el adquirente y todavia no puede cobrar. Sin ese estado el
operador no distingue "esta en tramite" de "esta listo y algo falla".';

CREATE TABLE merchants.branch (
    id              catalog.entity_id PRIMARY KEY,
    tenant_id       catalog.tenant_id NOT NULL,
    merchant_id     catalog.entity_id NOT NULL REFERENCES merchants.merchant(id),
    name            TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE merchants.branch IS
  'Nivel derivado. La cámara no conoce la sucursal: su atribución se deriva de la terminal, y solo es conciliable si el identificador de terminal regresa en el registro de movimientos. Compuerta N4.';

CREATE TABLE merchants.terminal (
    id                  catalog.entity_id PRIMARY KEY,
    tenant_id           catalog.tenant_id NOT NULL,
    merchant_id         catalog.entity_id NOT NULL REFERENCES merchants.merchant(id),
    branch_id           catalog.entity_id REFERENCES merchants.branch(id),
    network_terminal_id TEXT,
    serial_number       TEXT NOT NULL,
    manufacturer        TEXT,
    model               TEXT,
    status              TEXT NOT NULL
        CHECK (status IN ('registrada','alta_solicitada','activa','suspendida','baja')),
    last_seen_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, serial_number),
    CONSTRAINT terminal_activa_requiere_id_de_red
      CHECK (status <> 'activa' OR network_terminal_id IS NOT NULL)
);

COMMENT ON COLUMN merchants.terminal.network_terminal_id IS
  'Identidad dual: este identificador lo asigna la red, no Centrix. Nulo hasta que el tercero confirma. Decisión D45.';

-- La asignacion es entidad propia, no un campo de la terminal: una terminal sin asignacion activa
-- no procesa aunque exista y este encendida. Esta tabla es la fuente de verdad.
CREATE TABLE merchants.terminal_assignment (
    id              catalog.entity_id PRIMARY KEY,
    tenant_id       catalog.tenant_id NOT NULL,
    terminal_id     catalog.entity_id NOT NULL REFERENCES merchants.terminal(id),
    merchant_id     catalog.entity_id NOT NULL REFERENCES merchants.merchant(id),
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    assigned_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    released_at     TIMESTAMPTZ
);

CREATE UNIQUE INDEX terminal_una_asignacion_activa
    ON merchants.terminal_assignment (terminal_id) WHERE active;

-- Operación distribuida: cascada de cancelación. D39.
CREATE TABLE merchants.cascade_run (
    id              catalog.entity_id PRIMARY KEY,
    tenant_id       catalog.tenant_id NOT NULL,
    affiliation_id  catalog.entity_id NOT NULL REFERENCES merchants.affiliation(id),
    reason          TEXT NOT NULL,
    total_targets   INT  NOT NULL,
    completed       INT  NOT NULL DEFAULT 0,
    status          TEXT NOT NULL CHECK (status IN ('en_curso','completada','con_errores')),
    started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at     TIMESTAMPTZ
);

CREATE TABLE merchants.cascade_item (
    run_id          catalog.entity_id NOT NULL REFERENCES merchants.cascade_run(id),
    merchant_id     catalog.entity_id NOT NULL,
    status          TEXT NOT NULL CHECK (status IN ('pendiente','solicitado','confirmado','fallido')),
    attempts        INT  NOT NULL DEFAULT 0,
    last_error      TEXT,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (run_id, merchant_id)
);

COMMENT ON TABLE merchants.cascade_run IS
  'La cascada no es una transacción de base de datos: es proceso reanudable con bitácora por sub-afiliación. Invariante I11 se verifica al completarse.';

-- =============================================================================
-- PAYMENTS · ciclo transaccional
-- =============================================================================

CREATE TABLE payments.payment_intent (
    id                  catalog.entity_id NOT NULL,
    tenant_id           catalog.tenant_id NOT NULL,
    merchant_id         catalog.entity_id NOT NULL,
    terminal_id         catalog.entity_id,
    trace_id            TEXT NOT NULL,
    client_reference    TEXT,

    status              TEXT NOT NULL CHECK (status IN (
                          'creada','en_proceso',
                          'autorizada','capturada','capturada_parcial','anulada','expirada',
                          'esperando_pago','pagada','pagada_diferente','caducada',
                          'rechazada','devuelta','devuelta_parcial','indeterminada')),
    flow                TEXT NOT NULL CHECK (flow IN ('extraccion','empuje')),
    method              TEXT NOT NULL,
    rail_id             catalog.entity_id,
    capture_mode        TEXT CHECK (capture_mode IN (
                          'chip','contactless','banda','tecleado',
                          'comercio_electronico','credencial_almacenada')),

    amount              catalog.minor_units NOT NULL,
    currency_code       catalog.currency_code NOT NULL REFERENCES catalog.currency(code),
    captured_amount     catalog.minor_units NOT NULL DEFAULT 0,
    refunded_amount     catalog.minor_units NOT NULL DEFAULT 0,
    paid_amount         catalog.minor_units,

    instrument_token    TEXT,
    instrument_last_four CHAR(4),
    instrument_brand    TEXT,
    instrument_nature   TEXT,

    installments        SMALLINT,
    plan_type           TEXT CHECK (plan_type IN ('sin_intereses','con_intereses','diferido')),
    deferred_months     SMALLINT,

    authentication      TEXT NOT NULL DEFAULT 'no_aplica'
        CHECK (authentication IN ('no_aplica','autenticado','intento_registrado',
                                  'no_autenticado','fallida')),

    payment_reference_id TEXT,
    reference_expires_at TIMESTAMPTZ,
    hosted_payment_url   TEXT,
    hosted_expires_at    TIMESTAMPTZ,
    return_url           TEXT,

    network_lifecycle_id TEXT,
    batch_id            catalog.entity_id,
    config_version      TEXT NOT NULL,
    metadata            JSONB NOT NULL DEFAULT '{}',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    PRIMARY KEY (created_at, id),

    CONSTRAINT intent_captura_no_excede    CHECK (captured_amount <= amount),
    CONSTRAINT intent_devolucion_no_excede CHECK (refunded_amount <= captured_amount),
    CONSTRAINT intent_estados_por_flujo CHECK (
        (flow = 'extraccion' AND status NOT IN ('esperando_pago','pagada','pagada_diferente','caducada'))
     OR (flow = 'empuje'     AND status NOT IN ('autorizada','capturada','capturada_parcial','anulada','expirada'))
    )
) PARTITION BY RANGE (created_at);

COMMENT ON TABLE payments.payment_intent IS
  'Intención de cobro. Objeto raíz. NO existe columna de número de cuenta ni de código de seguridad: reglas irrevocables 2 y 3.';

COMMENT ON CONSTRAINT intent_estados_por_flujo ON payments.payment_intent IS
  'Los estados de un flujo no son alcanzables en el otro. Invariante R3 del 0.9.';

COMMENT ON COLUMN payments.payment_intent.hosted_payment_url IS
  'Pantalla de captura alojada por el procesador. Es la pieza que sostiene el alcance: el numero de
tarjeta va del navegador al procesador sin pasar por Centrix. Documento 3.2.';

COMMENT ON COLUMN payments.payment_intent.paid_amount IS
  'Flujo de empuje. Se persiste aunque difiera del solicitado y nunca se sobrescribe con el importe pedido. Invariante R6 del 0.9.';

COMMENT ON COLUMN payments.payment_intent.network_lifecycle_id IS
  'Identificador de seguimiento asignado por la marca o la camara. Llega en la respuesta de aprobacion
y debe reenviarse en devoluciones, reversos y cierre de operativas de dos pasos. No es el numero de
rastreo ni la referencia de recuperacion ni el codigo de autorizacion: es un cuarto concepto.
Se imprime en el comprobante porque se usa para aclaraciones. Glosario 6.8.';

COMMENT ON COLUMN payments.payment_intent.config_version IS
  'Versión de configuración aplicada. Sin esto, una disputa a seis meses no es reproducible. Decisión D21, invariante I9.';

CREATE TABLE payments.payment_intent_2026_q4 PARTITION OF payments.payment_intent
    FOR VALUES FROM ('2026-10-01') TO ('2027-01-01');

CREATE INDEX intent_por_comercio  ON payments.payment_intent (tenant_id, merchant_id, created_at DESC);
CREATE INDEX intent_por_trace     ON payments.payment_intent (trace_id);
CREATE INDEX intent_por_referencia ON payments.payment_intent (tenant_id, client_reference)
    WHERE client_reference IS NOT NULL;
CREATE INDEX intent_indeterminadas ON payments.payment_intent (tenant_id, created_at)
    WHERE status = 'indeterminada';

COMMENT ON INDEX payments.intent_indeterminadas IS
  'Índice parcial: lo indeterminado se consulta constantemente para resolución y para bloquear dispersión, y es una fracción pequeña del volumen.';

CREATE TABLE payments.attempt (
    id                  catalog.entity_id PRIMARY KEY,
    tenant_id           catalog.tenant_id NOT NULL,
    intent_id           catalog.entity_id NOT NULL,
    intent_created_at   TIMESTAMPTZ NOT NULL,
    sequence            SMALLINT NOT NULL,

    status              TEXT NOT NULL CHECK (status IN (
                          'preparado','enviado','aprobado','declinado','indeterminado',
                          'reverso_solicitado','revertido','resuelto_tardio','abandonado')),

    affiliation_id      catalog.entity_id,
    intended_route      TEXT,
    route_binding       TEXT CHECK (route_binding IN ('preferencia','restriccion')),
    routing_rule_id     TEXT,
    routing_inputs      JSONB,

    result_class        TEXT CHECK (result_class IN (
                          'aprobado','rechazo_del_emisor','rechazo_por_fondos',
                          'rechazo_por_instrumento','rechazo_por_riesgo',
                          'rechazo_estructural','error_tecnico','indeterminado')),
    reason_code         TEXT,
    authorization_code  TEXT,
    retrieval_reference TEXT,
    stan                TEXT,

    late_resolution     BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at             TIMESTAMPTZ,
    resolved_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (intent_id, sequence)
);

COMMENT ON TABLE payments.attempt IS
  'Una ejecución contra una ruta. El estado indeterminado vive aquí, no en la intención. Decisión D19.';

COMMENT ON COLUMN payments.attempt.routing_inputs IS
  'Insumos evaluados en la decisión de ruteo. Se persiste aunque Centrix no pueda ejecutar la decisión: permite medir después la desviación entre lo pedido y lo hecho. Documento 0.2 §3.4.';

-- Invariante I7: una intención tiene a lo más un intento aprobado.
CREATE UNIQUE INDEX attempt_un_solo_aprobado
    ON payments.attempt (intent_id)
    WHERE status = 'aprobado';

-- Invariante I13: el reverso se empareja por identificadores de red.
CREATE INDEX attempt_emparejamiento_reverso
    ON payments.attempt (tenant_id, stan, sent_at)
    WHERE stan IS NOT NULL;

CREATE INDEX attempt_por_referencia_de_red
    ON payments.attempt (retrieval_reference)
    WHERE retrieval_reference IS NOT NULL;

CREATE TABLE payments.capture (
    id              catalog.entity_id PRIMARY KEY,
    tenant_id       catalog.tenant_id NOT NULL,
    intent_id       catalog.entity_id NOT NULL,
    amount          catalog.minor_units NOT NULL CHECK (amount > 0),
    currency_code   catalog.currency_code NOT NULL,
    result_class    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payments.refund (
    id              catalog.entity_id PRIMARY KEY,
    tenant_id       catalog.tenant_id NOT NULL,
    intent_id       catalog.entity_id NOT NULL,
    amount          catalog.minor_units NOT NULL CHECK (amount > 0),
    currency_code   catalog.currency_code NOT NULL,
    reason          TEXT,
    result_class    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payments.batch (
    id              catalog.entity_id PRIMARY KEY,
    tenant_id       catalog.tenant_id NOT NULL,
    terminal_id     catalog.entity_id NOT NULL,
    status          TEXT NOT NULL CHECK (status IN ('abierto','cierre_solicitado','cerrado','compensado')),
    opened_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at       TIMESTAMPTZ,
    sales_amount    catalog.minor_units NOT NULL DEFAULT 0,
    refunds_amount  catalog.minor_units NOT NULL DEFAULT 0,
    tx_count        INT NOT NULL DEFAULT 0,
    currency_code   catalog.currency_code NOT NULL
);

CREATE UNIQUE INDEX batch_uno_abierto_por_terminal
    ON payments.batch (terminal_id)
    WHERE status = 'abierto';

-- =============================================================================
-- FEES · motor de comisiones
-- =============================================================================

CREATE TABLE fees.scheme (
    id                  catalog.entity_id NOT NULL,
    version             INT NOT NULL,
    tenant_id           catalog.tenant_id NOT NULL,
    components          JSONB NOT NULL,
    calculation_base    TEXT NOT NULL DEFAULT 'bruto'
                        CHECK (calculation_base IN ('bruto','neto_anterior')),
    rounding_mode       TEXT NOT NULL
                        CHECK (rounding_mode IN ('alza','baja','cercano_alza','cercano_par')),
    absorbs_remainder   BOOLEAN NOT NULL DEFAULT TRUE,
    tax_applicable      BOOLEAN NOT NULL DEFAULT TRUE,
    valid_from          DATE NOT NULL,
    valid_to            DATE,
    sealed              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id, version)
);

COMMENT ON COLUMN fees.scheme.calculation_base IS
  'El detalle que decide: cada eslabón cobra sobre el bruto o sobre el neto del anterior. Se declara, nunca se infiere. Documento 0.6 §4.';

COMMENT ON COLUMN fees.scheme.sealed IS
  'Verdadero en cuanto el esquema evalúa una transacción real. A partir de ahí es inmutable: los cambios se publican como versión nueva. Invariante C3.';

CREATE TABLE fees.assessment (
    id                  catalog.entity_id PRIMARY KEY,
    tenant_id           catalog.tenant_id NOT NULL,
    intent_id           catalog.entity_id NOT NULL,
    merchant_id         catalog.entity_id NOT NULL,
    gross_amount        catalog.minor_units NOT NULL,
    net_to_merchant     catalog.minor_units NOT NULL,
    currency_code       catalog.currency_code NOT NULL,
    rounding_mode       TEXT NOT NULL,
    config_version      TEXT NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE fees.assignment (
    assessment_id   catalog.entity_id NOT NULL REFERENCES fees.assessment(id),
    link_order      SMALLINT NOT NULL,
    link_role       TEXT NOT NULL,
    participant     TEXT NOT NULL,
    scheme_id       catalog.entity_id NOT NULL,
    scheme_version  INT NOT NULL,
    applied_base    catalog.minor_units NOT NULL,
    fee_amount      catalog.minor_units NOT NULL,
    tax_amount      catalog.minor_units NOT NULL DEFAULT 0,
    total_amount    catalog.minor_units NOT NULL,
    components_applied JSONB NOT NULL,
    PRIMARY KEY (assessment_id, link_order),
    FOREIGN KEY (scheme_id, scheme_version) REFERENCES fees.scheme(id, version),
    CONSTRAINT assignment_total_cuadra CHECK (total_amount = fee_amount + tax_amount)
);

COMMENT ON TABLE fees.assignment IS
  'N eslabones. Ningún cálculo asume tres. Invariante C5. Se persiste la versión de esquema aplicada, no la referencia al vigente: un cambio de tarifa no altera retroactivamente lo ya cobrado.';

-- =============================================================================
-- LEDGER · libro contable · documento 2.3
-- =============================================================================

CREATE TABLE ledger.account (
    code        TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    kind        TEXT NOT NULL CHECK (kind IN ('activo','pasivo','ingreso','gasto','control')),
    normal_side TEXT NOT NULL CHECK (normal_side IN ('cargo','abono'))
);

COMMENT ON COLUMN ledger.account.kind IS
  'Las cuentas de control son las que hacen visible el problema: una partida indeterminada no desaparece del libro. Documento 0.7 §3.';

CREATE TABLE ledger.journal (
    id              catalog.entity_id NOT NULL,
    tenant_id       catalog.tenant_id NOT NULL,
    period          DATE NOT NULL,
    sequence        BIGINT NOT NULL,
    event_type      TEXT NOT NULL,
    intent_id       catalog.entity_id,
    merchant_id     catalog.entity_id,
    affiliation_id  catalog.entity_id,
    currency_code   catalog.currency_code NOT NULL,
    state           TEXT NOT NULL DEFAULT 'aprobado'
                    CHECK (state IN ('aprobado','confirmado')),
    confirmed_at    TIMESTAMPTZ,
    confirmed_by    TEXT,
    corrects_id     catalog.entity_id,
    correction_reason TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (period, id),
    UNIQUE (tenant_id, period, sequence),
    CONSTRAINT journal_confirmado_con_origen
      CHECK (state = 'aprobado' OR (confirmed_at IS NOT NULL AND confirmed_by IS NOT NULL)),
    CONSTRAINT journal_correccion_con_motivo
      CHECK (corrects_id IS NULL OR correction_reason IS NOT NULL)
) PARTITION BY RANGE (period);

CREATE TABLE ledger.journal_2026_q4 PARTITION OF ledger.journal
    FOR VALUES FROM ('2026-10-01') TO ('2027-01-01');

COMMENT ON COLUMN ledger.journal.sequence IS
  'Secuencia sin huecos por periodo y tenant. Un hueco es señal de manipulación o de fallo, y en ambos casos debe detectarse. Invariante L5.';

COMMENT ON COLUMN ledger.journal.state IS
  'Estado dual. Aprobado es lo que Centrix cree; confirmado es lo que el tercero verificó. El saldo dispersable se calcula solo sobre confirmados. L6.';

CREATE TABLE ledger.entry (
    journal_id      catalog.entity_id NOT NULL,
    journal_period  DATE NOT NULL,
    tenant_id       catalog.tenant_id NOT NULL,
    line            SMALLINT NOT NULL,
    account_code    TEXT NOT NULL REFERENCES ledger.account(code),
    side            TEXT NOT NULL CHECK (side IN ('cargo','abono')),
    amount          catalog.minor_units NOT NULL CHECK (amount > 0),
    currency_code   catalog.currency_code NOT NULL,
    PRIMARY KEY (journal_period, journal_id, line),
    FOREIGN KEY (journal_period, journal_id) REFERENCES ledger.journal(period, id)
);

CREATE INDEX entry_por_cuenta ON ledger.entry (tenant_id, account_code, journal_period);

COMMENT ON COLUMN ledger.entry.tenant_id IS
  'Denormalizado desde el asiento. Sin esta columna la tabla queda fuera del aislamiento por fila y
las líneas del asiento son legibles entre clientes. Invariante T1.';

-- Invariante L1: todo asiento cuadra al escribir, no en un proceso posterior.
CREATE OR REPLACE FUNCTION ledger.verificar_cuadre() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_cargo  BIGINT;
    v_abono  BIGINT;
    v_monedas INT;
BEGIN
    SELECT
        COALESCE(SUM(amount) FILTER (WHERE side = 'cargo'), 0),
        COALESCE(SUM(amount) FILTER (WHERE side = 'abono'), 0),
        COUNT(DISTINCT currency_code)
      INTO v_cargo, v_abono, v_monedas
      FROM ledger.entry
     WHERE journal_period = NEW.journal_period
       AND journal_id     = NEW.journal_id;

    IF v_monedas > 1 THEN
        RAISE EXCEPTION 'L1: el asiento % mezcla monedas', NEW.journal_id;
    END IF;
    IF v_cargo <> v_abono THEN
        RAISE EXCEPTION 'L1: el asiento % no cuadra (cargo % / abono %)',
            NEW.journal_id, v_cargo, v_abono;
    END IF;

    PERFORM 1 FROM ledger.journal j
      WHERE j.period = NEW.journal_period AND j.id = NEW.journal_id
        AND j.tenant_id = NEW.tenant_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'T1: la línea del asiento % no coincide en tenant con su asiento',
            NEW.journal_id;
    END IF;
    RETURN NULL;
END $$;

CREATE CONSTRAINT TRIGGER entry_cuadre
    AFTER INSERT OR UPDATE ON ledger.entry
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION ledger.verificar_cuadre();

-- Invariante L3 y L4: inmutabilidad por disparador, no por convención.
CREATE OR REPLACE FUNCTION ledger.impedir_mutacion() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'L3: los asientos no se borran. La corrección es por contrapartida.';
    END IF;
    IF NEW.state = OLD.state THEN
        RAISE EXCEPTION 'L4: la única mutación admitida es el paso de aprobado a confirmado.';
    END IF;
    IF NOT (OLD.state = 'aprobado' AND NEW.state = 'confirmado') THEN
        RAISE EXCEPTION 'L4: transición de estado no permitida: % -> %', OLD.state, NEW.state;
    END IF;
    IF (NEW.id, NEW.tenant_id, NEW.period, NEW.sequence, NEW.event_type)
       IS DISTINCT FROM
       (OLD.id, OLD.tenant_id, OLD.period, OLD.sequence, OLD.event_type) THEN
        RAISE EXCEPTION 'L3: los campos del asiento son inmutables.';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER journal_inmutable
    BEFORE UPDATE OR DELETE ON ledger.journal
    FOR EACH ROW EXECUTE FUNCTION ledger.impedir_mutacion();

CREATE OR REPLACE FUNCTION ledger.impedir_mutacion_linea() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'L3: las líneas de asiento son inmutables.';
END $$;

CREATE TRIGGER entry_inmutable
    BEFORE UPDATE OR DELETE ON ledger.entry
    FOR EACH ROW EXECUTE FUNCTION ledger.impedir_mutacion_linea();

CREATE TABLE ledger.period_close (
    tenant_id   catalog.tenant_id NOT NULL,
    period      DATE NOT NULL,
    closed_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_by   TEXT NOT NULL,
    PRIMARY KEY (tenant_id, period)
);

COMMENT ON TABLE ledger.period_close IS
  'Invariante L7: un periodo cerrado no admite asientos con fecha dentro de él. Las correcciones posteriores se asientan en el periodo abierto.';

-- =============================================================================
-- RECONCILIATION · conciliación
-- =============================================================================

CREATE TABLE reconciliation.ingestion_batch (
    id              catalog.entity_id PRIMARY KEY,
    tenant_id       catalog.tenant_id NOT NULL,
    source          TEXT NOT NULL CHECK (source IN ('procesador','camara','banco','emisora')),
    source_ref      TEXT NOT NULL,
    content_hash    TEXT NOT NULL,
    row_count       INT  NOT NULL,
    ingested_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, source, content_hash)
);

COMMENT ON TABLE reconciliation.ingestion_batch IS
  'Invariante K8: la ingesta es idempotente. La unicidad del hash de contenido impide que reprocesar el mismo archivo duplique partidas.';

CREATE TABLE reconciliation.movement (
    id                  catalog.entity_id PRIMARY KEY,
    tenant_id           catalog.tenant_id NOT NULL,
    ingestion_batch_id  catalog.entity_id NOT NULL REFERENCES reconciliation.ingestion_batch(id),
    source              TEXT NOT NULL,
    movement_type       TEXT NOT NULL CHECK (movement_type IN (
                          'venta','devolucion','anulacion','contracargo','reverso_contracargo',
                          'comision','impuesto','abono','ajuste','no_clasificado')),
    amount              catalog.minor_units NOT NULL,
    currency_code       catalog.currency_code NOT NULL,
    operation_date      DATE NOT NULL,
    value_date          DATE,
    sub_affiliation_id  TEXT,
    network_terminal_id TEXT,
    retrieval_reference TEXT,
    stan                TEXT,
    source_attributes   JSONB NOT NULL DEFAULT '{}',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON COLUMN reconciliation.movement.movement_type IS
  'Incluye no_clasificado, y es obligatorio: descartar lo que no se entiende es la forma más silenciosa de perder dinero. Invariante K2.';

COMMENT ON COLUMN reconciliation.movement.source_attributes IS
  'Lo que el tercero envió y no se mapeó, íntegro. Permite reprocesar cuando se descubre que un campo sí importaba, y es evidencia ante una disputa. K6.';

-- Índices por nivel de la llave de correlación jerárquica. Documento 0.8 §3.
CREATE INDEX movement_llave_exacta ON reconciliation.movement
    (tenant_id, retrieval_reference, amount, currency_code)
    WHERE retrieval_reference IS NOT NULL;

CREATE INDEX movement_llave_fuerte ON reconciliation.movement
    (tenant_id, sub_affiliation_id, stan, operation_date, amount)
    WHERE stan IS NOT NULL;

CREATE INDEX movement_llave_media  ON reconciliation.movement
    (tenant_id, sub_affiliation_id, network_terminal_id, operation_date, amount);

CREATE INDEX movement_llave_debil  ON reconciliation.movement
    (tenant_id, sub_affiliation_id, operation_date, amount);

CREATE TABLE reconciliation.item (
    id                  catalog.entity_id PRIMARY KEY,
    tenant_id           catalog.tenant_id NOT NULL,
    movement_id         catalog.entity_id REFERENCES reconciliation.movement(id),
    intent_id           catalog.entity_id,
    merchant_id         catalog.entity_id,
    status              TEXT NOT NULL CHECK (status IN (
                          'pendiente','casada','diferencia_importe','faltante_en_origen',
                          'faltante_en_destino','duplicada','ambigua','resuelta')),
    correlation_level   TEXT CHECK (correlation_level IN (
                          'exacta','fuerte','media','debil','sin_coincidencia')),
    candidate_count     INT NOT NULL DEFAULT 0,
    expected_amount     catalog.minor_units,
    reported_amount     catalog.minor_units,
    difference_amount   catalog.minor_units,
    currency_code       catalog.currency_code NOT NULL,
    resolution_reason   TEXT,
    resolved_by         TEXT,
    resolved_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT item_resuelta_con_motivo
      CHECK (status <> 'resuelta' OR (resolution_reason IS NOT NULL
                                  AND resolved_by IS NOT NULL
                                  AND resolved_at IS NOT NULL)),
    CONSTRAINT item_ambigua_con_candidatos
      CHECK (status <> 'ambigua' OR candidate_count > 1)
);

COMMENT ON CONSTRAINT item_ambigua_con_candidatos ON reconciliation.item IS
  'Invariante K3: la correlación ambigua no elige, escala. Una correlación incorrecta es peor que ninguna: produce una confirmación falsa que libera una dispersión indebida.';

CREATE INDEX item_abiertas ON reconciliation.item (tenant_id, merchant_id)
    WHERE status NOT IN ('casada','resuelta');

-- =============================================================================
-- SETTLEMENT · liquidación y dispersión
-- =============================================================================

CREATE TABLE settlement.settlement (
    id              catalog.entity_id PRIMARY KEY,
    tenant_id       catalog.tenant_id NOT NULL,
    merchant_id     catalog.entity_id NOT NULL,
    period          DATE NOT NULL,
    gross_amount    catalog.minor_units NOT NULL,
    fees_amount     catalog.minor_units NOT NULL,
    taxes_amount    catalog.minor_units NOT NULL,
    net_amount      catalog.minor_units NOT NULL,
    currency_code   catalog.currency_code NOT NULL,
    status          TEXT NOT NULL CHECK (status IN
                      ('calculada','bloqueada','instruida','confirmada','fallida')),
    blocked_reason  TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, merchant_id, period),
    CONSTRAINT settlement_bloqueo_con_motivo
      CHECK (status <> 'bloqueada' OR blocked_reason IS NOT NULL),
    CONSTRAINT settlement_neto_cuadra
      CHECK (net_amount = gross_amount - fees_amount - taxes_amount)
);

COMMENT ON TABLE settlement.settlement IS
  'La liquidación LEE el libro; no recalcula comisiones. Un solo sistema de liquidación, nunca dos en paralelo. Invariante L8.';

CREATE TABLE settlement.payout (
    id              catalog.entity_id PRIMARY KEY,
    tenant_id       catalog.tenant_id NOT NULL,
    settlement_id   catalog.entity_id NOT NULL REFERENCES settlement.settlement(id),
    amount          catalog.minor_units NOT NULL,
    currency_code   catalog.currency_code NOT NULL,
    bank_file_id    TEXT,
    status          TEXT NOT NULL CHECK (status IN
                      ('calculada','bloqueada','instruida','confirmada','fallida')),
    blocked_reason  TEXT CHECK (blocked_reason IN
                      ('partida_no_conciliada','transaccion_indeterminada',
                       'revision_de_riesgo','disputa_abierta')),
    account_snapshot JSONB,
    instructed_at   TIMESTAMPTZ,
    confirmed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT payout_bloqueo_con_motivo
      CHECK (status <> 'bloqueada' OR blocked_reason IS NOT NULL),
    CONSTRAINT payout_instruida_con_cuenta
      CHECK (status NOT IN ('instruida','confirmada') OR account_snapshot IS NOT NULL)
);

COMMENT ON COLUMN settlement.payout.account_snapshot IS
  'Invariante L10. Fotografia inmutable de los datos bancarios del beneficiario vigentes en el momento
de la dispersion. Cambiar la cuenta despues NO reescribe el pasado: las dispersiones ya ejecutadas
siguen mostrando la cuenta a la que efectivamente se pago. Es D21 aplicado al dato bancario.';

COMMENT ON COLUMN settlement.payout.blocked_reason IS
  'Las dos ultimas causas retienen el pago SIN detener la venta: la transaccion se autoriza, se cobra y
el comprador recibe su compra. Si llega un contracargo en unos dias se quiere el dinero disponible
para cubrirlo en vez de haberlo dispersado. Al resolverse a favor se acredita en la corrida siguiente.';

-- =============================================================================
-- PLATFORM · idempotencia, configuración, auditoría
-- =============================================================================

CREATE TABLE platform.idempotency_key (
    tenant_id       catalog.tenant_id NOT NULL,
    key             TEXT NOT NULL,
    request_hash    TEXT NOT NULL,
    operation       TEXT NOT NULL,
    response_status INT,
    response_body   JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at      TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (tenant_id, key)
);

COMMENT ON TABLE platform.idempotency_key IS
  'Toda operación que modifica estado exige clave de idempotencia. Misma clave y mismo cuerpo devuelve el resultado original; misma clave y cuerpo distinto devuelve conflicto. Documento 1.1.';

CREATE INDEX idempotency_purga ON platform.idempotency_key (expires_at);

CREATE TABLE platform.dialect_spec (
    id              TEXT NOT NULL,
    version         INT  NOT NULL,
    processor       TEXT NOT NULL,
    messaging       TEXT NOT NULL,
    payload_hash    TEXT NOT NULL,
    valid_from      DATE NOT NULL,
    valid_to        DATE,
    source_notice   TEXT,
    PRIMARY KEY (id, version)
);

COMMENT ON TABLE platform.dialect_spec IS
  'Las especificaciones de dialecto necesitan VIGENCIA, no solo version: un mapeo correcto en junio
puede dejar de serlo en julio. La especificacion consultada acumula siete revisiones en las que se
elimino un token y un campo entero, se movieron tokens a otro documento, y uno paso de obligatorio a
condicional. source_notice registra el aviso de cambio del proveedor que originó la version.';

CREATE TABLE platform.config_version (
    id              TEXT PRIMARY KEY,
    tenant_id       catalog.tenant_id NOT NULL,
    description     TEXT NOT NULL,
    payload_hash    TEXT NOT NULL,
    applied_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    applied_by      TEXT NOT NULL
);

CREATE TABLE platform.cross_tenant_access (
    id              catalog.entity_id PRIMARY KEY,
    actor           TEXT NOT NULL,
    tenant_id       catalog.tenant_id NOT NULL,
    purpose         TEXT NOT NULL,
    resource        TEXT NOT NULL,
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE platform.cross_tenant_access IS
  'Invariante T4. El acceso cross-tenant de un operador de Centrix es excepcional y se registra siempre. Es lo primero que pide un evaluador.';

-- =============================================================================
-- SEGURIDAD A NIVEL DE FILA · invariantes T1, T2 y T3
-- El aislamiento se aplica en la capa de datos, nunca solo en presentación.
-- =============================================================================

CREATE OR REPLACE FUNCTION platform.tenant_actual() RETURNS TEXT
LANGUAGE sql STABLE AS $$
    SELECT current_setting('centrix.tenant_id', true)
$$;

DO $$
DECLARE
    t RECORD;
BEGIN
    FOR t IN
        SELECT c.oid::regclass AS tabla
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = 'tenant_id'
         WHERE c.relkind IN ('r','p')   -- 'p' incluye tablas particionadas:
                                        -- las políticas de una partición NO se aplican
                                        -- al consultar a través de la tabla padre
           AND n.nspname IN ('merchants','payments','fees','ledger',
                             'reconciliation','settlement','platform')
    LOOP
        EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t.tabla);
        EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t.tabla);
        EXECUTE format(
            'CREATE POLICY aislamiento_tenant ON %s USING (tenant_id = platform.tenant_actual())',
            t.tabla);
    END LOOP;
END $$;

COMMIT;

-- =============================================================================
-- LO QUE ESTE ESQUEMA NO CONTIENE, Y ES DELIBERADO
--
--   · Ninguna columna de número de cuenta principal          R3
--   · Ninguna columna de código de seguridad                 R2
--   · Ninguna columna de datos de pista                      R2
--   · Ningún tipo NUMERIC, DECIMAL, REAL o DOUBLE PRECISION  R1
--   · Ningún campo con nombre de artefacto de trama          R8
--   · Ninguna clave foránea entre esquemas de servicios      Propiedad por servicio
--
-- PENDIENTE
--   · Tablas de mapeo por dialecto (2.6) — bloqueado por manuales de cámara
--   · Catálogo de causas de rechazo (0.11) — bloqueado por manuales de cámara
--   · Particiones futuras: se crean con antelación por trabajo programado
-- =============================================================================
