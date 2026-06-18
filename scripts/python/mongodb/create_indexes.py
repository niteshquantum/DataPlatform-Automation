from db_connection import get_db

db = get_db()

db.customers.create_index("customer_id")
db.sellers.create_index("seller_id")
db.products.create_index("product_id")
db.orders.create_index("order_id")
db.orderdetails.create_index([
    ("order_id", 1),
    ("product_id", 1)
])

print("Indexes created successfully.")