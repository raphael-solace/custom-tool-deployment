BEGIN;

INSERT INTO public.products (
  sku,
  product_name,
  short_description,
  long_description,
  brand_id,
  manufacturer_id,
  product_line,
  status_id,
  primary_category_id,
  department_id,
  base_uom_id,
  is_variant,
  created_at,
  updated_at
)
VALUES
  (
    'MAT-200120',
    'Pressure Sensor Industrial 0-16 bar',
    'Industrial pressure sensor for fluid systems',
    'Pressure Sensor Industrial 0-16 bar with 4-20mA output and M12 connector.',
    14,
    14,
    'Instrumentation',
    1,
    16,
    4,
    1,
    false,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
  ),
  (
    'MAT-300080',
    'Valve Controller Electro-Pneumatic',
    'Electro-pneumatic valve controller',
    'Valve Controller Electro-Pneumatic suitable for on/off and proportional valve automation.',
    8,
    8,
    'Valves',
    1,
    15,
    2,
    1,
    false,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
  ),
  (
    'MAT-400060',
    'Hydraulic Pump Kit HPK-60',
    'Hydraulic pump kit for medium-pressure applications',
    'Hydraulic Pump Kit HPK-60 including pump head, coupling and seals for standard industrial duty.',
    2,
    2,
    'Pumping',
    1,
    2,
    2,
    1,
    false,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
  ),
  (
    'MAT-500200',
    'Flow Meter FM-200 Inline',
    'Inline flow meter for process monitoring',
    'Flow Meter FM-200 Inline for process monitoring with digital readout and Modbus support.',
    10,
    10,
    'Instrumentation',
    1,
    11,
    4,
    1,
    false,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
  ),
  (
    'MAT-700200',
    'Gasket Set GS-200 Chemical Resistant',
    'Chemical-resistant gasket set',
    'Gasket Set GS-200 for pumps and valves with chemical-resistant material composition.',
    11,
    11,
    'Maintenance',
    1,
    10,
    2,
    1,
    false,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
  )
ON CONFLICT (sku) DO UPDATE SET
  product_name = EXCLUDED.product_name,
  short_description = EXCLUDED.short_description,
  long_description = EXCLUDED.long_description,
  brand_id = EXCLUDED.brand_id,
  manufacturer_id = EXCLUDED.manufacturer_id,
  product_line = EXCLUDED.product_line,
  status_id = EXCLUDED.status_id,
  primary_category_id = EXCLUDED.primary_category_id,
  department_id = EXCLUDED.department_id,
  base_uom_id = EXCLUDED.base_uom_id,
  is_variant = EXCLUDED.is_variant,
  updated_at = CURRENT_TIMESTAMP;

WITH sku_pricing AS (
  SELECT * FROM (
    VALUES
      ('MAT-200120', 5, 'MAT-200120', 210.00, 'EUR', 14),
      ('MAT-300080', 6, 'MAT-300080', 340.00, 'EUR', 21),
      ('MAT-400060', 3, 'MAT-400060', 1250.00, 'EUR', 28),
      ('MAT-500200', 4, 'MAT-500200', 460.00, 'EUR', 21),
      ('MAT-700200', 7, 'MAT-700200', 18.00, 'EUR', 7)
  ) AS t(sku, supplier_id, supplier_sku, supplier_cost, supplier_currency, purchase_lead_time_days)
)
INSERT INTO public.product_suppliers (
  product_id,
  supplier_id,
  is_primary,
  supplier_sku,
  purchase_order_minimum,
  purchase_lead_time_days,
  supplier_cost,
  supplier_currency,
  is_preferred,
  notes,
  is_active,
  created_at,
  updated_at
)
SELECT
  p.product_id,
  s.supplier_id,
  true,
  s.supplier_sku,
  1,
  s.purchase_lead_time_days,
  s.supplier_cost,
  s.supplier_currency,
  true,
  'Seeded for RFQ golden scenarios',
  true,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
FROM sku_pricing s
JOIN public.products p ON p.sku = s.sku
ON CONFLICT (product_id, supplier_id) DO UPDATE SET
  is_primary = EXCLUDED.is_primary,
  supplier_sku = EXCLUDED.supplier_sku,
  purchase_order_minimum = EXCLUDED.purchase_order_minimum,
  purchase_lead_time_days = EXCLUDED.purchase_lead_time_days,
  supplier_cost = EXCLUDED.supplier_cost,
  supplier_currency = EXCLUDED.supplier_currency,
  is_preferred = EXCLUDED.is_preferred,
  notes = EXCLUDED.notes,
  is_active = EXCLUDED.is_active,
  updated_at = CURRENT_TIMESTAMP;

COMMIT;
