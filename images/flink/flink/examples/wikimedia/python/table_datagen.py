import logging
import sys

from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import StreamTableEnvironment


def table_datagen_example():
    """
    Simple pyflink Table API example that uses the datagen
    connector to print random table row data to stdout.

    This will
    """
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_parallelism(2)

    t_env = StreamTableEnvironment.create(stream_execution_environment=env)
    t_env.execute_sql(
        """
        CREATE TABLE orders (
          order_number BIGINT,
          price        DECIMAL(32,2),
          buyer        ROW<first_name STRING, last_name STRING>,
          order_time   TIMESTAMP(3)
        ) WITH (
          'connector' = 'datagen', 'rows-per-second' = '2'
        )
        """
    )

    t_env.execute_sql(
        """
        CREATE TABLE print_table WITH ('connector' = 'print' )
          LIKE orders (EXCLUDING ALL)
        """
    )
    t_env.execute_sql(
        """
        INSERT INTO print_table SELECT * FROM orders
        """
    )


if __name__ == '__main__':
    logging.basicConfig(stream=sys.stdout, level=logging.INFO, format="%(message)s")
    table_datagen_example()
