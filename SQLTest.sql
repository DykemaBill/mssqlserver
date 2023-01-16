-- Create a database
CREATE DATABASE [testdb]

-- Create a table
CREATE TABLE [testdb].[dbo].[test]
    (
      Test_DateTime    DATETIME2 NOT NULL,
      Test_Number      INT NOT NULL,
      Test_Text        VARCHAR(50) NOT NULL,
      Record_Added     TIMESTAMP NOT NULL
    )

-- Add a record
INSERT INTO [testdb].[dbo].[test]
    (
        Test_DateTime,
        Test_Number,
        Test_Text
    ) VALUES (
        GETDATE(),
        10,
        'Test text'
    )

-- Query all records
SELECT *
  FROM [testdb].[dbo].[test]