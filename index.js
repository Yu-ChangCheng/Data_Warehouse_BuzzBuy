import express from "express";
import bodyParser from "body-parser";
import pg from "pg";
import session from "express-session";

const app = express();
const port = 3000;

const db = new pg.Client({
  user: "postgres",
  host: "localhost",
  database: "BuzzBuy Data Warehouse",
  password: "0000",
  port: 5432,
});
db.connect();

app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static("public"));
app.use(session({
  secret: 'your_secret_key',
  resave: false,
  saveUninitialized: true,
}));

app.set('view engine', 'ejs');

app.get("/", (req, res) => {
  res.render("home");
});

var employee_id = ''
var corp_em = ''
var audit_access = ''
var user_districts = []


async function is_corp () {
  const em_query = `
    SELECT 
      COUNT(DISTINCT uad.district_number) as em_dis,
      COUNT(DISTINCT district.district_number) as d_dis
    FROM 
      userassignedtodistrict uad, district
    Where
      employee_id = $1;
  `;

  try {
    const em_result = await db.query(em_query, [employee_id]);
    if (em_result.rows[0].em_dis === em_result.rows[0].d_dis) {
      corp_em = true;
    } else {
      corp_em = false;
    };
  } catch (err) {
    console.error('Error with is_corp: ', err);
  }
};

async function view_audit_log () {
  const audit_query = `
    SELECT 
      audit_log_access
    FROM 
      users
    Where
      employee_id = $1;
  `;

  try {
    const audit_result = await db.query(audit_query, [employee_id]);
    if (audit_result.rows[0].audit_log_access) {
      audit_access = true;
    } else {
      audit_access = false;
    };
  } catch (err) {
  }
};


async function log_new_audit(name_of_report) {
  const insert_query = 'INSERT INTO audit (log_time, employee_id, report_name) VALUES (CURRENT_TIMESTAMP, $1, $2)';
  
  try{
    const result = await db.query(insert_query, [employee_id, name_of_report]);
  } catch (err) {
    console.error('Error inserting audit log', err);
  }

};

app.post("/login", async (req, res) => {
  employee_id = req.body.username;
  const password = req.body.password;

// joined Users table with UserAssignedToDistrict to pull employees district_number 
  try {
    const result = await db.query("SELECT first_name, last_name, ssn_last4, district_number FROM Users u JOIN UserAssignedToDistrict uad ON u.employee_id = uad.employee_id WHERE u.employee_id = $1", [
      employee_id,
    ]);
    if (result.rows.length > 0) {
      const user = result.rows[0];
      const storedPassword = user.ssn_last4 + '-' + user.last_name;
      const username = user.first_name + " " + user.last_name;
      const num_rows = result.rows.length;
      
      // iterate through rows to get complete list of districts assigned to user
      for (let i = 0; i < num_rows; i++) {
        user_districts.push(result.rows[i].district_number);
      };
      //convert user_districts array to list of strings
      const district_list = user_districts.map(district => `'${district}'`).join(', ');

      if (password === storedPassword) {
        req.session.user = {
          id: employee_id,
          name: username,
          district: district_list
        };
        res.redirect("/menu");
      } else {
        res.render('home', { error: "Incorrect Password!" });
      }
    } else {
      res.render('home', { error: "User not found!" });
    }
    is_corp();
    view_audit_log();
  } catch (err) {
    console.log(err);
    res.status(500).send("Server error");
  }
});

app.get("/menu", async (req, res) => {
  if (!req.session.user) {
    return res.redirect('/');
  }

  const user = req.session.user;

  const query = `
    SELECT *
    FROM (
      SELECT 'Store' AS TableName, COUNT(*) AS TableCount FROM Store
      UNION SELECT 'City' AS TableName, COUNT(*) AS TableCount FROM City
      UNION SELECT 'District' AS TableName, COUNT(*) AS TableCount FROM District
      UNION SELECT 'Manufacturer' AS TableName, COUNT(*) AS TableCount FROM Manufacturer
      UNION SELECT 'Product' AS TableName, COUNT(*) AS TableCount FROM Product
      UNION SELECT 'Category' AS TableName, COUNT(*) AS TableCount FROM Category
      UNION SELECT 'Holiday' AS TableName, COUNT(*) AS TableCount FROM Holiday
    ) AS UnionCount;
  `;

  try {
    const result = await db.query(query);
    res.render('menu', { user, tableCounts: result.rows, corp_em, audit_access });
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});

app.get('/holidays', async (req, res) => {
  const user = req.session.user;
  
  const holiday_query = `
    SELECT 
      holiday.holiday_date, holiday.holiday_name, holiday.created_by 
    FROM 
      holiday 
    ORDER BY holiday.holiday_date ASC; 
  `;

  try {
    const result = await db.query(holiday_query);
    res.render('holidays', {corp_em, holidays: result.rows, error: null, success: req.query.success  } );
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});


app.post('/add-holiday', async (req, res) => {
  const { holidayDate, holidayName } = req.body;
  

  // Check if the holiday already exists
  const checkQuery = `SELECT * FROM Holiday WHERE holiday_date = $1`;
  const insertQuery = `INSERT INTO Holiday (holiday_date, holiday_name, created_by) VALUES ($1, $2, $3)`;

  try {
    const checkResult = await db.query(checkQuery, [holidayDate]);
    if (checkResult.rows.length > 0) {
      // Holiday already exists
      const holiday_query = `
        SELECT 
          holiday_date, holiday_name, created_by 
        FROM 
          Holiday 
        ORDER BY holiday_date ASC;
      `;
      const result = await db.query(holiday_query);
      res.render('holidays', { holidays: result.rows, corp_em, error: 'Holiday already exists for this date.' });
    } else {
      // Add the holiday
      await db.query(insertQuery, [holidayDate, holidayName, employee_id]);
      res.redirect('/holidays?success=Holiday successfully added.');
    }
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});

app.get('/manufacturer-report', async (req, res) => {
  log_new_audit('Manufacturer\'s Product Report');

  const mfg_report_query = `
    WITH manufacturer_report AS  
  (SELECT m.manufacturer_name, 
      count(distinct p.pid) as number_of_products, 
      avg(p.price) as avg_price, 
      max(p.price) as max_price, 
      min(price) as min_price 
  FROM Manufacturer m 
      JOIN Product p ON m.manufacturer_name = p.manufacturer_name 
  GROUP BY m.manufacturer_name 
  ORDER BY avg(p.price) DESC 
  LIMIT 100) 
  SELECT manufacturer_name, 
      number_of_products, 
      ROUND(CAST(avg_price AS NUMERIC), 2) AS avg_price, 
      max_price, 
      min_price 
  FROM manufacturer_report;  
  `;

  try {
    const result = await db.query(mfg_report_query);
    res.render('manufacturer-report', {mfg_report: result.rows } );
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});

app.get('/manufacturer-details', async (req, res) => {
  const { manufacturer } = req.query
  const mfg_details_query = `
  SELECT
    pd.pid,
    pd.product_name,
    STRING_AGG(pc.category_name, ', ') AS categories,
    pd.price
FROM (
	SELECT
		  manufacturer_name, 
	      number_of_products, 
	      ROUND(CAST(avg_price AS NUMERIC), 2) AS avg_price, 
	      max_price, 
	      min_price 
	  FROM (
		  SELECT m.manufacturer_name, 
		      count(distinct p.pid) as number_of_products, 
		      avg(p.price) as avg_price, 
		      max(p.price) as max_price, 
		      min(price) as min_price 
		  FROM 
		 	Manufacturer m 
		      JOIN Product p ON m.manufacturer_name = p.manufacturer_name 
		  GROUP BY 
		 	m.manufacturer_name 
		  ORDER BY 
		 	avg(p.price) DESC 
		  LIMIT 100 ) as manufacturer_report ) as mr
	LEFT JOIN product AS pd ON pd.manufacturer_name = mr.manufacturer_name
	LEFT JOIN productcategory AS pc ON pc.pid = pd.pid
WHERE 
	mr.manufacturer_name = $1
GROUP BY
	pd.pid,
	pd.product_name,
	pd.price
ORDER BY
	pd.price DESC;  
  `;

  try {
    const result = await db.query(mfg_details_query, [manufacturer]);
    res.render('manufacturer-details', {
      manufacturer,
      mfg_details: result.rows } );
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});

app.get('/category-report', async (req, res) => {
  log_new_audit('Category Report');

  const cat_report_query = `
  SELECT c.category_name, 
     count(distinct p.pid) as number_of_products, 
     count(distinct p.manufacturer_name) as number_of_manufacturers, 
     ROUND(CAST(avg(price) AS NUMERIC),2) as avg_price 
  FROM Category c 
      JOIN ProductCategory pc ON c.category_name = pc.category_name 
      JOIN Product p ON p.pid = pc.pid 
  GROUP BY c.category_name 
  ORDER BY c.category_name ASC; 
  `;

  try {
    const result = await db.query(cat_report_query);
    res.render('category-report', {cat_report: result.rows } );
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});

app.get('/gps-revenue', async (req, res) => {
  log_new_audit('Actual versus Predicted Revenue for GPS units');
  
  // added district variable
  const district = req.session.user.district
  const gps_rev_query = `
  SELECT pid, 
    product_name, 
    price, 
    sum(quantity) AS total_quantity_sold, 
    sum(discount_quantity) AS total_quantity_sold_discount, 
    sum(retail_quantity) AS total_quantity_sold_retail, 
    ROUND(CAST(sum(actual_revenue) AS NUMERIC),2) AS actual_revenue, 
    ROUND(CAST(sum(predicted_revenue) AS NUMERIC),2) AS predicted_revenue, 
    ROUND(CAST(abs(sum(actual_revenue) - sum(predicted_revenue)) AS NUMERIC),2) as revenue_diff 
  FROM ( 
    SELECT pid, 
        product_name, 
        price, 
        quantity, 
        CASE 
          WHEN discount_price is NULL THEN quantity 
          ELSE 0 
        END AS retail_quantity, 
        CASE 
          WHEN discount_price is NOT NULL THEN quantity 
          ELSE 0 
        END AS discount_quantity, 
        CASE 
          WHEN discount_price is NULL THEN price * quantity 
          ELSE discount_price * quantity 
        END AS actual_revenue, 
        CASE 
          WHEN discount_price is NULL THEN price * quantity 
          ELSE price * (0.75 * quantity) 
        END AS predicted_revenue 
    FROM ( 
      SELECT s.pid, 
          p.product_name, 
          p.price, 
          dap.discount_price, 
          s.quantity 
      FROM Sales s 
          LEFT JOIN ( 
              SELECT * 
              FROM DiscountAppliesToProduct dp 
                  JOIN Discount d ON dp.discount_id = d.discount_id 
          ) dap ON s.date_sold = dap.discount_date 
          AND s.pid = dap.pid 
          JOIN Store st ON s.store_number = st.store_number
          JOIN Product p ON s.pid = p.pid 
          JOIN ProductCategory pc ON s.pid = pc.pid 
      WHERE category_name like '%GPS%'
      AND st.district_number IN (${district})
    ) AS tbl0 
  ) AS tbl1 
  GROUP BY pid, 
    product_name, 
    price 
  HAVING abs(sum(actual_revenue) - sum(predicted_revenue)) > 200 
  ORDER BY revenue_diff DESC;  
    `;
  try {
    const result = await db.query(gps_rev_query);
    res.render('gps-revenue', {gps_rev_report: result.rows } );
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});

app.get('/groundhog-day', async (req, res) => {
  log_new_audit('Air Conditioners on Groundhog Day?');

  // added district variable
  const district = req.session.user.district
  const ghd_report_query = `
  WITH 
  ac_sales AS (
    SELECT 
          EXTRACT(YEAR FROM Sales.date_sold) AS sa_year, 
          SUM(Sales.quantity) AS annual_sales, 
          SUM(Sales.quantity) / 365 AS daily_sales 
    FROM 
          Sales 
          JOIN Store ON Sales.store_number = Store.store_number
          JOIN Product ON Product.pid = Sales.pid 
          JOIN ProductCategory ON ProductCategory.pid = Product.pid 
    WHERE 
          ProductCategory.category_name LIKE '%Air Conditioning%'
          AND Store.district_number IN (${district}) 
    GROUP BY 
          sa_year 
  ), 
  ghd_sales AS (
    SELECT 
          EXTRACT(YEAR FROM Sales.date_sold) AS sa_year, 
          SUM(Sales.quantity) AS sales 
    FROM 
          Sales 
          JOIN Product ON Product.pid = Sales.pid 
          JOIN ProductCategory ON ProductCategory.pid = Product.pid 
    WHERE 
          ProductCategory.category_name LIKE '%Air Conditioning%' 
          AND EXTRACT(MONTH FROM Sales.date_sold) = 2 
          AND EXTRACT(DAY FROM Sales.date_sold) = 2 
    GROUP BY 
          sa_year 
  ) 
SELECT 
    ac_sales.sa_year, 
    ac_sales.annual_sales, 
    ac_sales.daily_sales, 
    COALESCE(ghd_sales.sales, 0) AS groundhog_day_sales 
FROM 
    ac_sales 
    LEFT JOIN ghd_sales ON ac_sales.sa_year = ghd_sales.sa_year 
ORDER BY 
    ac_sales.sa_year ASC 
  `;

  try {
    const result = await db.query(ghd_report_query);
    res.render('groundhog-day', {ghd_report: result.rows } );
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});

app.get('/revenue-population', async (req, res) => {
  log_new_audit('Revenue by Population');

  const rev_pop_report_query = `
SELECT 
	report_year,
	SUM(CASE WHEN city_size ='Small' THEN average_revenue ELSE NULL END) AS small,
	SUM(CASE WHEN city_size ='Medium' THEN average_revenue ELSE NULL END) AS medium,
	SUM(CASE WHEN city_size ='Large' THEN average_revenue ELSE NULL END) AS large,
	SUM(CASE WHEN city_size ='Extra Large' THEN average_revenue ELSE NULL END) AS extra_large
FROM 
	(SELECT 
	r5.report_year,
    CAST( 
        CASE 
            WHEN ct.population < 3700000 THEN 'Small' 
            WHEN ct.population < 6700000 AND ct.population >= 3700000 THEN 'Medium'
            WHEN ct.population < 9000000 AND ct.population >= 6700000 THEN 'Large'
            ELSE 'Extra Large'
        END AS VARCHAR 
    ) AS city_size, 
    ROUND(AVG(r5.total_revenue),2) AS average_revenue 
FROM 
	City AS ct 
	LEFT JOIN
		(SELECT 
			EXTRACT (YEAR FROM sa.date_sold) AS report_year,
			ct.city_id,
			ct.city_name, 
			st.store_number, 
			st.address, 
			SUM(tt.total_price) AS total_revenue
		FROM 
			City AS ct 
		    LEFT JOIN Store AS st ON st.city_id = ct.city_id 
		    LEFT JOIN Sales AS sa ON sa.store_number = st.store_number 
			LEFT JOIN 
				(SELECT DISTINCT
					sa.sales_id,
					sa.pid,
					sa.date_sold,
					sa.quantity,
					MIN(CASE WHEN sa.date_sold = dc.discount_date THEN dc.discount_price ELSE pd.price END) AS true_price,
					ROUND(CAST(sa.quantity * MIN(CASE WHEN sa.date_sold = dc.discount_date THEN dc.discount_price ELSE pd.price END) AS NUMERIC) ,2) AS total_price
				FROM Sales AS sa
					LEFT JOIN Product AS pd ON sa.pid = pd.pid 
					LEFT JOIN DiscountAppliesToProduct AS datp ON pd.pid = datp.pid
					LEFT JOIN Discount AS dc ON datp.discount_id = dc.discount_id
				GROUP BY
					sa.sales_id,
					sa.pid,
					sa.date_sold,
					sa.quantity) AS tt ON sa.sales_id = tt.sales_id
			GROUP BY 
				ct.city_id,
				ct.city_name,
			    st.store_number, 
			    st.address, 
			    report_year
			ORDER BY 
				report_year ASC, 
			    total_revenue DESC
				) AS r5 ON ct.city_id = r5.city_id
	GROUP BY 
		report_year, 
	    city_size 
	ORDER BY 
		report_year ASC,
		city_size ASC
		) AS pivot
GROUP BY report_year
;
  `;

  try {
    const result = await db.query(rev_pop_report_query);
    res.render('revenue-population', {rev_pop_report: result.rows } );
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});

app.get('/store-revenue', async (req, res) => {

  const { state } = req.query;

  // Query to get the list of unique states from the database
  const statesQuery = `SELECT DISTINCT state_loc FROM City ORDER BY state_loc ASC;`;

  try {
    const statesResult = await db.query(statesQuery);
    const states = statesResult.rows.map(row => row.state_loc);

    if (!state) {
      return res.render('store-revenue', { states, rev_year_state_report: [] });
    }

    const rev_year_state_report_query = `
      SELECT 
        EXTRACT(YEAR FROM sa.date_sold) AS report_year,
        ct.city_name, 
        st.store_number, 
        st.address, 
        SUM(tt.total_price) AS total_revenue
      FROM City AS ct 
        LEFT JOIN Store AS st ON st.city_id = ct.city_id 
        LEFT JOIN Sales AS sa ON sa.store_number = st.store_number 
        LEFT JOIN 
          (SELECT DISTINCT
            sa.sales_id,
            sa.pid,
            sa.date_sold,
            sa.quantity,
            MIN(CASE WHEN sa.date_sold = dc.discount_date THEN dc.discount_price ELSE pd.price END) AS true_price,
            ROUND(CAST(sa.quantity * MIN(CASE WHEN sa.date_sold = dc.discount_date THEN dc.discount_price ELSE pd.price END) AS NUMERIC) ,2) AS total_price
          FROM Sales AS sa
            LEFT JOIN Product AS pd ON sa.pid = pd.pid 
            LEFT JOIN DiscountAppliesToProduct AS datp ON pd.pid = datp.pid
            LEFT JOIN Discount AS dc ON datp.discount_id = dc.discount_id
          GROUP BY
            sa.sales_id,
            sa.pid,
            sa.date_sold,
            sa.quantity) AS tt ON sa.sales_id = tt.sales_id
      WHERE 
        ct.state_loc = $1
      GROUP BY 
        ct.city_name,
        st.store_number, 
        st.address, 
        report_year
      ORDER BY 
        report_year ASC, 
        total_revenue DESC
    `;

    const result = await db.query(rev_year_state_report_query, [state]);
    res.render('store-revenue', { states, rev_year_state_report: result.rows, selectedState: state });
    log_new_audit('Store Revenue by Year by State');
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});

app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/');
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

app.get('/district-volume', async (req, res) => {
  const { year, month } = req.query;
  const currentDate = new Date();
  const currentYear = currentDate.getFullYear();
  const currentMonth = currentDate.getMonth() + 1; // getMonth() returns 0-based month

  const selectedYear = year || currentYear;
  const selectedMonth = month || currentMonth;
  
  const district_volume_query = `
    WITH CategorySales AS (
      SELECT
        c.category_name,
        st.district_number,
        SUM(s.quantity) AS total_units_sold
      FROM
        Sales s
        JOIN ProductCategory pc ON s.pid = pc.pid
        JOIN Category c ON pc.category_name = c.category_name
        JOIN Store st ON s.store_number = st.store_number
      WHERE
        EXTRACT(YEAR FROM s.date_sold) = $1
        AND EXTRACT(MONTH FROM s.date_sold) = $2
      GROUP BY
        c.category_name,
        st.district_number
    ),
    MaxDistrictSales AS (
      SELECT
        category_name,
        MAX(total_units_sold) AS max_units_sold
      FROM
        CategorySales
      GROUP BY
        category_name
    )
    SELECT
      cs.category_name,
      cs.district_number,
      cs.total_units_sold
    FROM
      CategorySales cs
      JOIN MaxDistrictSales mds ON cs.category_name = mds.category_name 
        AND cs.total_units_sold = mds.max_units_sold
    ORDER BY
      cs.category_name ASC
  `;

  try {
    const result = await db.query(district_volume_query, [selectedYear, selectedMonth]);
    res.render('district-volume', { district_volume_report: result.rows, selectedYear, selectedMonth });
    log_new_audit('District with Highest Volume for each Category');
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});

app.get('/audit-log', async (req, res) => {

  const audit_log_query = `
    WITH total_dis AS (SELECT COUNT(*) AS total FROM District),
      emp_dis AS (
        SELECT employee_id, COUNT(DISTINCT district_number) AS em_dis 
        FROM userassignedtodistrict
        GROUP BY employee_id),
      dis_access AS (
        SELECT emp_dis.employee_id,
            (emp_dis.em_dis = total_dis.total) AS all_access
        FROM emp_dis CROSS JOIN total_dis)
    SELECT 
      to_char(Audit.log_time AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI:SS TZ') AS log_time, 
      Audit.employee_id, 
      Audit.report_name, 
      Users.last_name || ', ' || Users.first_name AS user_name,
      dis_access.all_access
    FROM 
      Audit 
      LEFT JOIN Users ON Audit.employee_id = Users.employee_id
      JOIN dis_access ON Audit.employee_id = dis_access.employee_id
    ORDER BY log_time DESC, employee_id ASC
    LIMIT 100; 
  `;

  try {
    const result = await db.query(audit_log_query);
    res.render('audit-log', { audit_log_report: result.rows });
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});

app.get('/district-details', async (req, res) => {
  const { year, month, district, category } = req.query;

  const details_query = `
    SELECT
      st.district_number,
      st.store_number,
      st.address,
      ct.state_loc,
      ct.city_name
    FROM
      Store st
      JOIN City ct ON st.city_id = ct.city_id
    WHERE
      st.district_number = $1
    ORDER BY
          CAST(st.store_number AS INTEGER) ASC;
  `;

  try {
    const result = await db.query(details_query, [district]);
    res.render('district-details', {
      selectedYear: year,
      selectedMonth: month,
      district,
      category,
      details: result.rows
    });
  } catch (err) {
    console.error(err);
    res.send("Error " + err);
  }
});
