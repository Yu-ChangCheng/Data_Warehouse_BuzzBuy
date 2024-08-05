# Data_Warehouse_BuzzBuy

Relational Database Design built with NodeJS, ExpressJS, HTML/ CSS, Bootstrap, PostgreSQL implementation

**Screenshots of the application**:
    - Login page (/Image/Login.png)
    - Main menu (/Image/Main_Menu.png)
    - State revenue Report (/Image/State_Revenue.png)
    
## Spec: BuzzBuy Data Warehouse-1.0.1.pdf
[View Spec Document](BuzzBuy%20Data%20Warehouse-1.0.1.pdf)

## EER Diagram
[View EER Diagram](/Docs/team025_p2_updatedEER.pdf)

## Design + SQL Doc
[View Design + SQL Document](/Docs/team025_p2_ac+SQL.pdf)

## Demo Video
[Watch Demo Video](https://youtu.be/JYbA1fEwFUc)

## Step 1: Clone the project
Download or git clone the project

## Step 2: Install dependencies
```
npm install
```

## Step 3: Unzip Demo Data.zip
```
unzip Data/Demo\ Data.zip -d Data
```

## Step 4: Import data into PostgreSQL
Ensure PostgreSQL and PG Admin are installed and running
Create a new database named "BuzzBuy Data Warehouse"
Use PG Admin to run add_data.sql(remember to change path name and unzip the data files in Demo Data.zip)

## Step 5: Update index.js with PostgreSQL credentials
```
const db = new pg.Client({
  user: "postgres",
  host: "localhost",
  database: "BuzzBuy Data Warehouse",
  password: "0000",
  port: 5432,
});
```

## Step 6: Run the application
```
nodemon index.js
```
