import pandas as pd

def load_ecommerce_data(file_path: str) -> pd.DataFrame:
    """
    Load and clean the Ecommerce dataset.

    Parameters
    ----------
    file_path : str
        Local path or S3 URI (e.g. s3://bucket/Ecommerce.csv).

    Returns
    -------
    pd.DataFrame
        Cleaned dataframe.
    """

    # Read CSV
    dataframe = pd.read_csv(
        file_path,
        encoding="latin1",
    )

    # Remove unnecessary column if present
    dataframe.drop(columns=["Unnamed: 8"], errors="ignore", inplace=True)

    return dataframe
