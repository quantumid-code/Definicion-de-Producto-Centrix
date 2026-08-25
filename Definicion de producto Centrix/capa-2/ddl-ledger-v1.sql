-- =============================================================================
-- Centrix · 2.3 Esquema físico del libro contable
-- Capa 2 · Datos · Versión 0.1 borrador · 16 de agosto de 2026
-- PostgreSQL 17
--
-- Se aplica DESPUÉS de centrix-ddl-v1.sql, que crea la estructura base
-- (ledger.account, ledger.journal, ledger.entry, ledger.period_close y los
-- disparadores de cuadre e inmutabilidad).
--
-- Este archivo añade lo que el documento 0.7 promete y la estructura no cubría:
--   · Plan de cuentas sembrado
--   · Catálogo de asientos por evento de negocio
--   · Invariante L7 · periodo cerrado, por disparador y no por convención
--   · Invariante L2 · cuadre por periodo y dimensión, verificable
--   · Invariante L5 · detección de huecos en la numeración
--   · Invariante L6 · saldo dispersable solo sobre asientos confirmados
--   · La medida de incertidumbre del sistema
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1 · Plan de cuentas
-- Las cuentas de control son las que hacen visible el problema: una partida
-- indeterminada no desaparece del libro, se queda ahí hasta que se resuelve.
-- -----------------------------------------------------------------------------

INSERT INTO ledger.account (code, name, kind, normal_side) VALUES
  -- Activo
  ('1100', 'Fondos en tránsito',                  'activo',  'cargo'),
  ('1200', 'Cuentas por cobrar a procesador',     'activo',  'cargo'),
  ('1300', 'Fondos en cuenta concentradora',      'activo',  'cargo'),
  ('1400', 'Por cobrar por contracargo',          'activo',  'cargo'),
  -- Pasivo
  ('2100', 'Cuentas por pagar a comercio',        'pasivo',  'abono'),
  ('2200', 'Reservas retenidas',                  'pasivo',  'abono'),
  ('2300', 'Impuestos por enterar',               'pasivo',  'abono'),
  ('2400', 'Por pagar a eslabón superior',        'pasivo',  'abono'),
  -- Ingreso
  ('4100', 'Comisión ganada',                     'ingreso', 'abono'),
  -- Gasto
  ('5100', 'Comisión pagada a eslabón superior',  'gasto',   'cargo'),
  ('5200', 'Pérdida por contracargo',             'gasto',   'cargo'),
  ('5300', 'Diferencias no recuperables',         'gasto',   'cargo'),
  -- Control
  ('9100', 'Partidas indeterminadas',             'control', 'cargo'),
  ('9200', 'Partidas en conciliación',            'control', 'cargo'),
  ('9300', 'Diferencias no resueltas',            'control', 'cargo'),
  ('9400', 'Movimientos no clasificados',         'control', 'cargo')
ON CONFLICT (code) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 2 · Catálogo de asientos por evento de negocio
-- Declarativo, no cableado en el código. Un evento nuevo es una fila, no un
-- despliegue. Autorización y captura generan asientos DISTINTOS: es la razón
-- contable por la que no se pueden colapsar en una sola operación.
-- -----------------------------------------------------------------------------

CREATE TABLE ledger.event_template (
    event_type      TEXT     NOT NULL,
    line            SMALLINT NOT NULL,
    account_code    TEXT     NOT NULL REFERENCES ledger.account(code),
    side            TEXT     NOT NULL CHECK (side IN ('cargo','abono')),
    amount_source   TEXT     NOT NULL,
    initial_state   TEXT     NOT NULL DEFAULT 'aprobado'
                    CHECK (initial_state IN ('aprobado','confirmado')),
    valid_from      DATE     NOT NULL DEFAULT DATE '2026-01-01',
    valid_to        DATE,
    PRIMARY KEY (event_type, line, valid_from)
);

COMMENT ON COLUMN ledger.event_template.amount_source IS
  'Qué importe del evento alimenta la línea: bruto, comisión, impuesto, neto o diferencia.
El motor no interpreta nombres de cuenta: aplica la plantilla vigente.';

INSERT INTO ledger.event_template (event_type, line, account_code, side, amount_source) VALUES
  ('autorizacion_aprobada',   1, '1100', 'cargo', 'bruto'),
  ('autorizacion_aprobada',   2, '2100', 'abono', 'bruto'),

  ('autorizacion_expirada',   1, '2100', 'cargo', 'bruto'),
  ('autorizacion_expirada',   2, '1100', 'abono', 'bruto'),

  ('captura',                 1, '1200', 'cargo', 'bruto'),
  ('captura',                 2, '1100', 'abono', 'bruto'),

  ('anulacion',               1, '2100', 'cargo', 'bruto'),
  ('anulacion',               2, '1200', 'abono', 'bruto'),

  ('comision_evaluada',       1, '2100', 'cargo', 'comision'),
  ('comision_evaluada',       2, '4100', 'abono', 'comision'),

  ('impuesto_comision',       1, '2100', 'cargo', 'impuesto'),
  ('impuesto_comision',       2, '2300', 'abono', 'impuesto'),

  ('comision_eslabon_superior', 1, '5100', 'cargo', 'comision'),
  ('comision_eslabon_superior', 2, '2400', 'abono', 'comision'),

  ('liquidacion_calculada',   1, '1300', 'cargo', 'neto'),
  ('liquidacion_calculada',   2, '1200', 'abono', 'neto'),

  ('dispersion_instruida',    1, '2100', 'cargo', 'neto'),
  ('dispersion_instruida',    2, '1300', 'abono', 'neto'),

  ('devolucion',              1, '2100', 'cargo', 'bruto'),
  ('devolucion',              2, '1200', 'abono', 'bruto'),

  ('contracargo_notificado',  1, '9200', 'cargo', 'bruto'),
  ('contracargo_notificado',  2, '2100', 'abono', 'bruto'),

  ('contracargo_perdido',     1, '5200', 'cargo', 'bruto'),
  ('contracargo_perdido',     2, '9200', 'abono', 'bruto'),

  ('contracargo_ganado',      1, '2100', 'cargo', 'bruto'),
  ('contracargo_ganado',      2, '9200', 'abono', 'bruto'),

  -- La transacción indeterminada NO desaparece del libro: vive en su cuenta de
  -- control hasta que se resuelve. Invariante I4.
  ('transaccion_indeterminada', 1, '9100', 'cargo', 'bruto'),
  ('transaccion_indeterminada', 2, '2100', 'abono', 'bruto'),

  ('indeterminada_resuelta_a_favor', 1, '2100', 'cargo', 'bruto'),
  ('indeterminada_resuelta_a_favor', 2, '9100', 'abono', 'bruto'),

  ('movimiento_no_clasificado', 1, '9400', 'cargo', 'bruto'),
  ('movimiento_no_clasificado', 2, '9300', 'abono', 'bruto'),

  ('diferencia_conciliacion', 1, '9300', 'cargo', 'diferencia'),
  ('diferencia_conciliacion', 2, '9200', 'abono', 'diferencia')
ON CONFLICT DO NOTHING;

-- -----------------------------------------------------------------------------
-- 3 · Invariante L7 · un periodo cerrado no admite asientos con fecha dentro
-- Las correcciones posteriores se asientan en el periodo abierto con referencia
-- al cerrado. No es formalismo: evita que un ajuste tardío cambie un número que
-- ya se reportó.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ledger.impedir_periodo_cerrado() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM 1 FROM ledger.period_close
     WHERE tenant_id = NEW.tenant_id AND period = NEW.period;
    IF FOUND THEN
        RAISE EXCEPTION
          'L7: el periodo % del tenant % está cerrado. La corrección se asienta en el periodo abierto con referencia al cerrado.',
          NEW.period, NEW.tenant_id;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER journal_periodo_cerrado
    BEFORE INSERT ON ledger.journal
    FOR EACH ROW EXECUTE FUNCTION ledger.impedir_periodo_cerrado();

-- -----------------------------------------------------------------------------
-- 4 · Invariante L2 · el libro cuadra por periodo y dimensión
-- Un descuadre es incidente, no hallazgo.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ledger.cuadre_de_periodo(
    p_tenant catalog.tenant_id,
    p_period DATE
) RETURNS TABLE (currency_code catalog.currency_code,
                 cargos catalog.minor_units,
                 abonos catalog.minor_units,
                 descuadre catalog.minor_units)
LANGUAGE sql STABLE AS $$
    SELECT e.currency_code,
           COALESCE(SUM(e.amount) FILTER (WHERE e.side = 'cargo'), 0),
           COALESCE(SUM(e.amount) FILTER (WHERE e.side = 'abono'), 0),
           COALESCE(SUM(e.amount) FILTER (WHERE e.side = 'cargo'), 0)
         - COALESCE(SUM(e.amount) FILTER (WHERE e.side = 'abono'), 0)
      FROM ledger.entry e
     WHERE e.tenant_id = p_tenant AND e.journal_period = p_period
     GROUP BY e.currency_code
$$;

-- -----------------------------------------------------------------------------
-- 5 · Invariante L5 · numeración secuencial sin huecos
-- Un hueco es señal de manipulación o de fallo, y en ambos casos debe detectarse.
-- La unicidad la garantiza la restricción; la ausencia de huecos, no.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ledger.huecos_de_numeracion(
    p_tenant catalog.tenant_id,
    p_period DATE
) RETURNS TABLE (desde BIGINT, hasta BIGINT)
LANGUAGE sql STABLE AS $$
    WITH s AS (
        SELECT sequence,
               LEAD(sequence) OVER (ORDER BY sequence) AS siguiente
          FROM ledger.journal
         WHERE tenant_id = p_tenant AND period = p_period
    )
    SELECT sequence + 1, siguiente - 1
      FROM s
     WHERE siguiente IS NOT NULL AND siguiente > sequence + 1
$$;

-- -----------------------------------------------------------------------------
-- 6 · Invariante L6 · el saldo dispersable se calcula solo sobre confirmados
-- Lo aprobado y no confirmado es expectativa, no dinero.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE VIEW ledger.v_saldo AS
SELECT j.tenant_id,
       j.period,
       j.merchant_id,
       e.account_code,
       a.kind      AS account_kind,
       j.state,
       e.currency_code,
       SUM(CASE WHEN e.side = a.normal_side THEN e.amount ELSE -e.amount END) AS saldo
  FROM ledger.entry   e
  JOIN ledger.journal j ON j.period = e.journal_period AND j.id = e.journal_id
  JOIN ledger.account a ON a.code = e.account_code
 GROUP BY j.tenant_id, j.period, j.merchant_id, e.account_code, a.kind, j.state, e.currency_code;

COMMENT ON VIEW ledger.v_saldo IS
  'Saldo por cuenta, comercio, periodo y ESTADO. La separación por estado es lo que hace posible
distinguir lo que Centrix cree de lo que el tercero confirmó.';

CREATE OR REPLACE VIEW ledger.v_dispersable AS
SELECT tenant_id, merchant_id, currency_code,
       SUM(saldo) AS saldo_dispersable
  FROM ledger.v_saldo
 WHERE account_code = '2100'      -- por pagar a comercio
   AND state        = 'confirmado'
 GROUP BY tenant_id, merchant_id, currency_code;

COMMENT ON VIEW ledger.v_dispersable IS
  'Invariante L6. Solo asientos confirmados. Un importe es dispersable si además no existe partida
de conciliación abierta asociada, que se comprueba contra reconciliation.item.';

-- -----------------------------------------------------------------------------
-- 7 · La medida de incertidumbre del sistema
-- El saldo de las cuentas de control es la medida directa de cuánta
-- incertidumbre tiene el sistema en un momento dado. Si crece, algo no se está
-- resolviendo.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE VIEW ledger.v_incertidumbre AS
SELECT s.tenant_id,
       s.account_code,
       a.name AS cuenta,
       s.currency_code,
       SUM(s.saldo) AS saldo_abierto
  FROM ledger.v_saldo s
  JOIN ledger.account a ON a.code = s.account_code
 WHERE a.kind = 'control'
 GROUP BY s.tenant_id, s.account_code, a.name, s.currency_code
HAVING SUM(s.saldo) <> 0;

COMMENT ON VIEW ledger.v_incertidumbre IS
  'Saldo abierto de las cuentas de control: indeterminadas, en conciliación, diferencias no
resueltas y movimientos no clasificados. Es el indicador que se vigila a diario, y el que un
evaluador pide para entender el estado real de la operación.';

COMMIT;

-- =============================================================================
-- LO QUE ESTE ARCHIVO NO RESUELVE
--
--   · Ciclos de compensación y corte de cada cámara, que definen la frontera
--     del periodo contable · P13
--   · Formato de exportación exigido por el auditor del cliente · P32
--   · Tratamiento contable de la reserva · P37, diferido por fase
--   · Conversión a moneda de reporte · P38, diferido por fase
--
-- Las plantillas de contracargo se incluyen porque el libro ya las contempla
-- (documento 0.7), aunque el registro del ciclo completo sea F0-Producto.
-- =============================================================================
