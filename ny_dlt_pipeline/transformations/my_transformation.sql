create streaming table jpmc.naval_bronze.sales_raw 
as 
SELECT *,current_date() as ingestion_date FROM STREAM read_files(
    's3://jpmctraining/pipeline_input/sales',
    format => 'csv');


create streaming table jpmc.naval_silver.sales_cleaned_dlt
(Constraint valid_order_id EXPECT (order_id is not null)ON VIOLATION drop row)
as 
select distinct * except(ingestion_date,_rescued_data) from STREAM(jpmc.naval_bronze.sales_raw);


create streaming table jpmc.naval_bronze.products_raw 
as 
SELECT *,current_date() as ingestion_date FROM STREAM read_files(
    's3://jpmctraining/pipeline_input/products',
    format => 'csv');

-- Create and populate the target table.
CREATE OR REFRESH STREAMING TABLE jpmc.naval_silver.products;

APPLY CHANGES INTO
  jpmc.naval_silver.products
FROM
  stream(jpmc.naval_bronze.products_raw)
KEYS
  (product_id)
APPLY AS DELETE WHEN
  operation = "DELETE"
SEQUENCE BY
  seqNum
COLUMNS * EXCEPT
  (operation, seqNum,_rescued_data,ingestion_date)
STORED AS
  SCD TYPE 1;

create streaming table jpmc.naval_bronze.customers_raw 
as 
SELECT *, current_date() as ingestion_date FROM STREAM read_files(
    's3://jpmctraining/pipeline_input/customers',
    format => 'csv');


CREATE OR REFRESH STREAMING TABLE jpmc.naval_silver.customer;

APPLY CHANGES INTO
  jpmc.naval_silver.customer
FROM
  stream(jpmc.naval_bronze.customers_raw )
KEYS
  (customer_id)
APPLY AS DELETE WHEN
  operation = "DELETE"
SEQUENCE BY
  sequenceNum
COLUMNS * EXCEPT
  (operation, sequenceNum,_rescued_data,ingestion_date)
STORED AS
  SCD TYPE 2;
  


  