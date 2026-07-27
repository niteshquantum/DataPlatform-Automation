import gdown


def download(url, output_path):
    """
    Download a file from Google Drive.

    Parameters
    ----------
    url : str
        Google Drive share URL.

    output_path : str
        Destination file path.
    """

    gdown.download(
        url,
        output_path,
        quiet=False
    )