const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");
const bodyParser = require("body-parser");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}

// Multer storage configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});
const upload = multer({ storage: storage });

// Serve uploads folder statically
app.use("/uploads", express.static(uploadsDir));

const db = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "kasir_kopijo",
});

db.connect((err) => {
    if (err) {
        console.error("Database Tidak Terhubung!", err);
        return;
    }
    console.log("Terhubung ke MySQL!");
});

// ==========================================
// 1. CATEGORIES ROUTER
// ==========================================

// Get All Categories
app.get("/categories", (req, res) => {
  db.query("SELECT * FROM categories", (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// Get Category By Id
app.get("/categories/:id", (req, res) => {
  const { id } = req.params;
  db.query("SELECT * FROM categories WHERE id = ?", [id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results[0] || {});
  });
});

// Post Category (Tambah Data)
app.post("/categories", (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ message: "Nama kategori harus diisi!" });
  db.query("INSERT INTO categories (name) VALUES (?)", [name], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Data masuk!", id: result.insertId });
  });
});

// Put Category (Update Data)
app.put("/categories/:id", (req, res) => {
  const { id } = req.params;
  const { name } = req.body;
  if (!name) return res.status(400).json({ message: "Nama kategori harus diisi!" });
  db.query("UPDATE categories SET name = ? WHERE id = ?", [name, id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Data diupdate!" });
  });
});

// Delete Category
app.delete("/categories/:id", (req, res) => {
  const { id } = req.params;
  db.query("DELETE FROM categories WHERE id = ?", [id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Data dihapus!" });
  });
});


// ==========================================
// 2. MODIFIERS ROUTER
// ==========================================

// Get All Modifiers (can filter by ?category_id=)
app.get("/modifiers", (req, res) => {
  const { category_id } = req.query;
  let sql = "SELECT * FROM modifiers";
  const params = [];

  if (category_id) {
    sql += " WHERE category_id = ?";
    params.push(category_id);
  }

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// Get Modifier By Id
app.get("/modifiers/:id", (req, res) => {
  const { id } = req.params;
  db.query("SELECT * FROM modifiers WHERE id = ?", [id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results[0] || {});
  });
});

// Post Modifier (Tambah Data)
app.post("/modifiers", (req, res) => {
  const { category_id, modifier_group, name, price_adjustment } = req.body;
  if (!category_id || !modifier_group || !name) {
    return res.status(400).json({ message: "Kategori, grup modifier, dan nama harus diisi!" });
  }
  const sql = `
    INSERT INTO modifiers (category_id, modifier_group, name, price_adjustment)
    VALUES (?, ?, ?, ?)
  `;
  db.query(sql, [category_id, modifier_group, name, price_adjustment || 0], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Data masuk!", id: result.insertId });
  });
});

// Put Modifier (Update Data)
app.put("/modifiers/:id", (req, res) => {
  const { id } = req.params;
  const { category_id, modifier_group, name, price_adjustment } = req.body;
  const sql = `
    UPDATE modifiers
    SET category_id = ?, modifier_group = ?, name = ?, price_adjustment = ?
    WHERE id = ?
  `;
  db.query(sql, [category_id, modifier_group, name, price_adjustment, id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Data diupdate!" });
  });
});

// Delete Modifier
app.delete("/modifiers/:id", (req, res) => {
  const { id } = req.params;
  db.query("DELETE FROM modifiers WHERE id = ?", [id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Data dihapus!" });
  });
});


// ==========================================
// 3. PRODUCTS ROUTER
// ==========================================

// Get All Products
app.get("/products", (req, res) => {
  const sql = `
    SELECT p.*, c.name AS category_name
    FROM products p
    JOIN categories c ON p.category_id = c.id
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// Get Product By Id
app.get("/products/:id", (req, res) => {
  const { id } = req.params;
  db.query("SELECT * FROM products WHERE id = ?", [id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results[0] || {});
  });
});

// Post Product (Tambah Data)
app.post("/products", (req, res) => {
  const { category_id, name, description, image, type, base_price, is_active } = req.body;
  if (!category_id || !name || !type || base_price === undefined) {
    return res.status(400).json({ message: "Kategori, nama, tipe, dan harga dasar harus diisi!" });
  }
  const sql = `
    INSERT INTO products (category_id, name, description, image, type, base_price, is_active)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `;
  db.query(
    sql,
    [category_id, name, description, image, type, base_price, is_active ?? true],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: "Data masuk!", id: result.insertId });
    }
  );
});

// Put Product (Update Data)
app.put("/products/:id", (req, res) => {
  const { id } = req.params;
  const { category_id, name, description, image, type, base_price, is_active } = req.body;
  const sql = `
    UPDATE products
    SET category_id = ?, name = ?, description = ?, image = ?, type = ?, base_price = ?, is_active = ?
    WHERE id = ?
  `;
  db.query(
    sql,
    [category_id, name, description, image, type, base_price, is_active, id],
    (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: "Data diupdate!" });
    }
  );
});

// Delete Product
app.delete("/products/:id", (req, res) => {
  const { id } = req.params;
  db.query("DELETE FROM products WHERE id = ?", [id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Data dihapus!" });
  });
});


// ==========================================
// 4. PRODUCT VARIANTS ROUTER
// ==========================================

// Get All Variants (can filter by ?product_id=)
app.get("/variants", (req, res) => {
  const { product_id } = req.query;
  let sql = "SELECT * FROM product_variants";
  const params = [];

  if (product_id) {
    sql += " WHERE product_id = ?";
    params.push(product_id);
  }

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// Get Variant By Id
app.get("/variants/:id", (req, res) => {
  const { id } = req.params;
  db.query("SELECT * FROM product_variants WHERE id = ?", [id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results[0] || {});
  });
});

// Post Variant (Tambah Data)
app.post("/variants", (req, res) => {
  const { product_id, name, price, stock, unit } = req.body;
  if (!product_id || !name || price === undefined) {
    return res.status(400).json({ message: "Product ID, nama varian, dan harga harus diisi!" });
  }
  const sql = "INSERT INTO product_variants (product_id, name, price, stock, unit) VALUES (?, ?, ?, ?, ?)";
  db.query(sql, [product_id, name, price, stock || 0, unit || "pcs"], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Data masuk!", id: result.insertId });
  });
});

// Put Variant (Update Data)
app.put("/variants/:id", (req, res) => {
  const { id } = req.params;
  const { product_id, name, price, stock, unit } = req.body;
  const sql = `
    UPDATE product_variants
    SET product_id = ?, name = ?, price = ?, stock = ?, unit = ?
    WHERE id = ?
  `;
  db.query(sql, [product_id, name, price, stock, unit, id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Data diupdate!" });
  });
});

// Delete Variant
app.delete("/variants/:id", (req, res) => {
  const { id } = req.params;
  db.query("DELETE FROM product_variants WHERE id = ?", [id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Data dihapus!" });
  });
});


// ==========================================
// 5. TRANSACTION ITEMS & MODIFIERS ROUTER
// ==========================================

// Get All Transaction Item Modifiers
app.get("/transaction-item-modifiers", (req, res) => {
  const { transaction_item_id } = req.query;
  let sql = "SELECT * FROM transaction_item_modifiers";
  const params = [];

  if (transaction_item_id) {
    sql += " WHERE transaction_item_id = ?";
    params.push(transaction_item_id);
  }

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// Post Transaction Item Modifier
app.post("/transaction-item-modifiers", (req, res) => {
  const { transaction_item_id, modifier_id, price_adjustment } = req.body;
  const sql = `
    INSERT INTO transaction_item_modifiers (transaction_item_id, modifier_id, price_adjustment)
    VALUES (?, ?, ?)
  `;
  db.query(sql, [transaction_item_id, modifier_id, price_adjustment || 0], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Data masuk!", id: result.insertId });
  });
});

// Get All Transaction Items
app.get("/transaction-items", (req, res) => {
  const { transaction_id } = req.query;
  let sql = "SELECT * FROM transaction_items";
  const params = [];

  if (transaction_id) {
    sql += " WHERE transaction_id = ?";
    params.push(transaction_id);
  }

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// Post Transaction Item
app.post("/transaction-items", (req, res) => {
  const { transaction_id, product_id, variant_id, quantity, unit_price, subtotal } = req.body;
  const sql = `
    INSERT INTO transaction_items (transaction_id, product_id, variant_id, quantity, unit_price, subtotal)
    VALUES (?, ?, ?, ?, ?, ?)
  `;
  db.query(
    sql,
    [transaction_id, product_id, variant_id || null, quantity, unit_price, subtotal],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: "Item tersimpan!", id: result.insertId });
    }
  );
});


// ==========================================
// 6. TRANSACTIONS ROUTER
// ==========================================

// Get All Transactions
app.get("/transactions", (req, res) => {
  db.query("SELECT * FROM transactions ORDER BY created_at DESC", (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// Get Transaction By Id (complete with items & nested modifiers)
app.get("/transactions/:id", (req, res) => {
  const { id } = req.params;
  db.query("SELECT * FROM transactions WHERE id = ?", [id], (err, transResult) => {
    if (err) return res.status(500).json({ error: err.message });
    if (transResult.length === 0) return res.json({});

    const sqlItems = `
      SELECT ti.*, p.name AS product_name, pv.name AS variant_name
      FROM transaction_items ti
      JOIN products p ON ti.product_id = p.id
      LEFT JOIN product_variants pv ON ti.variant_id = pv.id
      WHERE ti.transaction_id = ?
    `;
    db.query(sqlItems, [id], async (err, items) => {
      if (err) return res.status(500).json({ error: err.message });

      // Gather modifiers for each item
      const itemsWithModifiers = [];
      for (const item of items) {
        const sqlMods = `
          SELECT tim.*, m.name AS modifier_name, m.modifier_group
          FROM transaction_item_modifiers tim
          JOIN modifiers m ON tim.modifier_id = m.id
          WHERE tim.transaction_item_id = ?
        `;
        const promiseDb = db.promise();
        try {
          const [mods] = await promiseDb.query(sqlMods, [item.id]);
          itemsWithModifiers.push({ ...item, modifiers: mods });
        } catch (e) {
          return res.status(500).json({ error: e.message });
        }
      }

      res.json({ ...transResult[0], items: itemsWithModifiers });
    });
  });
});

// Checkout (Create Transaction + Items + Modifiers & Decrement Stock in transaction)
app.post("/transactions/checkout", async (req, res) => {
  const { user_id, payment_method, discount, tax, amount_paid, items } = req.body;
  const promiseDb = db.promise();

  if (!items || items.length === 0) {
    return res.status(400).json({ message: "Items tidak boleh kosong!" });
  }

  // Calculate subtotal from all items
  let subtotal = 0;
  const itemsWithSubtotal = items.map((item) => {
    const modifierTotal = (item.modifiers || []).reduce(
      (sum, m) => sum + Number(m.price_adjustment || 0), 0
    );
    const itemSubtotal = (Number(item.unit_price) + modifierTotal) * Number(item.quantity);
    subtotal += itemSubtotal;
    return { ...item, itemSubtotal };
  });

  const total = subtotal - (Number(discount) || 0) + (Number(tax) || 0);
  const changeAmount = Number(amount_paid) - total;
  const transactionCode = "TRX" + Date.now();

  try {
    await promiseDb.beginTransaction();

    // 1. Validate & Decrement stock for variants
    for (const item of items) {
      if (item.variant_id) {
        const [variants] = await promiseDb.query(
          "SELECT stock, name FROM product_variants WHERE id = ?",
          [item.variant_id]
        );
        if (variants.length > 0) {
          const currentStock = Number(variants[0].stock);
          const reqQty = Number(item.quantity);
          if (currentStock < reqQty) {
            throw new Error(`Stok tidak cukup untuk varian: ${variants[0].name}. Tersedia: ${currentStock}, Dibutuhkan: ${reqQty}`);
          }
          // Decrement stock
          await promiseDb.query(
            "UPDATE product_variants SET stock = stock - ? WHERE id = ?",
            [reqQty, item.variant_id]
          );
        }
      }
    }

    // 2. Insert into transactions
    const [transResult] = await promiseDb.query(
      `INSERT INTO transactions
       (user_id, transaction_code, subtotal, discount, tax, total, payment_method, amount_paid, change_amount, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'paid')`,
      [user_id || null, transactionCode, subtotal, discount || 0, tax || 0, total, payment_method, amount_paid, changeAmount]
    );
    const transactionId = transResult.insertId;

    // 3. Insert each item + its modifiers
    for (const item of itemsWithSubtotal) {
      const [itemResult] = await promiseDb.query(
        `INSERT INTO transaction_items
         (transaction_id, product_id, variant_id, quantity, unit_price, subtotal)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [transactionId, item.product_id, item.variant_id || null, item.quantity, item.unit_price, item.itemSubtotal]
      );
      const transactionItemId = itemResult.insertId;

      for (const mod of item.modifiers || []) {
        await promiseDb.query(
          `INSERT INTO transaction_item_modifiers (transaction_item_id, modifier_id, price_adjustment)
           VALUES (?, ?, ?)`,
          [transactionItemId, mod.modifier_id, mod.price_adjustment || 0]
        );
      }
    }

    await promiseDb.commit();
    res.json({
      message: "Checkout berhasil!",
      transaction_id: transactionId,
      transaction_code: transactionCode,
      subtotal, total, change_amount: changeAmount,
    });
  } catch (err) {
    await promiseDb.rollback();
    res.status(500).json({ message: "Checkout gagal!", error: err.message });
  }
});

// Put Transaction (Update Status, e.g. cancel & restore stock)
app.put("/transactions/:id", async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  const promiseDb = db.promise();

  try {
    await promiseDb.beginTransaction();

    // If changing to canceled, restore stock
    if (status === "canceled") {
      // Get all items in transaction
      const [items] = await promiseDb.query(
        "SELECT variant_id, quantity FROM transaction_items WHERE transaction_id = ?",
        [id]
      );
      for (const item of items) {
        if (item.variant_id) {
          await promiseDb.query(
            "UPDATE product_variants SET stock = stock + ? WHERE id = ?",
            [Number(item.quantity), item.variant_id]
          );
        }
      }
    }

    await promiseDb.query("UPDATE transactions SET status = ? WHERE id = ?", [status, id]);
    await promiseDb.commit();
    res.json({ message: "Status transaksi diupdate!" });
  } catch (err) {
    await promiseDb.rollback();
    res.status(500).json({ error: err.message });
  }
});

// Delete Transaction
app.delete("/transactions/:id", (req, res) => {
  const { id } = req.params;
  db.query("DELETE FROM transactions WHERE id = ?", [id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Transaksi dihapus!" });
  });
});


// ==========================================
// 7. REPORTS ROUTER (CUSTOM)
// ==========================================

// GET /reports/sales (daily & monthly sales)
app.get("/reports/sales", async (req, res) => {
  const promiseDb = db.promise();
  try {
    // Daily sales for the last 30 days
    const [dailySales] = await promiseDb.query(`
      SELECT DATE(created_at) as date, SUM(total) as revenue, COUNT(id) as transaction_count
      FROM transactions
      WHERE status = 'paid'
      GROUP BY DATE(created_at)
      ORDER BY date DESC
      LIMIT 30
    `);

    // Monthly sales for the last 12 months
    const [monthlySales] = await promiseDb.query(`
      SELECT DATE_FORMAT(created_at, '%Y-%m') as month, SUM(total) as revenue, COUNT(id) as transaction_count
      FROM transactions
      WHERE status = 'paid'
      GROUP BY DATE_FORMAT(created_at, '%Y-%m')
      ORDER BY month DESC
      LIMIT 12
    `);

    // Payment methods distribution
    const [paymentDistribution] = await promiseDb.query(`
      SELECT payment_method, SUM(total) as revenue, COUNT(id) as count
      FROM transactions
      WHERE status = 'paid'
      GROUP BY payment_method
    `);

    res.json({
      daily: dailySales,
      monthly: monthlySales,
      payments: paymentDistribution,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /reports/popular (best seller products)
app.get("/reports/popular", (req, res) => {
  const sql = `
    SELECT p.id as product_id, p.name, p.type, SUM(ti.quantity) as quantity_sold, SUM(ti.subtotal) as total_revenue
    FROM transaction_items ti
    JOIN products p ON ti.product_id = p.id
    JOIN transactions t ON ti.transaction_id = t.id
    WHERE t.status = 'paid'
    GROUP BY p.id
    ORDER BY quantity_sold DESC
    LIMIT 10
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// POST /upload (Upload product photo)
app.post("/upload", upload.single("image"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: "Tidak ada file yang diunggah!" });
  }
  // Return the path prefix URL
  const fileUrl = `/uploads/${req.file.filename}`;
  res.json({ message: "Upload berhasil!", url: fileUrl });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server berjalan di port ${PORT}`);
});

module.exports = app;
