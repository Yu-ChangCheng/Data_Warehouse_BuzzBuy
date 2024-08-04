----------------------------------------------------------------------------
-- ADD DATA TO USER TABLE
----------------------------------------------------------------------------

-- This script adds data from the TSV file to the Users table in the database.
-- Step 1: Create a temporary table
CREATE TEMP TABLE temp_users (
    employee_id TEXT,
    first_name TEXT,
    last_name TEXT,
    ssn_last4 TEXT,
    audit_log_access INT,
    districts_assigned TEXT
);

-- Step 2: Import data into the temporary table
COPY temp_users
FROM '/Users/ravinderbadwal/Downloads/Demo Data/City.tsv'
DELIMITER E'\t'
CSV HEADER;

-- Step 3: Insert required data into the Users table
INSERT INTO Users (employee_id, first_name, last_name, ssn_last4)
SELECT employee_id, first_name, last_name, ssn_last4 FROM temp_users;

-- Step 4: Drop the temporary table
DROP TABLE temp_users;

----------------------------------------------------------------------------
-- ADD DATA TO MANUFACTURER TABLE
----------------------------------------------------------------------------

--- Manufacturer table can easily be loaded with the data from the Manufacturer.tsv file.
COPY manufacturer FROM '/Users/ravinderbadwal/Downloads/Demo Data/Manufacturer.tsv' DELIMITER E'\t' CSV HEADER;

----------------------------------------------------------------------------
-- ADD DATA TO CITY TABLE
----------------------------------------------------------------------------

--- For city table, we need to update the state column to state_loc because 'state' is a reserved keyword in SQL.

ALTER TABLE city
RENAME COLUMN state TO state_loc;

--- city_id is not in the provided City.tsv data file, so altered it to autogenerate a value in sequence. We can talk about whether or not we want to keep this as a primary key.

CREATE SEQUENCE IF NOT EXISTS city_city_id_seq;

ALTER TABLE city
ALTER COLUMN city_id
SET DEFAULT nextval('city_city_id_seq'::regclass);

--- find the and update the owner below. Right click on the DB in postgresql and see properties, for me it was my username 'ravinderbadwal'

ALTER SEQUENCE city_city_id_seq
OWNER to ravinderbadwal;

--- After doing the above modifications to table city, we can now load data into the City table.
CREATE TEMP TABLE temp_city (
    city_name TEXT,
    state_loc TEXT,
    population INT
);

COPY temp_city FROM '/Users/ravinderbadwal/Downloads/Demo Data/City.tsv' DELIMITER E'\t' CSV HEADER;

INSERT INTO City (city_name, state_loc, population)
SELECT city_name, state_loc, population FROM temp_city;

DROP TABLE temp_city;

----------------------------------------------------------------------------
-- ADD DATA TO DISTRICT TABLE
----------------------------------------------------------------------------

--- Add data to the District table from the District.tsv file.
COPY district
FROM '/Users/ravinderbadwal/Downloads/Demo Data/District.tsv'
DELIMITER E'\t'
CSV HEADER;


----------------------------------------------------------------------------
-- ADD DATA TO STORE TABLE
----------------------------------------------------------------------------

--- Add data to the Store table from the Store.tsv file.
-- Note: that I joined the City table to get the city_id. Also note that I concatenated the city_name and state columns to create the address column. Address was not a column in the tsv file, so I created it.

CREATE TEMP TABLE temp_store (
    store_number INT,
    phone BIGINT,
    city_name TEXT,
    city_state TEXT,
    district_number INT,
    address TEXT
);

COPY temp_store(store_number, phone, city_name, city_state, district_number)
FROM '/Users/ravinderbadwal/Downloads/Demo Data/Store.tsv'
DELIMITER E'\t'
CSV HEADER;

UPDATE temp_store SET address = city_name || ', ' || city_state;

INSERT INTO store (store_number, phone_number, city_id, district_number, address)
SELECT ts.store_number, ts.phone, c.city_id, ts.district_number, ts.address
FROM temp_store ts
JOIN City c ON ts.city_name = c.city_name;


----------------------------------------------------------------------------
-- ADD DATA TO CATEGORY TABLE
----------------------------------------------------------------------------

--- Add data to the Category table from the Category.tsv file.
COPY category_name FROM '/Users/ravinderbadwal/Downloads/Demo Data/Category.tsv' DELIMITER E'\t' CSV HEADER;

--- Add data to the Product table from the Product.tsv file.
CREATE TEMP TABLE temp_product (
    PID INT,
    Product_Name TEXT,
    Manufacturer TEXT,
    retail_price NUMERIC,
    categories TEXT
);

----------------------------------------------------------------------------
-- ADD DATA TO PRODUCT TABLE
----------------------------------------------------------------------------

COPY temp_product FROM '/Users/ravinderbadwal/Downloads/Demo Data/Product.tsv' DELIMITER E'\t' CSV HEADER;

INSERT INTO product (pid, product_name, manufacturer_name, price)
SELECT PID, Product_Name, Manufacturer, retail_price FROM temp_product;

DROP TABLE temp_product;

--- Add data to the ProductCategory table from the ProductCategory.tsv file. This one was a bit more complex because the categories column contained multiple values separated by commas. We needed to normalize this data into separate rows in the ProductCategory table.

CREATE TEMP TABLE temp_product_categories (
    PID INT,
    Product_Name TEXT,
    Manufacturer TEXT,
    retail_price NUMERIC,
    categories TEXT
);

COPY temp_product_categories
FROM '/Users/ravinderbadwal/Downloads/Demo Data/Product.tsv'
DELIMITER E'\t'
CSV HEADER;

-- Normalize categories by splitting them into separate rows and then inserting into the ProductCategory table

CREATE OR REPLACE FUNCTION split_string_to_table(text, text)
RETURNS TABLE (category_name text) AS $$
BEGIN
   RETURN QUERY SELECT unnest(string_to_array($1, $2));
END;
$$ LANGUAGE plpgsql;

WITH split_categories AS (
  SELECT
    PID,
    unnest(string_to_array(categories, ',')) AS category_name
  FROM temp_product_categories
)
INSERT INTO productcategory (pid, category_name)
SELECT
  sc.PID,
  sc.category_name
FROM split_categories sc
JOIN category c ON sc.category_name = c.category_name;

DROP TABLE temp_product_categories;

----------------------------------------------------------------------------
-- ADD DATA TO DISCOUNT TABLE
----------------------------------------------------------------------------

--- Add data from discount.tsv to the Discount table.
--- The discount_id column was not present in the Discount.tsv file. Again, I altered the table to autogenerate this value in sequence.
CREATE SEQUENCE IF NOT EXISTS discount_id_seq;

ALTER TABLE discount
ALTER COLUMN discount_id
SET DEFAULT nextval('discount_id_seq'::regclass);

ALTER SEQUENCE discount_id_seq
OWNER to ravinderbadwal;

--- Now load data into the Discount table
CREATE TEMP TABLE temp_discount (
    date_discount DATE,
    PID INT,
    discount_price NUMERIC
);

COPY temp_discount FROM '/Users/ravinderbadwal/Downloads/Demo Data/Discount.tsv' DELIMITER E'\t' CSV HEADER;

INSERT INTO discount (discount_price, discount_date)
SELECT discount_price, date_discount FROM temp_discount;

--- Match the discount_id in the Discount table with the PID in the Discount.tsv file and update the DiscountAppliesToProduct table.

ALTER TABLE temp_discount ADD COLUMN discount_id VARCHAR(50);

-- Update the temp_discount table with discount_id from the Discount table based on matching criteria
UPDATE temp_discount td
SET discount_id = d.discount_id
FROM discount d
WHERE td.date_discount = d.discount_date AND td.discount_price = d.discount_price;

INSERT INTO discountappliestoproduct (discount_id, pid)
SELECT discount_id, PID::VARCHAR(50)
FROM temp_discount
WHERE discount_id IS NOT NULL;

DROP TABLE temp_discount;

----------------------------------------------------------------------------
-- ADD DATA TO SOLD TABLE
----------------------------------------------------------------------------

--- Add data from Sold.tsv to the Sold table.

--- first need to alter the date column to date_sold because 'date' is a reserved keyword in SQL.
ALTER TABLE Sales
RENAME COLUMN date TO date_sold;

--- sales_id is not in the provided Sold.tsv data file, so altered it to autogenerate a value in sequence. We can talk about whether or not we want to keep this as a primary key.
CREATE SEQUENCE IF NOT EXISTS sales_id_seq;

ALTER TABLE sales
ALTER COLUMN sales_id
SET DEFAULT nextval('sales_id_seq'::regclass);

ALTER SEQUENCE sales_id_seq
OWNER to ravinderbadwal;

--- I dropped the total column from the Sales table because it was not present in the Sold.tsv file. Let's talk about it if we need to add it.
ALTER TABLE Sales
DROP COLUMN total;

--- Now load data into the Sales table
CREATE TEMP TABLE temp_sales (
    PID INT,
    date_sold DATE,
    store_number INT,
    quantity INT
);

COPY temp_sales FROM '/Users/ravinderbadwal/Downloads/Demo Data/Sold.tsv' DELIMITER E'\t' CSV HEADER;

INSERT INTO sales (pid, date_sold, store_number, quantity)
SELECT PID, date_sold, store_number, quantity FROM temp_sales;

DROP TABLE temp_sales;

----------------------------------------------------------------------------
-- ADD DATA TO DISTRICT TABLE
----------------------------------------------------------------------------

--- Add district assignment from User.tsv to the UserAssignedToDistrict table.
CREATE TEMP TABLE temp_user (
    employeeID TEXT,
    first_name TEXT,
    last_name TEXT,
    last_4_ssn TEXT,
    audit_log_access INT,
    districts_assigned TEXT
);

COPY temp_user
FROM '/Users/ravinderbadwal/Downloads/Demo Data/User.tsv'
DELIMITER E'\t'
CSV HEADER;

-- Normalize districts_assigned by splitting them into separate rows using a split function
CREATE OR REPLACE FUNCTION split_districts_assigned(text)
RETURNS TABLE (district_assigned text) AS $$
BEGIN
   RETURN QUERY SELECT unnest(string_to_array($1, ','));
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------------------------
-- ADD DATA TO USER ASSIGNED TO DISTRICT TABLE
----------------------------------------------------------------------------

-- Insert data into the UserAssignedToDistrict table
WITH normalized_districts AS (
  SELECT
    employeeID,
    unnest(string_to_array(districts_assigned, ',')) AS district
  FROM temp_user
)
INSERT INTO userassignedtodistrict (employee_id, district_number)
SELECT
  employeeID,
  district
FROM normalized_districts;

DROP TABLE temp_user;

----------------------------------------------------------------------------
-- ADD DATA TO HOLIDAY TABLE
----------------------------------------------------------------------------

--- Add data from Holiday.tsv to the Holiday table.
--- first need to alter the date column to holiday_date because 'date' is a reserved keyword in SQL.
ALTER TABLE Holiday
RENAME COLUMN date TO holiday_date;

--- load data
CREATE TEMP TABLE temp_holiday (
    holiday_date DATE,
    holiday_name TEXT,
    employeeID TEXT
);

COPY temp_holiday FROM '/Users/ravinderbadwal/Downloads/Demo Data/Holiday.tsv' DELIMITER E'\t' CSV HEADER;

INSERT INTO Holiday (holiday_date, holiday_name, created_by)
SELECT holiday_date, holiday_name, employeeID FROM temp_holiday;

DROP TABLE temp_holiday;

----------------------------------------------------------------------------
-- ADD DATA TO REPORT TABLE
----------------------------------------------------------------------------

--- Add data from Report.tsv to the Report table.
COPY report
FROM '/Users/ravinderbadwal/Downloads/Demo Data/Report_Names.tsv'
DELIMITER E'\t'
CSV HEADER;

----------------------------------------------------------------------------
-- ADD DATA TO AUDIT TABLE
----------------------------------------------------------------------------

--- Add data from Audit.tsv to the Audit table.
--- first need to alter the timestamp column to log_time because 'timestamp' is a reserved keyword in SQL.
ALTER TABLE Audit
RENAME COLUMN timestamp TO log_time;

--- The log_id column was not present in the Audit_log.tsv file. Again, I altered the table to autogenerate this value in sequence.
CREATE SEQUENCE IF NOT EXISTS audit_log_id_seq;

ALTER TABLE audit
ALTER COLUMN log_id
SET DEFAULT nextval('audit_log_id_seq'::regclass);

ALTER SEQUENCE audit_log_id_seq
OWNER to ravinderbadwal;

--- Now load data into the Audit table
CREATE TEMP TABLE temp_audit (
    log_time TIMESTAMP,
    employeeID TEXT,
    report_name TEXT
);

COPY temp_audit FROM '/Users/ravinderbadwal/Downloads/Demo Data/Audit_log.tsv' DELIMITER E'\t' CSV HEADER;

-- Insert data into the Audit table with audit_flag. If the employee is assigned to all districts, set the flag to TRUE, otherwise FALSE.
WITH employee_district_counts AS (
  SELECT
    ua.employee_id,
    COUNT(DISTINCT ua.district_number) AS assigned_districts,
    (SELECT COUNT(DISTINCT district_number) FROM district) AS total_districts
  FROM
    userassignedtodistrict ua
  GROUP BY
    ua.employee_id
),
audit_data_with_flag AS (
  SELECT
    ta.log_time,
    ta.employeeID,
    ta.report_name,
    CASE
      WHEN edc.assigned_districts IS NOT NULL AND edc.assigned_districts = edc.total_districts THEN TRUE
      ELSE FALSE
    END AS audit_flag
  FROM
    temp_audit ta
  LEFT JOIN employee_district_counts edc ON ta.employeeID = edc.employee_id
)
INSERT INTO audit (log_time, employee_id, report_name, audit_flag)
SELECT
  log_time,
  employeeID,
  report_name,
  audit_flag
FROM
  audit_data_with_flag;

DROP TABLE temp_audit;

----------------------------------------------------------------------------
-- ADD DATA TO BUSINESS DAY TABLE
----------------------------------------------------------------------------

--- Add data from Date.tsv to the Business Day table.
--- first need to alter the date column to business_date because 'date' is a reserved keyword in SQL.
ALTER TABLE Businessday
RENAME COLUMN date TO business_date;

--- load data
COPY businessday
FROM '/Users/ravinderbadwal/Downloads/Demo Data/Date.tsv'
DELIMITER E'\t' CSV HEADER;