--- pgbench -i -s 10 -h localhost -U postgres -d db-labs

EXPLAIN ANALYZE SELECT * FROM pgbench_accounts WHERE abalance > 500;

--pgbench -c 10 -t 1000 -h localhost -U postgres -d db-labs

-- найти сумму балансов счетов (abalance) по филиалам,
-- где есть транзакции с положительным delta в 2025 году.
EXPLAIN ANALYZE
SELECT b.bid, SUM(a.abalance) as total_balance
FROM pgbench_accounts a
JOIN pgbench_branches b ON a.bid = b.bid
JOIN pgbench_history h ON a.aid = h.aid
WHERE a.abalance > 500
AND h.mtime >= '2025-01-01' AND h.mtime < '2026-01-01'
AND h.delta > 0
GROUP BY b.bid
ORDER BY total_balance DESC;
-- create index
CREATE INDEX idx_accounts_abalance ON pgbench_accounts(abalance);
CREATE INDEX idx_history_mtime ON pgbench_history(mtime);
CREATE INDEX idx_history_aid_delta ON pgbench_history(aid, delta);
CREATE INDEX idx_accounts_bid ON pgbench_accounts(bid);
---drop index
DROP INDEX idx_accounts_abalance;
DROP INDEX idx_history_mtime;
DROP INDEX idx_history_aid_delta;
DROP INDEX idx_accounts_bid;

---филиалы, где средний баланс счетов
-- выше общего среднего, с учетом транзакций кассиров (tellers)
EXPLAIN ANALYZE
SELECT b.bid, AVG(a.abalance) as avg_balance
FROM pgbench_accounts a
JOIN pgbench_branches b ON a.bid = b.bid
JOIN pgbench_tellers t ON t.bid = b.bid
JOIN pgbench_history h ON h.tid = t.tid AND h.aid = a.aid
WHERE h.delta > 0
GROUP BY b.bid
HAVING AVG(a.abalance) > (SELECT AVG(abalance) FROM pgbench_accounts)
ORDER BY avg_balance DESC;

---с предварительным вычислением среднего
EXPLAIN ANALYZE
WITH avg_balance AS (SELECT AVG(abalance) as overall_avg FROM pgbench_accounts)
SELECT b.bid, AVG(a.abalance) as avg_balance
FROM pgbench_accounts a
JOIN pgbench_branches b ON a.bid = b.bid
JOIN pgbench_tellers t ON t.bid = b.bid
JOIN pgbench_history h ON h.tid = t.tid AND h.aid = a.aid
WHERE h.delta > 0
GROUP BY b.bid
HAVING AVG(a.abalance) > (SELECT overall_avg FROM avg_balance)
ORDER BY avg_balance DESC;

---предварительную агрегацию по pgbench_accounts и pgbench_branches,
-- чтобы уменьшить количество строк перед финальным HAVING
EXPLAIN ANALYZE
WITH avg_balance AS (
    SELECT AVG(abalance) as overall_avg FROM pgbench_accounts
),
pre_aggregated AS (
    SELECT a.bid, AVG(a.abalance) as avg_balance
    FROM pgbench_accounts a
    JOIN pgbench_branches b ON a.bid = b.bid
    JOIN pgbench_tellers t ON t.bid = b.bid
    JOIN pgbench_history h ON h.tid = t.tid AND h.aid = a.aid
    WHERE h.delta > 0
    GROUP BY a.bid
)
SELECT bid, avg_balance
FROM pre_aggregated
WHERE avg_balance > (SELECT overall_avg FROM avg_balance)
ORDER BY avg_balance DESC;