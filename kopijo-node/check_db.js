const mysql = require("mysql2");

const db = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "kasir_kopijo",
});

db.connect((err) => {
    if (err) {
        console.error("Database connection failed:", err.message);
        process.exit(1);
    }
    console.log("Database connected successfully.");
    
    // Check tables
    db.query("SHOW TABLES", (err, results) => {
        if (err) {
            console.error("Failed to show tables:", err.message);
            db.end();
            process.exit(1);
        }
        console.log("Tables in database:", results.map(r => Object.values(r)[0]));
        
        // Describe transactions
        db.query("DESCRIBE transactions", (err, cols) => {
            if (err) {
                console.error("Failed to describe transactions:", err.message);
            } else {
                console.log("\nStructure of transactions table:");
                cols.forEach(c => console.log(`  - ${c.Field}: ${c.Type} (Null: ${c.Null}, Key: ${c.Key})`));
            }
            
            // Describe transaction_items
            db.query("DESCRIBE transaction_items", (err, cols) => {
                if (err) {
                    console.error("Failed to describe transaction_items:", err.message);
                } else {
                    console.log("\nStructure of transaction_items table:");
                    cols.forEach(c => console.log(`  - ${c.Field}: ${c.Type} (Null: ${c.Null}, Key: ${c.Key})`));
                }
                db.end();
            });
        });
    });
});
