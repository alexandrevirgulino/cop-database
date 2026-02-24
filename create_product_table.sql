CREATE TABLE app.Product
(
    ProductID        INT IDENTITY(1,1) NOT NULL,
    ProductCode      NVARCHAR(50) NOT NULL,
    ProductName      NVARCHAR(200) NOT NULL,
    Description      NVARCHAR(500) NULL,
    Category         NVARCHAR(100) NULL,
    UnitPrice        DECIMAL(18,2) NOT NULL,
    IsActive         BIT NOT NULL DEFAULT (1),
    CreatedAt        DATETIME2(0) NOT NULL DEFAULT (SYSDATETIME()),
    UpdatedAt        DATETIME2(0) NULL,

    CONSTRAINT PK_Product PRIMARY KEY CLUSTERED (ProductID),
    CONSTRAINT UQ_Product_ProductCode UNIQUE (ProductCode)
);
GO