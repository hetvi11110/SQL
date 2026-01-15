
--Create a new database named db_{yourfirstname}.
CREATE DATABASE db_hetvi
GO

USE db_hetvi
GO

--Create Customer Table
CREATE TABLE dbo.Customer
    (ID int IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    CustomerID int NOT NULL UNIQUE,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL)
GO

--Create Orders Table
CREATE TABLE dbo.Orders
    (OrderID  int IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    CustomerID int NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP)
GO

--Prevent deletion of a customer if they have existing orders. 
--Create a custom error message using RAISEERROR to notify if the deletion of a customer with orders fails.
IF EXISTS (
    SELECT 1 
    FROM sys.triggers 
    WHERE name = N'PreventCustomerDeletion'
)
    DROP TRIGGER PreventCustomerDeletion;
GO
CREATE TRIGGER PreventCustomerDeletion ON dbo.Customer
	INSTEAD OF DELETE
AS
IF EXISTS ( SELECT 1 FROM dbo.Orders WHERE CustomerID IN (SELECT CustomerID FROM deleted) )
BEGIN
    RAISERROR ('Cannot delete customer with existing orders.',16,1);
    RETURN; 
END
DELETE FROM dbo.Customer WHERE CustomerID IN (SELECT CustomerID FROM deleted);
GO

--Ensure CustomerID update in Customer table updates related rows in Orders table
IF EXISTS (
    SELECT 1 
    FROM sys.triggers 
    WHERE name = N'UpdateCustomerIDInOrders'
)
    DROP TRIGGER UpdateCustomerIDInOrders;
GO
CREATE TRIGGER UpdateCustomerIDInOrders ON dbo.Customer
	AFTER UPDATE
AS
IF UPDATE (CustomerID)
BEGIN
    UPDATE Orders
	SET CustomerID = i.CustomerID
	FROM Orders o
	JOIN inserted i ON o.CustomerID = (SELECT CustomerID FROM deleted)
	WHERE o.CustomerID = (SELECT CustomerID FROM deleted)
END
GO

--When inserting or updating records in the Orders table, validate that the CustomerID exists in the Customer table. If not, use RAISEERROR to display an appropriate message.
IF EXISTS (
    SELECT 1 
    FROM sys.triggers 
    WHERE name = N'ValidateCustomerIDInOrders'
)
    DROP TRIGGER ValidateCustomerIDInOrders;
GO
CREATE TRIGGER ValidateCustomerIDInOrders ON dbo.Orders
	FOR INSERT, UPDATE
AS
IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID IN (SELECT CustomerID FROM inserted))
BEGIN
	RAISERROR ('Invalid CustomerID. Customer does not exist.', 16, 1);
	ROLLBACK TRANSACTION;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Create a Scalar Function 
CREATE FUNCTION fn_CheckName 
(
	@FirstName NVARCHAR(50), @LastName NVARCHAR(50)
)
RETURNS BIT
AS
BEGIN
    IF @FirstName = @LastName
        RETURN 0;
    RETURN 1;
END;
GO

--Create a Stored Procedure 
CREATE PROCEDURE sp_InsertCustomer
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @CustomerID INT = NULL
AS
BEGIN
    IF dbo.fn_CheckName(@FirstName, @LastName) = 0
    BEGIN
        RAISERROR ('First Name and Last Name cannot be identical.', 16, 1);
        RETURN;
    END;

    IF @CustomerID IS NULL
    BEGIN
        SELECT @CustomerID = MAX(CustomerID) + 1 FROM dbo.Customer;
    END

    INSERT INTO Customer (CustomerID, FirstName, LastName)
    VALUES (@CustomerID, @FirstName, @LastName);
END
GO

--Audit Logging
CREATE TABLE CusAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerIDOldValue INT,
	CustomerIDNewValue INT,
    FirstNameOldValue NVARCHAR(255),
    FirstNameNewValue NVARCHAR(255),
	LastNameOldValue NVARCHAR(255),
    LastNameNewValue NVARCHAR(255),
    ChangeDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    LoginName NVARCHAR(50) DEFAULT SYSTEM_USER
);
GO

CREATE TRIGGER Audit_Logging
ON dbo.Customer
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DECLARE @CustomerIDOld INT, @CustomerIDNew INT;
    DECLARE @FirstNameOld NVARCHAR(255), @FirstNameNew NVARCHAR(255);
    DECLARE @LastNameOld NVARCHAR(255), @LastNameNew NVARCHAR(255);
	IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
	BEGIN
		SELECT 
            @CustomerIDNew = i.CustomerID, 
            @FirstNameNew = i.FirstName, 
            @LastNameNew = i.LastName
		FROM inserted i;
		INSERT INTO dbo.CusAudit (
            CustomerIDOldValue,
            CustomerIDNewValue,
            FirstNameOldValue,
            FirstNameNewValue,
            LastNameOldValue,
            LastNameNewValue,
            LoginName
        )
        SELECT 
            NULL,
            @CustomerIDNew, 
            NULL,
            @FirstNameNew, 
            NULL,
            @LastNameNew, 
            SYSTEM_USER;
	END
	IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
		SELECT 
            @CustomerIDOld = d.CustomerID, 
            @FirstNameOld = d.FirstName, 
            @LastNameOld = d.LastName
        FROM deleted d;
		SELECT 
            @CustomerIDNew = i.CustomerID, 
            @FirstNameNew = i.FirstName, 
            @LastNameNew = i.LastName
        FROM inserted i;
		INSERT INTO dbo.CusAudit (
            CustomerIDOldValue,
            CustomerIDNewValue,
            FirstNameOldValue,
            FirstNameNewValue,
            LastNameOldValue,
            LastNameNewValue,
            LoginName
        )
        SELECT 
            @CustomerIDOld,
            @CustomerIDNew, 
            @FirstNameOld,
            @FirstNameNew, 
            @LastNameOld,
            @LastNameNew, 
            SYSTEM_USER;
	END
	IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
		SELECT 
        @CustomerIDOld = d.CustomerID, 
        @FirstNameOld = d.FirstName, 
        @LastNameOld = d.LastName
        FROM deleted d;
		INSERT INTO dbo.CusAudit (
            CustomerIDOldValue,
            CustomerIDNewValue,
            FirstNameOldValue,
            FirstNameNewValue,
            LastNameOldValue,
            LastNameNewValue,
            LoginName
        )
        SELECT 
            @CustomerIDOld,
            NULL, 
            @FirstNameOld,
            NULL, 
            @LastNameOld,
            NULL, 
            SYSTEM_USER;
	END
END
GO
