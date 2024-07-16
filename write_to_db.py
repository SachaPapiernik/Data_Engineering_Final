import os
import pyodbc
import logging
import traceback
import pandas as pd
from function import create_df

def table_exists(cursor: pyodbc.Cursor, table_name: str) -> bool:
    """
    Check if a table exists in the database.

    Parameters:
    cursor (pyodbc.Cursor): The database cursor.
    table_name (str): The name of the table to check.

    Returns:
    bool: True if the table exists, False otherwise.
    """
    cursor.execute(f'''
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = '{table_name}'
    ''')
    result = cursor.fetchone()
    return result[0] == 1

def create_table_from_df(cursor: pyodbc.Cursor, df: pd.DataFrame, table_name: str, logger: logging.Logger) -> None:
    """
    Create a table in the database based on the schema of a DataFrame.

    Parameters:
    cursor (pyodbc.Cursor): The database cursor.
    df (pd.DataFrame): The DataFrame containing the schema.
    table_name (str): The name of the table to create.
    logger (logging.Logger): The logger for logging information.
    """
    columns_with_types = []
    for column, dtype in df.dtypes.items():
        if dtype == 'int64':
            columns_with_types.append(f"{column} INT")
        elif dtype == 'float64':
            columns_with_types.append(f"{column} FLOAT")
        elif dtype == 'bool':
            columns_with_types.append(f"{column} BIT")
        elif dtype == 'datetime64[ns]':
            columns_with_types.append(f"{column} DATETIME")
        else:
            columns_with_types.append(f"{column} NVARCHAR(255)")

    create_table_sql = f"CREATE TABLE {table_name} ({', '.join(columns_with_types)})"

    logger.info(f"Generated SQL: {create_table_sql}")
    cursor.execute(create_table_sql)

def insert_data_from_df(df: pd.DataFrame, table_name: str, batch_size: int = 1000, logger: logging.Logger = None) -> None:
    """
    Insert data from a DataFrame into a database table in batches.

    Parameters:
    df (pd.DataFrame): The DataFrame containing the data.
    table_name (str): The name of the table to insert data into.
    batch_size (int): The number of rows to insert per batch. Default is 1000.
    logger (logging.Logger): The logger for logging information. Default is None.
    """
    columns = ', '.join(df.columns)
    values = ', '.join(['?' for _ in df.columns])
    insert_sql = f"INSERT INTO {table_name} ({columns}) VALUES ({values})"
    batch = []
    total_rows = len(df)
    batches_inserted = 0

    for index, row in df.iterrows():
        batch.append(tuple(row))
        if len(batch) == batch_size:
            # Open a new connection and cursor
            conn, cursor = open_connection()
            cursor.executemany(insert_sql, batch)
            conn.commit()
            batches_inserted += 1
            if logger:
                logger.info(f"Batch {batches_inserted} inserted ({index + 1} out of {total_rows} rows).")
            batch = []
            # Close the connection and cursor
            cursor.close()
            conn.close()

    if batch:
        conn, cursor = open_connection()
        cursor.executemany(insert_sql, batch)
        conn.commit()
        batches_inserted += 1
        if logger:
            logger.info(f"Batch {batches_inserted} inserted (final batch).")
        cursor.close()
        conn.close()

def create_and_populate_table(cursor: pyodbc.Cursor, df: pd.DataFrame, table_name: str, logger: logging.Logger) -> None:
    """
    Create a table and populate it with data from a DataFrame.

    Parameters:
    cursor (pyodbc.Cursor): The database cursor.
    df (pd.DataFrame): The DataFrame containing the data.
    table_name (str): The name of the table to create and populate.
    logger (logging.Logger): The logger for logging information.
    """
    create_table_from_df(cursor, df, table_name, logger)
    if table_exists(cursor, table_name):
        logger.info(f"Table {table_name} created successfully.")
        insert_data_from_df(df, table_name, logger=logger)
        logger.info(f"Data inserted into table {table_name} successfully.")
    else:
        logger.error(f"Table {table_name} creation failed.")

def open_connection() -> tuple:
    """
    Open a database connection.

    Returns:
    tuple: A tuple containing the database connection and cursor.
    """
    server = os.getenv('DB_SERVER')
    database = os.getenv('DB_DATABASE')
    username = os.getenv('DB_USERNAME')
    password = os.getenv('DB_PASSWORD')
    driver = os.getenv('DB_DRIVER', '{ODBC Driver 18 for SQL Server}')

    conn = pyodbc.connect(f'DRIVER={driver};SERVER={server};PORT=1433;DATABASE={database};UID={username};PWD={password}')
    conn.autocommit = True
    cursor = conn.cursor()
    return conn, cursor

def main() -> None:
    """
    Main function to create and populate database tables from DataFrames.
    """
    # Configure logging
    logging.basicConfig(level=logging.INFO, 
                        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                        handlers=[
                            logging.FileHandler("app.log"),
                            logging.StreamHandler()
                        ])
    logger = logging.getLogger(__name__)

    try:
        conn, cursor = open_connection()

        # Call create_df to get the DataFrames
        circo_table, circo_data, circo_candidate_data = create_df()

        # Create and populate tables
        create_and_populate_table(cursor, circo_table, 'CircoTable', logger)
        create_and_populate_table(cursor, circo_data, 'CircoData', logger)
        create_and_populate_table(cursor, circo_candidate_data, 'CircoCandidateData', logger)

        cursor.close()
        conn.close()

        logger.info("Database operations completed.")
    except Exception as e:
        logger.error("Error: %s", e)
        logger.error("Traceback: %s", traceback.format_exc())

if __name__ == "__main__":
    main()
