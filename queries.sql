--Create database
CREATE DATABASE DWH;

--Create dimension table: DimCustomer, DimAccount, DimBranch
CREATE TABLE DimCustomer (
    customer_id INT PRIMARY KEY CONSTRAINT PK_DimCustomer NOT NULL,
    customer_name VARCHAR(50),
    address VARCHAR(MAX),
    city_name VARCHAR(100),
    state_name VARCHAR(100),
    age VARCHAR(3),
    gender VARCHAR(10),
    email VARCHAR(50)
);

CREATE TABLE DimAccount (
    account_id INT PRIMARY KEY CONSTRAINT PK_DimAccount NOT NULL,
    customer_id INT CONSTRAINT FK_DimAccount_Customer REFERENCES DimCustomer(customer_id),
    account_type VARCHAR(10),
    balance INT,
    date_opened DATETIME2(0),
    status VARCHAR(10)
);

CREATE TABLE DimBranch (
    branch_id INT PRIMARY KEY CONSTRAINT PK_Branch NOT NULL,
    branch_name VARCHAR(100),
    branch_location VARCHAR(255)
);
--Create fact table
CREATE TABLE FactTransaction (
    transaction_id INT PRIMARY KEY CONSTRAINT PK_FactTransaction NOT NULL,
    account_id INT CONSTRAINT FK_FactTransaction_Account REFERENCES DimAccount(account_id),
    transaction_date DATETIME2(0),
    amount INT,
    transaction_type VARCHAR(50),
    branch_id INT CONSTRAINT FK_FactTransaction_Branch REFERENCES DimBranch(branch_id)
);

-- Store Procedure: Daily Transaction
CREATE PROCEDURE DailyTransaction
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    SELECT 
        CAST(transaction_date AS DATE) AS [Date], 
        COUNT(*) AS TotalTransactions, 
        SUM(amount) AS TotalAmount
    FROM FactTransaction
    WHERE transaction_date BETWEEN @start_date AND @end_date
    GROUP BY CAST(transaction_date AS DATE)
    ORDER BY [Date];
END;

-- Query untuk memanggil procedure
EXEC DailyTransaction @start_date = '2024-01-17', @end_date = '2024-01-20';


-- Store Procedure: BalancePerCustomer
CREATE PROCEDURE BalancePerCustomer
    @name VARCHAR(100)
AS
BEGIN
    SELECT 
        c.customer_name,
        a.account_type,
        a.balance,
        (a.balance + 
            SUM(
                CASE 
                    WHEN t.transaction_type = 'Deposit' THEN t.amount
                    ELSE -t.amount
                END
            )
        ) AS CurrentBalance
    FROM DimAccount a
    JOIN DimCustomer c ON a.customer_id = c.customer_id
    LEFT JOIN FactTransaction t ON a.account_id = t.account_id
    WHERE c.customer_name LIKE '%' + @name + '%'
        AND a.status = 'Active'
    GROUP BY c.customer_name, a.account_type, a.Balance;
END;

EXEC BalancePerCustomer @name = 'Shelly';
