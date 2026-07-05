# Week3_Subqueries

# Superstore Sales Analysis (SQL - Subqueries, CTEs, Window Functions)

This is my SQL assignment/project where I analyze the Superstore dataset from Kaggle:
https://www.kaggle.com/datasets/vivek468/superstore-dataset-final

The goal was to practice three things specifically - subqueries, CTEs, and window
functions - by using them to answer some pretty typical business questions you'd
actually get asked about customer sales (who are the top customers, who only
ordered once, etc).

## Files

- `Superstore_SQL_Analysis.ipynb` - the main notebook, has everything (loading data,
  creating tables, all the queries, and my notes on what the results mean)
- `superstore_sales_analysis.sql` - same queries as a plain .sql file, in case
  someone wants to just run it in a SQL client instead of Jupyter
- `Sample-Superstore.csv` - the data file (see note below, this is important)

## About the CSV - read this before you run anything

I couldn't pull the dataset directly from Kaggle in the environment I built this
in (no Kaggle access), so `Sample-Superstore.csv` in this repo is actually a
stand-in I generated with the same exact columns as the real file - Order ID,
Customer Name, Segment, Region, Sales, Quantity, Discount, Profit, all of it. It's
enough to prove the whole thing runs without errors, but the numbers in it aren't
real.
.

## Schema

I split the raw data into 3 tables:

- **customers**: customer_id, customer_name, segment
- **products**: product_id, product_name, category, sub_category
- **orders**: everything order-level - dates, ship mode, sales, quantity,
  discount, profit, plus city/state/region

One thing I had to fix while testing: I originally put city/state/region in the
customers table too, but that broke the primary key constraint because the same
customer can ship orders to different cities. So the location fields live on
orders instead, and customers only has the stuff that's actually unique per
customer.

## What's in the notebook

Following the assignment steps:

1. Load the CSV into `superstore_raw`
2. Build customers/orders/products from it using `SELECT DISTINCT`
3. Subqueries - orders above average sales, highest order per customer
4. CTE - total sales per customer, then above-average customers on top of that
5. Window functions - `RANK()` for overall ranking, `ROW_NUMBER()` partitioned by
   customer, top 3 customers
6. One final query combining JOIN + CTE + window function - customer name, total
   sales, rank
7. The mini project questions: top 5, bottom 5, one-time customers,
   above-average customers, highest order value per customer

## Running it

Easiest way is just the notebook:

```
pip install pandas
jupyter notebook Superstore_SQL_Analysis.ipynb
```

It uses an in-memory SQLite database so there's nothing extra to set up, no
Postgres or MySQL server needed.

If you want to run the .sql file directly instead, load the CSV into a table
called `superstore_raw` first (matching the column names in the script), then
just run the rest of the script - `sqlite3`, `psql`, or MySQL Workbench should
all handle it fine. Window function syntax (RANK/ROW_NUMBER) is the same across
all three, so there's nothing to change there.

## A few things I noticed from the results

- A decent chunk of customers had only placed one order - that's a good
  retention flag if this were a real business.
- Most of the total sales come from a handful of top customers, which the RANK()
  query makes pretty obvious once you sort by it.
- Looking at ROW_NUMBER() partitioned by customer was actually more interesting
  than I expected - you can see how much a single customer's order values swing
  around, not just how customers compare to each other.

(Numbers above are based on the sample data included in this repo - swap in the
real Kaggle CSV and these will change.)
