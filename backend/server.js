const express = require('express');
const oracledb = require('oracledb');
const cors = require('cors');
require('dotenv').config(); // Load environment variables

const app = express();
const PORT = process.env.PORT || 5000;

// Set oracledb to promise mode
oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
oracledb.autoCommit = true; // For simplicity in lab, auto-commit changes

app.use(cors());
app.use(express.json());

// Database connection pool configuration for Oracle
const dbConfig = {
    user: process.env.DB_USER || 'lab_user',
    password: process.env.DB_PASSWORD || 'lab_password',
    connectString: process.env.DB_CONNECT_STRING || 'db:1521/FREEPDB1' // 'db' is the service name in docker-compose
};

async function initializeDatabase() {
    try {
        await oracledb.createPool(dbConfig);
        console.log('Oracle Connection pool created!');
    } catch (err) {
        console.error('Oracle database connection pool error:', err.message);
        process.exit(1); // Exit if connection cannot be established
    }
}

// Initialize the database pool when the server starts
initializeDatabase();

app.get('/api/products', async (req, res) => {
    const search = req.query.search || '';

    let connection;
    try {
        connection = await oracledb.getConnection();

        // --- VULNERABLE ORACLE SQL QUERY ---
        // This is the core vulnerability. User input is directly concatenated.
        // It uses a conditional error-based technique common in Oracle SQLi.
        // If the inner condition is TRUE, 'XYZ' is returned. TO_NUMBER('XYZ') causes ORA-01722 (invalid number).
        // If the inner condition is FALSE, '1' is returned. TO_NUMBER('1') is successful.
        // Example exploit: search=Laptop' AND 1=TO_NUMBER((SELECT CASE WHEN (SELECT LENGTH('abc')=3 FROM DUAL) THEN 'XYZ' ELSE '1' END FROM DUAL))--
        // Note: The `id = <value>` part is just to make it functional for products when no error occurs.
        const query = search
            ? `SELECT ID, NAME FROM PRODUCTS WHERE ID = TO_NUMBER((SELECT CASE WHEN NAME LIKE '%${search}%' THEN '1' ELSE 'XYZ' END FROM DUAL))`
            : `SELECT ID, NAME FROM PRODUCTS ORDER BY ID`;

        console.log(`Executing Oracle query: ${query}`); // Log the actual Oracle query

        const result = await connection.execute(query);
        res.json({
            success: true,
            data: result.rows.map(row => ({ id: row.ID, name: row.NAME })), // Map to match frontend structure
            total: result.rows.length
        });
    } catch (err) {
        console.error('Oracle query error:', err.message);
        // Specifically check for ORA-01722: invalid number for error-based SQLi
        if (err.message.includes('ORA-01722')) {
            res.status(500).json({
                success: false,
                message: 'Database error occurred (Possible SQL Injection - Invalid Number)'
            });
        } else {
            res.status(500).json({
                success: false,
                message: 'Database error occurred'
            });
        }
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error('Error closing connection:', err);
            }
        }
    }
});

app.get('/api/products/:id', async (req, res) => {
    const productId = parseInt(req.params.id);
    let connection;
    try {
        connection = await oracledb.getConnection();
        // Secure query: Uses bind variables (prepared statements) for safety
        const query = 'SELECT ID, NAME, CATEGORY, PRICE, DESCRIPTION FROM PRODUCTS WHERE ID = :id';
        const result = await connection.execute(query, { id: productId });

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (err) {
        console.error('Secure product detail query error:', err.message);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error('Error closing connection:', err);
            }
        }
    }
});

app.get('/api/health', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection();
        await connection.execute('SELECT 1 FROM DUAL');
        res.json({
            success: true,
            message: 'Server and Database connected'
        });
    } catch (err) {
        console.error('Health check database error:', err.message);
        res.status(503).json({
            success: false,
            message: 'Database connection failed'
        });
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error('Error closing connection:', err);
            }
        }
    }
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

process.on('SIGTERM', async () => {
    console.log('Closing Oracle connection pool...');
    await oracledb.getPool().close(10); // Close pool gracefully with 10s timeout
    process.exit(0);
});

process.on('SIGINT', async () => {
    console.log('Closing Oracle connection pool...');
    await oracledb.getPool().close(10); // Close pool gracefully with 10s timeout
    process.exit(0);
});