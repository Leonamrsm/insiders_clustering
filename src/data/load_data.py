import pandas as pd

def load_ecommerce_data(file_path: str) -> pd.DataFrame:
    """
    Load and clean the Ecommerce raw dataset.

    Parameters:
    file_path (str): The path to the CSV file containing the raw dataset.

    Returns:
    pd.DataFrame: A pandas DataFrame containing the cleaned data.
    """
    # Read the CSV file into a DataFrame with specified encoding
    dataframe = pd.read_csv(file_path, encoding="latin1")

    # Drop the 'Unnamed: 8' column if it exists, which may be an extra column
    if "Unnamed: 8" in dataframe.columns:
        dataframe.drop(columns="Unnamed: 8", inplace=True)

    # Return the cleaned DataFrame
    return dataframe
