import pandas as pd
from backend.python_pipelines.data_load_functions.utility_functions import get_engine


def get_data_from_database(table_name: str):
    engine = get_engine()

    query = f"""
    select *
    from {table_name}
    """
    
    with engine.connect() as conn:
        df = pd.read_sql(query, conn)

    return df
