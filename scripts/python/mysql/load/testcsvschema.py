import pandas as pd

print(pd.read_csv("datasets/mysql/Customers.csv").columns.tolist())
print(pd.read_csv("datasets/mysql/Sellers.csv").columns.tolist())
print(pd.read_csv("datasets/mysql/Products.csv").columns.tolist())
print(pd.read_csv("datasets/mysql/Orders.csv").columns.tolist())
print(pd.read_csv("datasets/mysql/OrderDetails.csv").columns.tolist())