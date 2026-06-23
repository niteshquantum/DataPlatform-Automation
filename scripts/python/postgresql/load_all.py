import os
import sys

from generate_dataset import main as generate_datasets
from load_customers import load_customers
from load_sellers import load_sellers
from load_products import load_products
from load_orders import load_orders
from load_orderdetails import load_orderdetails
from validate_loaded_data import validate_loaded_data


def get_project_root():
    return os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "..", "..")
    )


def load_all():

    project_root = get_project_root()
    dataset_path = os.path.join(project_root, "datasets", "postgresql")

    customers_file    = os.path.join(dataset_path, "Customers.csv")
    sellers_file      = os.path.join(dataset_path, "Sellers.csv")
    products_file     = os.path.join(dataset_path, "Products.csv")
    orders_file       = os.path.join(dataset_path, "Orders.csv")
    orderdetails_file = os.path.join(dataset_path, "OrderDetails.csv")

    # Auto-generate datasets if missing or placeholder (< 200 bytes)
    needs_gen = False
    for f in [customers_file, sellers_file, products_file, orders_file, orderdetails_file]:
        if not os.path.exists(f) or os.path.getsize(f) < 200:
            needs_gen = True
            break

    if needs_gen:
        print("Datasets missing or empty - generating now...")
        generate_datasets()

    print("=" * 60)
    print("POSTGRESQL DATA LOAD")
    print("=" * 60)

    load_customers(customers_file)
    load_sellers(sellers_file)
    load_products(products_file)
    load_orders(orders_file)
    load_orderdetails(orderdetails_file)
    validate_loaded_data()

    print("\nLoad Completed Successfully")


if __name__ == "__main__":
    try:
        load_all()
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)
