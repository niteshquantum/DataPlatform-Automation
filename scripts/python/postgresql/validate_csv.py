import os
import pandas as pd


def validate_csv(file_path):

    if not os.path.exists(file_path):

        raise FileNotFoundError(
            f"File not found : {file_path}"
        )

    dataframe = pd.read_csv(file_path)

    print(
        f"{os.path.basename(file_path)} : "
        f"{len(dataframe)} rows"
    )

    return True


if __name__ == "__main__":

    raise Exception(
        "Pass CSV path from caller"
    )