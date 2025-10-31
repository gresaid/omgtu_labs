--1
SELECT lower(split_part(form, ' ', 1)) AS form_norm,
COUNT(*) AS products_count
FROM products
GROUP BY form_norm
ORDER BY products_count DESC NULLS LAST;

--2
SELECT id,
full_name,
phone,
regexp_replace(phone, '\D', '', 'g') AS digits_only
FROM patients
WHERE length(regexp_replace(phone, '\D', '', 'g')) >= 10
ORDER BY full_name;
--3
SELECT p.name AS product,
SUM(si.quantity) AS total_sold
FROM sales_items si
JOIN products p ON p.id = si.product_id
GROUP BY p.name
HAVING SUM(si.quantity) > 2;
--4
SELECT p.id AS product_id,
p.name AS product_name,
AVG((b.expiry_date - CURRENT_DATE))::int AS avg_days_to_expiry
FROM products p
JOIN batches b ON b.product_id = p.id
WHERE b.expiry_date >= CURRENT_DATE
GROUP BY p.id, p.name
ORDER BY avg_days_to_expiry;
--5
SELECT date_part('hour', si.sale_date) AS hour_of_day,
COUNT(DISTINCT si.id) AS invoices_count,
SUM(it.quantity * it.unit_price) AS line_amount
FROM sales_invoices si
LEFT JOIN sales_items it ON it.sales_invoice_id = si.id
GROUP BY hour_of_day
ORDER BY hour_of_day;
--6
SELECT br.name AS branch,
p.name AS product,
SUM(b.quantity) AS total_qty_expired
FROM batches b
JOIN branches br ON br.id = b.branch_id
JOIN products p ON p.id = b.product_id
WHERE b.expiry_date < CURRENT_DATE
GROUP BY br.name, p.name
HAVING SUM(b.quantity) > 0
ORDER BY branch, product;

--7
WITH sold AS (SELECT si.branch_id,
it.product_id,
SUM(it.quantity) AS qty
FROM sales_items it
JOIN sales_invoices si ON si.id = it.sales_invoice_id
GROUP BY si.branch_id, it.product_id),
ranked AS (SELECT s.*,
DENSE_RANK() OVER (PARTITION BY s.branch_id ORDER BY s.qty DESC) AS rnk
FROM sold s)
SELECT br.name AS branch,
p.name AS product,
qty,
rnk
FROM ranked r
JOIN branches br ON br.id = r.branch_id
JOIN products p ON p.id = r.product_id
WHERE r.rnk <= 3
ORDER BY branch, rnk, product;
--8
WITH daily AS (SELECT DATE(si.sale_date) AS d,
SUM(it.quantity * it.unit_price) AS amount
FROM sales_invoices si
JOIN sales_items it ON it.sales_invoice_id = si.id
GROUP BY DATE(si.sale_date))
SELECT d,
amount,
SUM(amount) OVER (
ORDER BY d
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
) AS rolling_7d_amount
FROM daily
ORDER BY d;
--9
WITH branch_product AS (SELECT si.branch_id,
it.product_id,
SUM(it.quantity * it.unit_price) AS revenue
FROM sales_invoices si
JOIN sales_items it ON it.sales_invoice_id = si.id
GROUP BY si.branch_id, it.product_id)
SELECT br.name AS branch,
p.name AS product,
revenue,
100.0 * revenue / SUM(revenue) OVER (PARTITION BY branch_id) AS revenue_share_pct
FROM branch_product bp
JOIN branches br ON br.id = bp.branch_id
JOIN products p ON p.id = bp.product_id
ORDER BY branch, revenue DESC;
--10
WITH RECURSIVE
bounds AS (SELECT MIN(DATE(sale_date)) AS dmin,
MAX(DATE(sale_date)) AS dmax
FROM sales_invoices),
calendar(d) AS (SELECT dmin
FROM bounds
UNION ALL
SELECT c.d + 1
FROM calendar c,
bounds
WHERE c.d < bounds.dmax),
daily AS (SELECT DATE(si.sale_date) AS d,
SUM(it.quantity * it.unit_price) AS amount
FROM sales_invoices si
JOIN sales_items it ON it.sales_invoice_id = si.id
GROUP BY DATE(si.sale_date))
SELECT c.d, COALESCE(d.amount, 0) AS amount
FROM calendar c
LEFT JOIN daily d ON d.d = c.d
ORDER BY c.d;
--11
WITH RECURSIVE
horizon AS (SELECT b.id AS batch_id, b.expiry_date, 0 AS offset_days
FROM batches b
UNION ALL
SELECT batch_id, expiry_date, offset_days + 1
FROM horizon
WHERE offset_days < 7),
grid AS (SELECT h.batch_id,
(CURRENT_DATE + (h.offset_days || ' days')::interval)::date AS day_point,
(h.expiry_date - (CURRENT_DATE + (h.offset_days || ' days')::interval)::date)::int AS days_to_expiry
FROM horizon h)
SELECT b.id AS batch_id,
p.name AS product,
b.lot_number,
g.day_point,
CASE WHEN g.day_point <= b.expiry_date THEN GREATEST(g.days_to_expiry, 0) END AS days_to_expiry
FROM grid g
JOIN batches b ON b.id = g.batch_id
JOIN products p ON p.id = b.product_id
WHERE g.day_point <= b.expiry_date
ORDER BY batch_id, day_point;
--12
WITH RECURSIVE dates AS (
SELECT b.id AS batch_id,
b.product_id,
b.expiry_date,
CURRENT_DATE::date AS d
FROM batches b
UNION ALL
SELECT dates.batch_id,
dates.product_id,
dates.expiry_date,
(dates.d + INTERVAL '1 day')::date
FROM dates
WHERE (dates.d + INTERVAL '1 day')::date <= dates.expiry_date)
SELECT p.name AS product,
COUNT(*) AS days_available,
MIN(d) AS start_date,
MAX(d) AS end_date
FROM dates
JOIN products p ON p.id = dates.product_id
GROUP BY p.name
ORDER BY days_available DESC;
--13
SELECT COALESCE(NULLIF(trim(form), ''), '— неизвестно —') AS form_group,
PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY unit_price) AS p90_unit_price,
PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY unit_price) AS median_unit_price
FROM sales_items it
LEFT JOIN products p ON p.id = it.product_id
GROUP BY form_group
ORDER BY form_group;
--14
WITH
-- выручка по чеку (если invoices.total_amount ненадёжно)
invoice_revenue AS (
SELECT
si.id AS sales_invoice_id,
SUM(it.quantity * it.unit_price) AS amount
FROM sales_items it
JOIN sales_invoices si ON si.id = it.sales_invoice_id
GROUP BY si.id
),
-- все покупки пациентов
purchases AS (
SELECT
inv.patient_id,
DATE(inv.sale_date) AS d,
date_trunc('month', inv.sale_date)::date AS d_month,
ir.amount
FROM sales_invoices inv
JOIN invoice_revenue ir ON ir.sales_invoice_id = inv.id
WHERE inv.patient_id IS NOT NULL
),
-- первый месяц покупки (когорта)
first_purchase AS (
SELECT
patient_id,
MIN(d_month) AS cohort_month
FROM purchases
GROUP BY patient_id
),
-- факты с отступом по месяцам от первой покупки
facts AS (
SELECT
p.patient_id,
fp.cohort_month,
p.d_month,
p.amount,
(EXTRACT(YEAR FROM p.d_month) - EXTRACT(YEAR FROM fp.cohort_month)) * 12
(EXTRACT(MONTH FROM p.d_month) - EXTRACT(MONTH FROM fp.cohort_month)) AS months_since_first
FROM purchases p
JOIN first_purchase fp ON fp.patient_id = p.patient_id
),
-- размер когорты (число уникальных пациентов в нулевом месяце)
cohort_sizes AS (
SELECT
cohort_month,
COUNT(DISTINCT patient_id) AS cohort_size
FROM facts
WHERE months_since_first = 0
GROUP BY cohort_month
)
SELECT
TO_CHAR(f.cohort_month, 'YYYY-MM') AS cohort_month,
f.months_since_first::int AS month_offset,
COUNT(DISTINCT f.patient_id) AS active_customers,
SUM(f.amount) AS revenue,
cs.cohort_size,
ROUND(100.0 * COUNT(DISTINCT f.patient_id) / NULLIF(cs.cohort_size, 0), 1) AS retention_pct
FROM facts f
JOIN cohort_sizes cs USING (cohort_month)
GROUP BY f.cohort_month, f.months_since_first, cs.cohort_size
ORDER BY f.cohort_month, f.months_since_first;

--15
WITH
-- 1) Параметры и список месяцев (последние 3 календарных месяца, включая текущий)
params AS (
SELECT
date_trunc('month', CURRENT_DATE)::date AS this_month,
(date_trunc('month', CURRENT_DATE) - INTERVAL '2 months')::date AS start_month
),
months AS (
SELECT g::date AS month_start
FROM params p
CROSS JOIN generate_series(p.start_month, p.this_month, INTERVAL '1 month') AS g
),
-- 2) Линии чеков в нужном диапазоне месяцев
invoice_lines AS (
SELECT
si.id AS sales_invoice_id,
si.branch_id,
si.patient_id,
date_trunc('month', si.sale_date)::date AS month_start,
it.product_id,
(it.quantity * it.unit_price) AS line_amount,
it.quantity,
p.is_prescription
FROM sales_items it
JOIN sales_invoices si ON si.id = it.sales_invoice_id
JOIN products p ON p.id = it.product_id
WHERE date_trunc('month', si.sale_date)::date BETWEEN
(SELECT start_month FROM params) AND (SELECT this_month FROM params)
),
-- 3) Сумма по чеку (для среднего чека)
check_amounts AS (
SELECT
il.sales_invoice_id,
il.branch_id,
il.month_start,
SUM(il.line_amount) AS invoice_amount
FROM invoice_lines il
GROUP BY il.sales_invoice_id, il.branch_id, il.month_start
),
-- 4) Агрегации по филиалу × месяцу
branch_month AS (
SELECT
il.branch_id,
il.month_start,
SUM(il.line_amount) AS revenue,
COUNT(DISTINCT il.sales_invoice_id) AS invoices_count,
AVG(ca.invoice_amount) AS avg_ticket,
COUNT(DISTINCT il.patient_id) AS unique_patients,
100.0 * SUM(CASE WHEN il.is_prescription THEN il.line_amount ELSE 0 END)
/ NULLIF(SUM(il.line_amount), 0) AS rx_share_pct
FROM invoice_lines il
JOIN check_amounts ca
ON ca.sales_invoice_id = il.sales_invoice_id
AND ca.branch_id = il.branch_id
AND ca.month_start = il.month_start
GROUP BY il.branch_id, il.month_start
),
-- 5) Топ-1 продукт по выручке в филиале в месяц (через окно)
branch_month_top1 AS (
SELECT branch_id, month_start, product_id, product_revenue
FROM (
SELECT
il.branch_id,
il.month_start,
il.product_id,
SUM(il.line_amount) AS product_revenue,
DENSE_RANK() OVER (
PARTITION BY il.branch_id, il.month_start
ORDER BY SUM(il.line_amount) DESC, il.product_id
) AS rnk
FROM invoice_lines il
GROUP BY il.branch_id, il.month_start, il.product_id
) r
WHERE r.rnk = 1
),
-- 6) Сетка "все филиалы × все месяцы", чтобы показать и нули
grid AS (
SELECT b.id AS branch_id, b.name AS branch_name, m.month_start
FROM branches b
CROSS JOIN months m
)
-- 7) Финал
SELECT
g.branch_name AS branch,
TO_CHAR(g.month_start, 'YYYY-MM') AS month,
COALESCE(bm.revenue, 0)::numeric(12,2) AS revenue,
COALESCE(bm.invoices_count, 0) AS invoices_count,
COALESCE(bm.avg_ticket, 0)::numeric(10,2) AS avg_ticket,
COALESCE(bm.unique_patients, 0) AS unique_patients,
COALESCE(bm.rx_share_pct, 0)::numeric(5,2) AS rx_share_pct,
p.name AS top_product,
COALESCE(t1.product_revenue, 0)::numeric(12,2) AS top_product_revenue
FROM grid g
LEFT JOIN branch_month bm
ON bm.branch_id = g.branch_id
AND bm.month_start = g.month_start
LEFT JOIN branch_month_top1 t1
ON t1.branch_id = g.branch_id
AND t1.month_start = g.month_start
LEFT JOIN products p
ON p.id = t1.product_id
ORDER BY g.branch_name, g.month_start;
