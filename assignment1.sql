CREATE TABLE credit (
    id INTEGER CONSTRAINT prim_key PRIMARY KEY,
    created_date TIMESTAMP CONSTRAINT no_null NOT NULL,
    decision VARCHAR(8),
    decision_date TIMESTAMP,
    issued_sum FLOAT,
    issued_date TIMESTAMP
);

-- Кол-во заявок - все ряды
-- Уровень одобрения - одобренные делить на все с решением
-- Очередь заявок без решения - счет рядов где decision IS NULL
-- Уровень выдач - одобренные и выплаченные делить на все одобренные
-- Средняя выданная суммы - среднее значение issued_sum за день

WITH raw_data AS (
    SELECT
    DATE(created_date) as day_agg,
    COUNT(*) as total_applications,
    SUM(CASE WHEN decision = 'approved' THEN 1 ELSE 0 END) as approved,
    SUM(CASE WHEN (decision = 'approved' AND decision_date IS NOT NULL) THEN 1 ELSE 0 END) as approved_and_issued,
    SUM(CASE WHEN decision = 'reject' THEN 1 ELSE 0 END) as rejected,
    SUM(CASE WHEN decision IS NOT NULL THEN 1 ELSE 0 END) as with_decision,
    SUM(CASE WHEN decision IS NULL THEN 1 ELSE 0 END) as pending_decision,
    AVG(issued_sum) as average_issued_sum

    FROM credit

    WHERE
    EXTRACT(HOUR FROM created_date) <= 10 -- Это число мы можем заменить на любое, чтобы получить только информацию до назначенного часа 
    -- Иначе мы будем сравнивать показатели текущего неполного дня с показателями полных прошлых дней

    GROUP BY DATE(created_date)
);

SELECT 
'Today',
total_applications,
approved / with_decision as approval_rate,
pending_decision,
approved_and_issued / approved as issued_rate,
average_issued_sum
FROM raw_data
WHERE day_agg = CURRENT_DATE() -- Можно заменить на любой другой день

UNION ALL

SELECT
'Benchmark',
AVG(total_applications) as total_applications,
AVG(approved / with_decision) as approval_rate,
AVG(pending_decision) as pending_decision,
AVG(approved_and_issued / approved) as issued_rate,
AVG(average_issued_sum) as average_issued_sum
FROM raw_data
WHERE day_agg BETWEEN CURRENT_DATE - INTERVAL '21 DAY' AND CURRENT_DATE - INTERVAL '1 DAY'  -- Опять, можно заменить на другие дни


