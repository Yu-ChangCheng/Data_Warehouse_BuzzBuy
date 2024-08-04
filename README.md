# Data_Warehouse_BuzzBuy

Basic Relational Database Design built with NodeJS, ExpressJS, HTML/ CSS, Bootstrap, PostgreSQL implementation

## Spec: BuzzBuy Data Warehouse-1.0.1.pdf
[View Spec Document](BuzzBuy%20Data%20Warehouse-1.0.1.pdf)

### Or view the embedded document below:

<iframe src="BuzzBuy%20Data%20Warehouse-1.0.1.pdf" width="100%" height="600px"></iframe>

## Demo Video
[Watch Demo Video](https://youtu.be/JYbA1fEwFUc)

# Step 1: Clone the project
Download or git clone the project

# Step 2: Install dependencies
npm install

# Step 3: Unzip Demo Data.zip
unzip Data/Demo\ Data.zip -d Data

# Step 4: Import data into PostgreSQL
Ensure PostgreSQL and PG Admin are installed and running
Create a new database named "BuzzBuy Data Warehouse"
Use PG Admin to run add_data.sql(remember to change path name and unzip the data files in Demo Data.zip)

# Step 5: Update index.js with PostgreSQL credentials
const db = new pg.Client({
  user: "postgres",
  host: "localhost",
  database: "BuzzBuy Data Warehouse",
  password: "0000",
  port: 5432,
});


# Step 6: Run the application
nodemon index.js
