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
DROP TABLE IF EXISTS `User` CASCADE;
DROP TABLE IF EXISTS UserAssignedToDistrict CASCADE;
DROP TABLE IF EXISTS Holiday CASCADE;
DROP TABLE IF EXISTS Report CASCADE;
DROP TABLE IF EXISTS Audit CASCADE;

-- Tables 

CREATE TABLE Manufacturer (
  manufacturer_name VARCHAR(255) NOT NULL,
  PRIMARY KEY (manufacturer_name)
);

CREATE TABLE City (
  city_id VARCHAR(50) NOT NULL,
  city_name VARCHAR(255) NOT NULL,
  state CHAR(2) NOT NULL,
  population INT NOT NULL,
  PRIMARY KEY (city_id)
);

CREATE TABLE District (
  district_number VARCHAR(50) NOT NULL,
  PRIMARY KEY (district_number)
);

CREATE TABLE Store (
  store_number VARCHAR(50) NOT NULL,
  address VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  city_id VARCHAR(50) NOT NULL,
  district_number VARCHAR(50) NOT NULL,
  PRIMARY KEY (store_number),
  FOREIGN KEY (city_id) REFERENCES City(city_id),
  FOREIGN KEY (district_number) REFERENCES District(district_number)
);

CREATE TABLE Category (
  category_name VARCHAR(255) NOT NULL,
  PRIMARY KEY (category_name)
);

CREATE TABLE Product (
  pid VARCHAR(50) NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  price FLOAT NOT NULL,
  manufacturer_name VARCHAR(255) NOT NULL,
  PRIMARY KEY (pid),
  FOREIGN KEY (manufacturer_name) REFERENCES Manufacturer(manufacturer_name)
);

CREATE TABLE ProductCategory (
  pid VARCHAR(50) NOT NULL,
  category_name VARCHAR(255) NOT NULL,
  PRIMARY KEY (pid, category_name),
  FOREIGN KEY (pid) REFERENCES Product(pid),
  FOREIGN KEY (category_name) REFERENCES Category(category_name)
);

CREATE TABLE Discount (
  discount_id VARCHAR(50) NOT NULL,
  discount_price FLOAT NOT NULL,
  discount_date DATE NOT NULL,
  PRIMARY KEY (discount_id)
);

CREATE TABLE DiscountAppliesToProduct (
  discount_id VARCHAR(50) NOT NULL,
  pid VARCHAR(50) NOT NULL,
  PRIMARY KEY (discount_id, pid),
  FOREIGN KEY (discount_id) REFERENCES Discount(discount_id),
  FOREIGN KEY (pid) REFERENCES Product(pid)
);

CREATE TABLE Sales (
  sales_id VARCHAR(50) NOT NULL,
  store_number VARCHAR(50) NOT NULL,
  pid VARCHAR(50) NOT NULL,
  date DATE NOT NULL,
  quantity INT NOT NULL,
  total FLOAT NOT NULL,
  PRIMARY KEY (sales_id),
  FOREIGN KEY (store_number) REFERENCES Store(store_number),
  FOREIGN KEY (pid) REFERENCES Product(pid)
);

CREATE TABLE `User` (
  employee_id CHAR(7) NOT NULL,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  ssn_last4 CHAR(4) NOT NULL,
  PRIMARY KEY (employee_id)
);

CREATE TABLE UserAssignedToDistrict (
  district_number VARCHAR(50) NOT NULL,
  employee_id CHAR(7) NOT NULL,
  PRIMARY KEY (district_number, employee_id),
  FOREIGN KEY (district_number) REFERENCES District(district_number),
  FOREIGN KEY (employee_id) REFERENCES `User`(employee_id)
);

CREATE TABLE Holiday (
  date DATE NOT NULL,
  holiday_name VARCHAR(255) NOT NULL,
  created_by VARCHAR(50) NOT NULL,
  PRIMARY KEY (date),
  FOREIGN KEY (created_by) REFERENCES `User`(employee_id)
);

CREATE TABLE Report (
  report_name VARCHAR(100) NOT NULL,
  PRIMARY KEY (report_name)
);

CREATE TABLE Audit (
  log_id VARCHAR(50) NOT NULL,
  timestamp TIMESTAMP NOT NULL,
  audit_flag BOOLEAN NOT NULL,
  employee_id VARCHAR(7) NOT NULL,
  report_name VARCHAR(100) NOT NULL,
  PRIMARY KEY (log_id, employee_id),
  FOREIGN KEY (employee_id) REFERENCES `User`(employee_id),
  FOREIGN KEY (report_name) REFERENCES Report(report_name)
);

CREATE TABLE Businessday(
  date DATE NOT NULL,
  PRIMARY KEY (date)
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
  ADD CONSTRAINT FK_Holiday_created_by_User_employee_id FOREIGN KEY (created_by) REFERENCES `User`(employee_id);

ALTER TABLE Audit
  ADD CONSTRAINT FK_Audit_employee_id_User_employee_id FOREIGN KEY (employee_id) REFERENCES `User`(employee_id),
  ADD CONSTRAINT FK_Audit_report_name_Report_report_name FOREIGN KEY (report_name) REFERENCES Report(report_name);
---