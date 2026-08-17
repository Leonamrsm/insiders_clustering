import re

def to_snake_case_columns(df):
    """
    Converts all column names of a pandas DataFrame to snake_case.

    Parameters:
    df (pd.DataFrame): Input DataFrame

    Returns:
    pd.DataFrame: DataFrame with renamed columns in snake_case
    """
    new_columns = []
    for col in df.columns:
        # Remove leading/trailing whitespace
        col = col.strip()
        # Replace spaces and special characters with underscores
        col = re.sub(r"[^\w]+", "_", col)
        # Add underscore before any capital letter that follows a lowercase (e.g., StockCode -> Stock_Code)
        col = re.sub(r'(?<=[a-z])(?=[A-Z])', '_', col)
        # Convert to lowercase
        col = col.lower()
        # Remove trailing underscores
        col = col.strip('_')
        new_columns.append(col)
    
    df.columns = new_columns
    return df