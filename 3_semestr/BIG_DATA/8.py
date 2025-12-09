import psycopg2
import csv
from datetime import date

DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": "postgres",
    "user": "gpadmin",
    "password": ""
}


def load_stage_kladr(conn, csv_file_path):
    with conn.cursor() as cur:
        print("Очистка stg_kladr...")
        cur.execute("TRUNCATE TABLE public.stg_kladr;")

        print("Загрузка данных в stg_kladr...")
        with open(csv_file_path, encoding='utf-8') as f:
            reader = csv.reader(f)
            for row in reader:

                # если строка пустая → пропускаем
                if not row:
                    continue

                # если значений меньше двух → ошибка CSV
                if len(row) < 2:
                    print("Пропущена строка (мало значений):", row)
                    continue

                name, code = row[0], row[1]

                cur.execute("""
                    INSERT INTO public.stg_kladr (name, code)
                    VALUES (%s, %s);
                """, (name, code))

        print("Данные загружены в stg_kladr.")


def run_dm_kladr_etl(conn, load_date=None):
    if load_date is None:
        load_date = date.today()
        
    print(f"Вызов public.fn_dm_kladr_load('{load_date}')...")

    with conn.cursor() as cur:
        cur.execute("SELECT public.fn_dm_kladr_load(%s);", (load_date,))
        result = cur.fetchone()[0]
        print(f"Функция завершилась со статусом: {result}")


def etl_process(csv_path):
    try:
        print("Подключение к Greenplum...")
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        print("Успешное подключение.")

        load_stage_kladr(conn, csv_path)
        run_dm_kladr_etl(conn)

        print("ETL-процесс завершён успешно.")

    except Exception as e:
        print("Ошибка ETL процесса:", e)

    finally:
        if 'conn' in locals():
            conn.close()
            print("Подключение закрыто.")

if __name__ == "__main__":
    CSV_FILE = "3_semestr\BIG_DATA\kladr_new.csv"
    etl_process(CSV_FILE)
