CREATE OR REPLACE PROCEDURE calculate_salon_revenue(
    start_date DATE,
    end_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    total_revenue DECIMAL(12,2) := 0;
    master_rec RECORD;
    service_rec RECORD;
BEGIN
    IF start_date > end_date THEN
        RAISE EXCEPTION 'Начальная дата не может быть позже конечной даты';
    END IF;

    SELECT COALESCE(SUM(s.price), 0)
    INTO total_revenue
    FROM appointments a
    JOIN services s ON a.service_id = s.service_id
    WHERE a.appointment_date BETWEEN start_date AND end_date
    AND a.status = 'completed';

    RAISE NOTICE 'Период анализа: с % по %', start_date, end_date;
    RAISE NOTICE 'Общая выручка за период: % руб.', total_revenue;

    RAISE NOTICE '--------------------------------------------------------';
    RAISE NOTICE 'ВЫРУЧКА ПО МАСТЕРАМ:';
    RAISE NOTICE '--------------------------------------------------------';

    FOR master_rec IN
        SELECT
            e.employee_id,
            CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
            COUNT(a.appointment_id) AS appointment_count,
            SUM(s.price) AS revenue,
            ROUND(AVG(COALESCE(f.rating, 0)), 1) AS avg_rating
        FROM employees e
        LEFT JOIN appointments a ON e.employee_id = a.employee_id
        LEFT JOIN services s ON a.service_id = s.service_id
        LEFT JOIN feedback f ON a.appointment_id = f.appointment_id
        WHERE (a.appointment_date BETWEEN start_date AND end_date OR a.appointment_date IS NULL)
        AND (a.status = 'completed' OR a.status IS NULL)
        GROUP BY e.employee_id, e.first_name, e.last_name
        ORDER BY SUM(COALESCE(s.price, 0)) DESC NULLS LAST
    LOOP
        RAISE NOTICE 'Мастер: %, Кол-во услуг: %, Выручка: % руб., Ср. рейтинг: %',
            master_rec.employee_name,
            master_rec.appointment_count,
            COALESCE(master_rec.revenue, 0),
            master_rec.avg_rating;
    END LOOP;

    RAISE NOTICE '--------------------------------------------------------';
    RAISE NOTICE 'ПОПУЛЯРНОСТЬ УСЛУГ:';
    RAISE NOTICE '--------------------------------------------------------';

    FOR service_rec IN
        SELECT
            s.name AS service_name,
            COUNT(a.appointment_id) AS appointment_count,
            SUM(s.price) AS revenue,
            ROUND(AVG(COALESCE(f.rating, 0)), 1) AS avg_rating
        FROM services s
        LEFT JOIN appointments a ON s.service_id = a.service_id
        LEFT JOIN feedback f ON a.appointment_id = f.appointment_id
        WHERE (a.appointment_date BETWEEN start_date AND end_date OR a.appointment_date IS NULL)
        AND (a.status = 'completed' OR a.status IS NULL)
        GROUP BY s.service_id, s.name
        ORDER BY COUNT(a.appointment_id) DESC NULLS LAST
    LOOP
        RAISE NOTICE 'Услуга: %, Кол-во: %, Выручка: % руб., Ср. рейтинг: %',
            service_rec.service_name,
            service_rec.appointment_count,
            COALESCE(service_rec.revenue, 0),
            service_rec.avg_rating;
    END LOOP;

    RAISE NOTICE '--------------------------------------------------------';
    RAISE NOTICE 'Анализ завершен.';
END;
$$;
CALL calculate_salon_revenue('2025-01-01', '2025-05-01');



-- Функция триггера для обновления даты последнего изменения
CREATE OR REPLACE FUNCTION update_last_modified()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_modified = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE appointments
ADD COLUMN IF NOT EXISTS last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE TRIGGER update_appointment_timestamp
BEFORE UPDATE ON appointments
FOR EACH ROW
EXECUTE FUNCTION update_last_modified();


-- Обновление статуса записи
UPDATE appointments
SET status = 'completed'
WHERE appointment_id = 1;

-- Проверка результата (last_modified должен обновиться автоматически)
SELECT appointment_id, status, last_modified
FROM appointments
WHERE appointment_id = 1;
