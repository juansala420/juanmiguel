from datetime import datetime, timezone

from airflow import DAG
from airflow.operators.python import PythonOperator
from runtime import run_dbt

with DAG(
    dag_id="examen_ventas",
    start_date=datetime(2026, 1, 1, tzinfo=timezone.utc),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    max_active_tasks=1,
    default_args={"retries": 0},
    tags=["examen"],
) as dag:
    # Comprueba la actualidad de raw.ventas antes de reconstruir el resumen.
    # Una advertencia (más de 12 h) termina con salida 0 y deja continuar; un error
    # (más de 24 h) hace que run_dbt lance la excepción y la tarea quede failed.
    comprobar_freshness = PythonOperator(
        task_id="comprobar_freshness",
        python_callable=run_dbt,
        op_args=[["source", "freshness"]],
    )
    construir_resumen = PythonOperator(
        task_id="construir_resumen",
        python_callable=run_dbt,
        op_args=[["build"]],
    )

    # Con la regla predeterminada all_success, build solo corre si freshness terminó
    # bien; si freshness falla, build queda upstream_failed y el resumen anterior se conserva.
    comprobar_freshness >> construir_resumen
