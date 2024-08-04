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

app.post("/login", async (req, res) => {
  const employee_id = req.body.username;
  const password = req.body.password;

  try {
    const result = await db.query("SELECT first_name, last_name, ssn_last4 FROM Users WHERE employee_id = $1", [
      employee_id,
    ]);
    if (result.rows.length > 0) {
      const user = result.rows[0];
      const storedPassword = user.ssn_last4 + '-' + user.last_name;
      const username = user.first_name + " " + user.last_name;

      if (password === storedPassword) {
        req.session.user = {
          id: employee_id,
          name: username,
        };
        res.redirect("/menu");
      } else {
        res.send("Incorrect Password");
      }
    } else {
      res.send("User not found");
    }
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
    res.render('menu', { user, tableCounts: result.rows });
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
