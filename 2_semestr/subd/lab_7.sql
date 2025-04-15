-- Active: 1744030364581@@127.0.0.1@5432@device_repair
-- 1.  Ведение журнала изменений стоимости ремонта

CREATE TABLE IF NOT EXISTS repair_cost_history (
    history_id SERIAL PRIMARY KEY,
    repair_id INT NOT NULL,
    old_cost DECIMAL(10, 2),
    new_cost DECIMAL(10, 2),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    change_user VARCHAR(100) DEFAULT CURRENT_USER,
    change_reason VARCHAR(255)
);

CREATE OR REPLACE FUNCTION log_repair_cost_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.repair_cost IS DISTINCT FROM NEW.repair_cost) THEN
        INSERT INTO repair_cost_history (
            repair_id,
            old_cost,
            new_cost,
            change_reason
        ) VALUES (
            NEW.repair_id,
            OLD.repair_cost,
            NEW.repair_cost,
            'Изменение стоимости ремонта'
        );

        RAISE NOTICE 'Стоимость ремонта ID % изменена с % на %',
            NEW.repair_id, OLD.repair_cost, NEW.repair_cost;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER track_repair_cost_changes
BEFORE UPDATE ON repairs
FOR EACH ROW
EXECUTE FUNCTION log_repair_cost_changes();

-- 2.  Автоматическое обновление разряда мастера при выполнении определенного количества ремонтов

CREATE TABLE IF NOT EXISTS rank_upgrade_conditions (
    rank_id SERIAL PRIMARY KEY,
    from_rank INT NOT NULL,
    to_rank INT NOT NULL,
    min_repairs_required INT NOT NULL,
    min_experience_years DECIMAL(5, 2) NOT NULL,
    UNIQUE (from_rank, to_rank)
);

INSERT INTO rank_upgrade_conditions (from_rank, to_rank, min_repairs_required, min_experience_years)
VALUES
    (1, 2, 3, 0.5),
    (2, 3, 30, 1.0),
    (3, 4, 50, 2.0),
    (4, 5, 100, 3.0)
ON CONFLICT (from_rank, to_rank) DO NOTHING;

CREATE OR REPLACE FUNCTION check_master_rank_upgrade()
RETURNS TRIGGER AS $$
DECLARE
    master_repair_count INT;
    master_experience DECIMAL(5, 2);
    current_rank INT;
    upgrade_condition RECORD;
    should_upgrade BOOLEAN := FALSE;
    master_name VARCHAR;
BEGIN
    -- Получаем данные о мастере
    SELECT
        qualification_rank,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)),
        last_name || ' ' || first_name || ' ' || COALESCE(middle_name, '')
    INTO
        current_rank,
        master_experience,
        master_name
    FROM masters
    WHERE master_id = NEW.master_id;

    -- Выводим отладочную информацию
    RAISE NOTICE 'Триггер активирован для мастера ID: %, ФИО: %, текущий разряд: %, стаж: % лет',
        NEW.master_id, master_name, current_rank, master_experience;

    -- Подсчитываем общее количество ремонтов, включая только что добавленный
    SELECT COUNT(*)
    INTO master_repair_count
    FROM repairs
    WHERE master_id = NEW.master_id;

    RAISE NOTICE 'Общее количество ремонтов у мастера: %', master_repair_count;

    -- Проверяем условия для повышения разряда
    SELECT * INTO upgrade_condition
    FROM rank_upgrade_conditions
    WHERE from_rank = current_rank
    AND min_repairs_required <= master_repair_count
    AND min_experience_years <= master_experience;

    -- Если есть подходящее условие - повышаем разряд
    IF FOUND THEN
        should_upgrade := TRUE;

        -- Обновляем разряд мастера
        UPDATE masters
        SET qualification_rank = upgrade_condition.to_rank
        WHERE master_id = NEW.master_id;

        -- Выводим уведомление о повышении
        RAISE NOTICE 'Мастер % повышен с разряда % до разряда %',
            master_name, current_rank, upgrade_condition.to_rank;
    ELSE
        RAISE NOTICE 'Условия для повышения не выполнены';

        -- Проверяем, есть ли вообще правило для текущего разряда
        SELECT * INTO upgrade_condition
        FROM rank_upgrade_conditions
        WHERE from_rank = current_rank;
    END IF;

    -- Возвращаем NEW, чтобы разрешить операцию INSERT
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_master_rank_on_repair ON repairs;

CREATE OR REPLACE TRIGGER update_master_rank_on_repair
AFTER INSERT ON repairs
FOR EACH ROW
EXECUTE FUNCTION check_master_rank_upgrade();

-- обновления стоимости ремонта для проверки первого триггера:
UPDATE repairs SET repair_cost = 9000.00 WHERE repair_id = 1;

-- добавления нового ремонта для проверки второго триггера:
INSERT INTO masters (master_id, last_name, first_name, middle_name, qualification_rank, hire_date) VALUES
(6, 'Тестов', 'Тест', 'Тестович', 1, '2020-03-15')

INSERT INTO repairs (repair_id, device_in_repair_id, device_id, master_id, owner_full_name, receipt_date, malfunction_type, repair_cost)
VALUES
(15, 'REP-2023-007', 1, 6, 'Тестовый Клиент2', CURRENT_DATE, 'Тестовая поломка2', 5000.00),
(16, 'REP-2023-007', 1, 6, 'Тестовый Клиент2', CURRENT_DATE, 'Тестовая поломка2', 5000.00),
(17, 'REP-2023-007', 1, 6, 'Тестовый Клиент2', CURRENT_DATE, 'Тестовая поломка2', 5000.00);
