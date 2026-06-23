import pandas as pd


def validate_customers(file_path):

    dataframe = pd.read_csv(file_path)

    print("=" * 60)
    print("CUSTOMER VALIDATION")
    print("=" * 60)

    print(
        f"Rows : {len(dataframe)}"
    )

    print(
        f"Columns : "
        f"{len(dataframe.columns)}"
    )

    duplicates = dataframe.duplicated().sum()

    print(
        f"Duplicates : {duplicates}"
    )

    nulls = dataframe.isnull().sum().sum()

    print(
        f"Null Values : {nulls}"
    )

    return True


if __name__ == "__main__":

    raise Exception(
        "Pass customer csv path"
    )