CREATE TABLE IF NOT EXISTS public.sales_agg (
    sale_date DATE NOT NULL,
    product TEXT NOT NULL,
    total_quantity INT NOT NULL,
    total_amount NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (sale_date, product)
);
