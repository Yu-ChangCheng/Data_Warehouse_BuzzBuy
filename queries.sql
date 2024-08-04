CREATE TABLE Users (
  employee_id CHAR(7) NOT NULL,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  ssn_last4 CHAR(4) NOT NULL,
  PRIMARY KEY (employee_id)
);
INSERT INTO Users (employee_id, first_name, last_name , ssn_last4) VALUES
('0000000', 'John', 'Lee', '1234');
