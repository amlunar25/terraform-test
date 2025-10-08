import json
import io
import csv
import pg8000.native
import boto3
import os
from collections import defaultdict

# Environment variables set in Lambda
DB_HOST = os.environ["DB_HOST"]
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]
DB_PORT = int(os.environ.get("DB_PORT", 5432))

s3_client = boto3.client("s3")

def handler(event, context):
    try:
        # Check if this Lambda is invoked via S3 or API Gateway
        if "Records" in event:  # S3 trigger
            for record in event["Records"]:
                bucket = record["s3"]["bucket"]["name"]
                key = record["s3"]["object"]["key"]
                bucket = "my-private-bucket-terraform-test-nanlab1"
                key = "sales.csv"

                response = s3_client.get_object(Bucket=bucket, Key=key)
                file_content = response["Body"].read().decode("utf-8")

                reader = csv.DictReader(io.StringIO(file_content))
                aggregation = defaultdict(lambda: {"total_quantity": 0, "total_amount": 0.0})

                print(f"Aggrr  {aggregation}")
                for row in reader:
                    sale_date = row["date"]
                    product = row["product"]
                    quantity = int(row["quantity"])
                    amount = float(row["price"])
                    key_agg = (sale_date, product)
                    aggregation[key_agg]["total_quantity"] += quantity
                    aggregation[key_agg]["total_amount"] += amount

                # Connect to Postgres
                conn = pg8000.native.Connection(
                    host=DB_HOST,
                    database=DB_NAME,
                    user=DB_USER,
                    password=DB_PASSWORD,
                    port=DB_PORT
                )

                # Insert/Update aggregated data
                for (sale_date, product), values in aggregation.items():
                    conn.run(
                        """
                        INSERT INTO sales_agg (sale_date, product, total_quantity, total_amount)
                        VALUES (:sale_date, :product, :total_quantity, :total_amount)
                        ON CONFLICT (sale_date, product) 
                        DO UPDATE SET 
                          total_quantity = sales_agg.total_quantity + EXCLUDED.total_quantity,
                          total_amount = sales_agg.total_amount + EXCLUDED.total_amount;
                        """,
                        sale_date=sale_date,
                        product=product,
                        total_quantity=values["total_quantity"],
                        total_amount=values["total_amount"]
                    )

                conn.close()
            return {"statusCode": 200, "body": "CSV processed successfully."}

        else:  # API Gateway trigger
            conn = pg8000.native.Connection(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD,
                port=DB_PORT
            )
            result = conn.run("SELECT * FROM sales_agg;")
            columns = [desc[0] for desc in conn.run("SELECT column_name FROM information_schema.columns WHERE table_name='sales_agg'")]

            # Map tuples to dicts
            res = []
            for row in result:
                res.append({columns[0]: str(row[0]), 
                columns[1]: str(row[1]),
                columns[2]: str(row[2]),
                columns[3]: str(row[3])})
            
            conn.close()
            
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps(res)
            }

    except Exception as e:
        return {"statusCode": 500, "body": str(e)}