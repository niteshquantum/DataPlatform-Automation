import os
import random
import pandas as pd
from datetime import datetime, timedelta


CUSTOMERS_COUNT    = 100
SELLERS_COUNT      = 50
PRODUCTS_COUNT     = 100
ORDERS_COUNT       = 500
ORDERDETAILS_COUNT = 500

CITIES = [
    "Mumbai","Delhi","Bangalore","Chennai","Hyderabad",
    "Pune","Kolkata","Ahmedabad","Jaipur","Surat",
    "New York","London","Berlin","Paris","Tokyo",
    "Sydney","Toronto","Dubai","Singapore","Seoul"
]
FIRSTNAMES = [
    "Aarav","Priya","Ravi","Ananya","Vikram",
    "Sneha","Arjun","Meera","Rahul","Kavya",
    "James","Emma","Liam","Olivia","Noah",
    "Ava","William","Isabella","Oliver","Sophia"
]
LASTNAMES = [
    "Sharma","Patel","Singh","Kumar","Verma",
    "Mehta","Joshi","Nair","Iyer","Gupta",
    "Smith","Johnson","Brown","Williams","Jones",
    "Davis","Miller","Wilson","Moore","Taylor"
]
CATEGORIES = [
    "Electronics","Clothing","Home & Garden","Sports","Books",
    "Toys","Automotive","Health","Food","Beauty"
]
PRODUCT_TYPES = [
    "Laptop","Phone","Shirt","Jacket","Lamp",
    "Chair","Bicycle","Watch","Novel","Camera",
    "Headphones","Tablet","Jeans","Sneakers","Blender",
    "Sofa","Dumbbells","Sunglasses","Cookbook","Drone"
]
SELLER_NAMES = [
    "TechMart","QuickShip","MegaStore","FastBuy","SmartDeal",
    "PrimeSell","EasyCart","TopVendor","BestChoice","SwiftTrade"
]


def get_project_root():
    return os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "..", "..")
    )


def get_dataset_directory():
    dataset_dir = os.path.join(get_project_root(), "datasets", "postgresql")
    os.makedirs(dataset_dir, exist_ok=True)
    return dataset_dir


def generate_customers(dataset_dir):
    random.seed(42)
    customers = []
    for i in range(1, CUSTOMERS_COUNT + 1):
        fn = FIRSTNAMES[i % len(FIRSTNAMES)]
        ln = LASTNAMES[i % len(LASTNAMES)]
        customers.append({
            "customer_id":   i,
            "customer_name": f"{fn} {ln}",
            "email":         f"{fn.lower()}.{ln.lower()}{i}@example.com",
            "city":          CITIES[i % len(CITIES)]
        })
    fp = os.path.join(dataset_dir, "Customers.csv")
    pd.DataFrame(customers).to_csv(fp, index=False)
    print(f"Generated Customers.csv : {len(customers)} rows")


def generate_sellers(dataset_dir):
    sellers = []
    for i in range(1, SELLERS_COUNT + 1):
        sellers.append({
            "seller_id":   i,
            "seller_name": f"{SELLER_NAMES[i % len(SELLER_NAMES)]} {i}"
        })
    fp = os.path.join(dataset_dir, "Sellers.csv")
    pd.DataFrame(sellers).to_csv(fp, index=False)
    print(f"Generated Sellers.csv : {len(sellers)} rows")


def generate_products(dataset_dir):
    random.seed(99)
    products = []
    for i in range(1, PRODUCTS_COUNT + 1):
        products.append({
            "product_id":   i,
            "product_name": f"{PRODUCT_TYPES[i % len(PRODUCT_TYPES)]} Pro {i}",
            "category":     CATEGORIES[i % len(CATEGORIES)],
            "price":        round(random.uniform(99.99, 4999.99), 2)
        })
    fp = os.path.join(dataset_dir, "Products.csv")
    pd.DataFrame(products).to_csv(fp, index=False)
    print(f"Generated Products.csv : {len(products)} rows")


def generate_orders(dataset_dir):
    random.seed(77)
    start = datetime(2023, 1, 1)
    orders = []
    for i in range(1, ORDERS_COUNT + 1):
        orders.append({
            "order_id":    i,
            "customer_id": random.randint(1, CUSTOMERS_COUNT),
            "product_id":  random.randint(1, PRODUCTS_COUNT),
            "quantity":    random.randint(1, 10),
            "order_date":  (start + timedelta(days=random.randint(0, 730))).strftime("%Y-%m-%d")
        })
    fp = os.path.join(dataset_dir, "Orders.csv")
    pd.DataFrame(orders).to_csv(fp, index=False)
    print(f"Generated Orders.csv : {len(orders)} rows")


def generate_orderdetails(dataset_dir):
    random.seed(55)
    orderdetails = []
    for i in range(1, ORDERDETAILS_COUNT + 1):
        orderdetails.append({
            "orderdetail_id": i,
            "order_id":       random.randint(1, ORDERS_COUNT),
            "product_id":     random.randint(1, PRODUCTS_COUNT),
            "quantity":       random.randint(1, 5),
            "unit_price":     round(random.uniform(99.99, 4999.99), 2)
        })
    fp = os.path.join(dataset_dir, "OrderDetails.csv")
    pd.DataFrame(orderdetails).to_csv(fp, index=False)
    print(f"Generated OrderDetails.csv : {len(orderdetails)} rows")


def main():
    print("=" * 60)
    print("POSTGRESQL DATASET GENERATION")
    print("=" * 60)
    dataset_dir = get_dataset_directory()
    generate_customers(dataset_dir)
    generate_sellers(dataset_dir)
    generate_products(dataset_dir)
    generate_orders(dataset_dir)
    generate_orderdetails(dataset_dir)
    print("\nDataset generation completed successfully")


if __name__ == "__main__":
    main()
