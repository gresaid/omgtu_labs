import base64
import json
import urllib.error
import urllib.request
from datetime import date, datetime
from decimal import Decimal

import psycopg2


GREENPLUM_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": "postgres",
    "user": "gpadmin",
    "password": "",
}

CLICKHOUSE_CONFIG = {
    "host": "localhost",
    "port": 8123,
    "database": "default",
    "user": "usr",
    "password": "pwd123",
}

CLICKHOUSE_TABLE = "dm_transactions_denorm"
COLUMN_LIST = [
    "transaction_id",
    "dt",
    "card",
    "client_id",
    "full_name",
    "phone",
    "passport",
    "address_code",
    "region_id",
    "region_code",
    "region_name",
    "dist_id",
    "dist_code",
    "dist_name",
    "city_id",
    "city_code",
    "city_name",
    "street_id",
    "street_code",
    "street_name",
    "operation_type",
    "amount",
    "operation_result",
    "terminal_id",
    "load_dt",
]
BATCH_SIZE = 2000


def fetch_gp_rows():
    query = f"""
        SELECT {", ".join(COLUMN_LIST)}
        FROM dm.dm_transactions_denorm
        ORDER BY load_dt, transaction_id
    """
    with psycopg2.connect(**GREENPLUM_CONFIG) as conn:
        conn.set_client_encoding("UTF8")
        cursor = conn.cursor(name="gp_to_ch")
        cursor.itersize = BATCH_SIZE
        cursor.execute(query)
        while True:
            portion = cursor.fetchmany(BATCH_SIZE)
            if not portion:
                break
            yield portion


def ensure_clickhouse_table():
    ddl = f"""
        CREATE TABLE IF NOT EXISTS {CLICKHOUSE_TABLE} (
            transaction_id String,
            dt Nullable(Date),
            card Nullable(Int64),
            client_id Nullable(String),
            full_name Nullable(String),
            phone Nullable(String),
            passport Nullable(String),
            address_code Nullable(String),
            region_id Nullable(Int64),
            region_code Nullable(String),
            region_name Nullable(String),
            dist_id Nullable(Int64),
            dist_code Nullable(String),
            dist_name Nullable(String),
            city_id Nullable(Int64),
            city_code Nullable(String),
            city_name Nullable(String),
            street_id Nullable(Int64),
            street_code Nullable(String),
            street_name Nullable(String),
            operation_type Nullable(String),
            amount Nullable(Float64),
            operation_result Nullable(String),
            terminal_id Nullable(String),
            load_dt DateTime
        ) ENGINE = MergeTree
        ORDER BY (transaction_id, dt)
        SETTINGS allow_nullable_key = 1
    """
    execute_clickhouse(ddl)
    execute_clickhouse(f"TRUNCATE TABLE {CLICKHOUSE_TABLE}")


def execute_clickhouse(query: str):
    url = f"http://{CLICKHOUSE_CONFIG['host']}:{CLICKHOUSE_CONFIG['port']}/?database={CLICKHOUSE_CONFIG['database']}"
    auth_token = base64.b64encode(
        f"{CLICKHOUSE_CONFIG['user']}:{CLICKHOUSE_CONFIG['password']}".encode("utf-8")
    ).decode("ascii")
    request = urllib.request.Request(
        url,
        data=query.encode("utf-8"),
        method="POST",
        headers={"Authorization": f"Basic {auth_token}"},
    )
    try:
        with urllib.request.urlopen(request) as response:
            response.read()
    except urllib.error.HTTPError as err:
        details = err.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"ClickHouse HTTP {err.code}: {details}") from err


def normalize(value):
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%d %H:%M:%S")
    if isinstance(value, date):
        return value.isoformat()
    if isinstance(value, Decimal):
        return float(value)
    return value


def send_to_clickhouse(rows):
    if not rows:
        return
    json_lines = []
    for row in rows:
        obj = {col: normalize(val) for col, val in zip(COLUMN_LIST, row)}
        json_lines.append(json.dumps(obj, ensure_ascii=False))

    payload = (
        f"INSERT INTO {CLICKHOUSE_TABLE} FORMAT JSONEachRow\n"
        + "\n".join(json_lines)
        + "\n"
    )
    execute_clickhouse(payload)


def main():
    print("cоздание таблицы в ClickHouse...")
    ensure_clickhouse_table()

    transferred = 0
    for batch in fetch_gp_rows():
        send_to_clickhouse(batch)
        transferred += len(batch)
        print(f"перенесено строк: {transferred}")

    print(f"готово:) всеего перенесено {transferred} строк.")


if __name__ == "__main__":
    main()
