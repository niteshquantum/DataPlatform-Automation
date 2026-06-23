import sys
from check_port import check_port


def validate_port():

    if not check_port():

        raise Exception(
            "Port validation failed"
        )

    print(
        "Port validation successful"
    )


if __name__ == "__main__":

    try:

        validate_port()

    except Exception as error:

        print(error)
        sys.exit(1)