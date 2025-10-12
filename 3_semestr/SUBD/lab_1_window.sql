-- 1 Агрегатная оконная функция
-- накопительную сумму продаж по датам
SELECT
    sale_date,
    amount,
    SUM(amount) OVER (ORDER BY sale_date) AS running_total
FROM sales
ORDER BY sale_date;


-- 2 Ранжирующая оконная функция
-- рейтинг сотрудников по сумме продаж в отделе
SELECT
    e.department,
    e.full_name,
    SUM(s.amount) AS total_sales,
    RANK() OVER (PARTITION BY e.department ORDER BY SUM(s.amount) DESC) AS rank_in_dept
FROM sales s
JOIN employees e ON s.employee_id = e.employee_id
GROUP BY e.department, e.full_name
ORDER BY e.department, rank_in_dept;


-- 3 Функция смещения
-- насколько текущая продажа сотрудника отличается от предыдущей

SELECT
    employee_id,
    sale_date,
    amount,
    amount - LAG(amount) OVER (PARTITION BY employee_id ORDER BY sale_date) AS diff_prev_sale
FROM sales
ORDER BY employee_id, sale_date;
