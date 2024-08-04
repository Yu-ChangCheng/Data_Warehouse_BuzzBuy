-- Drop tables
DROP TABLE IF EXISTS Manufacturer CASCADE;
DROP TABLE IF EXISTS City CASCADE;
DROP TABLE IF EXISTS District CASCADE;
DROP TABLE IF EXISTS Store CASCADE;
DROP TABLE IF EXISTS Category CASCADE;
DROP TABLE IF EXISTS Product CASCADE;
DROP TABLE IF EXISTS ProductCategory CASCADE;
DROP TABLE IF EXISTS Discount CASCADE;
DROP TABLE IF EXISTS DiscountAppliesToProduct CASCADE;
DROP TABLE IF EXISTS Sales CASCADE;
DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS UserAssignedToDistrict CASCADE;
DROP TABLE IF EXISTS Holiday CASCADE;
DROP TABLE IF EXISTS Report CASCADE;
DROP TABLE IF EXISTS Audit CASCADE;
DROP TABLE IF EXISTS Businessday CASCADE;

-- Tables 
--updated
CREATE TABLE Manufacturer (
  manufacturer_name VARCHAR(999) NOT NULL,
  PRIMARY KEY (manufacturer_name)
);
--updated
CREATE TABLE City (
  city_id VARCHAR(50) NOT NULL,
  city_name VARCHAR(255) NOT NULL,
  state_loc CHAR(50) NOT NULL,
  population INT NOT NULL,
  PRIMARY KEY (city_id)
);
--updated
CREATE TABLE District (
  district_number INT NOT NULL,
  PRIMARY KEY (district_number)
);
--updated
CREATE TABLE Store (
  store_number VARCHAR(50) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  city_id VARCHAR(50) NOT NULL,
  district_number INT NOT NULL,
  address VARCHAR(999) NOT NULL,
  PRIMARY KEY (store_number),
  FOREIGN KEY (city_id) REFERENCES City(city_id),
  FOREIGN KEY (district_number) REFERENCES District(district_number)
);
--updated
CREATE TABLE Category (
  category_name VARCHAR(999) NOT NULL,
  PRIMARY KEY (category_name)
);
--updated
CREATE TABLE Product (
  pid VARCHAR(50) NOT NULL,
  product_name VARCHAR(999) NOT NULL,
  manufacturer_name VARCHAR(999) NOT NULL,
  price FLOAT NOT NULL,
  categories VARCHAR(999),  
  PRIMARY KEY (pid),
  FOREIGN KEY (manufacturer_name) REFERENCES Manufacturer(manufacturer_name)
);
--updated
CREATE TABLE ProductCategory (
  pid VARCHAR(50) NOT NULL,
  category_name VARCHAR(999) NOT NULL,
  PRIMARY KEY (pid, category_name),
  FOREIGN KEY (pid) REFERENCES Product(pid),
  FOREIGN KEY (category_name) REFERENCES Category(category_name)
);
--updated
CREATE TABLE Discount (
  discount_id VARCHAR(50) NOT NULL,
  discount_date DATE NOT NULL,
  pid VARCHAR(50) NOT NULL,
  discount_price FLOAT NOT NULL,
  PRIMARY KEY (discount_id, discount_date)
);
--updated
CREATE TABLE DiscountAppliesToProduct (
  discount_id VARCHAR(50) NOT NULL,
  pid VARCHAR(50) NOT NULL
);

--updated
CREATE TABLE Sales (
  sales_id VARCHAR(50) NOT NULL,
  pid VARCHAR(50) NOT NULL,
  date_sold DATE NOT NULL,
  store_number VARCHAR(50) NOT NULL,
  quantity INT NOT NULL,
  PRIMARY KEY (sales_id),
  FOREIGN KEY (store_number) REFERENCES Store(store_number),
  FOREIGN KEY (pid) REFERENCES Product(pid)
);

--updated
CREATE TABLE Users (
  employee_id CHAR(7) NOT NULL,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  ssn_last4 CHAR(4) NOT NULL,
  audit_log_access INT,
  districts_assigned TEXT,
  PRIMARY KEY (employee_id)
);
--updated
CREATE TABLE UserAssignedToDistrict (
  district_number VARCHAR(50) NOT NULL,
  employee_id CHAR(7) NOT NULL
);

--updated
CREATE TABLE Holiday (
  holiday_date DATE NOT NULL,
  holiday_name VARCHAR(255) NOT NULL,
  created_by VARCHAR(50) NOT NULL,
  PRIMARY KEY (holiday_date),
  FOREIGN KEY (created_by) REFERENCES Users(employee_id)
);
--updated
CREATE TABLE Report (
  report_name VARCHAR(100) NOT NULL,
  PRIMARY KEY (report_name)
);
--updated
CREATE TABLE Audit (
  log_id VARCHAR(50) NOT NULL,
  log_time TIMESTAMP NOT NULL,
  employee_id VARCHAR(7) NOT NULL,
  report_name VARCHAR(100) NOT NULL,
  PRIMARY KEY (log_id, employee_id),
  FOREIGN KEY (employee_id) REFERENCES Users(employee_id),
  FOREIGN KEY (report_name) REFERENCES Report(report_name)
);
--updated
CREATE TABLE Businessday(
  business_date DATE NOT NULL,
  PRIMARY KEY (business_date)
);

-- Constraints and foreign keys

ALTER TABLE Product
  ADD CONSTRAINT FK_Product_manufacturer_name_Manufacturer_manufacturer_name FOREIGN KEY (manufacturer_name) REFERENCES Manufacturer(manufacturer_name);

ALTER TABLE ProductCategory
  ADD CONSTRAINT FK_ProductCategory_pid_Product_pid FOREIGN KEY (pid) REFERENCES Product(pid),
  ADD CONSTRAINT FK_ProductCategory_category_name_Category_category_name FOREIGN KEY (category_name) REFERENCES Category(category_name);

ALTER TABLE DiscountAppliesToProduct
  ADD CONSTRAINT FK_DiscountAppliesToProduct_discount_id_Discount_discount_id FOREIGN KEY (discount_id) REFERENCES Discount(discount_id),
  ADD CONSTRAINT FK_DiscountAppliesToProduct_pid_Product_pid FOREIGN KEY (pid) REFERENCES Product(pid);

ALTER TABLE Sales
  ADD CONSTRAINT FK_Sales_store_number_Store_store_number FOREIGN KEY (store_number) REFERENCES Store(store_number),
  ADD CONSTRAINT FK_Sales_pid_Product_pid FOREIGN KEY (pid) REFERENCES Product(pid);

ALTER TABLE Holiday
  ADD CONSTRAINT FK_Holiday_created_by_User_employee_id FOREIGN KEY (created_by) REFERENCES Users(employee_id);

ALTER TABLE Audit
  ADD CONSTRAINT FK_Audit_employee_id_User_employee_id FOREIGN KEY (employee_id) REFERENCES Users(employee_id),
  ADD CONSTRAINT FK_Audit_report_name_Report_report_name FOREIGN KEY (report_name) REFERENCES Report(report_name);
---