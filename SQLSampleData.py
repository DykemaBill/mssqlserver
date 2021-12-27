# Pandas for dataframe manipulation
import pandas as pd
# Used to get the current date/time
from datetime import datetime, timedelta
# Used to generate a random number
import random
# Library to talk with Microsoft SQL Server
from sqlalchemy import create_engine
# Utils to create database if it does not exist already
from sqlalchemy_utils import database_exists, create_database

# Create DataFrame from scatch and populate it with test data
df_sampledata = pd.DataFrame(columns=['test_datetime', 'test_number', 'test_text', 'record_added'])
# Get the current date/time and the last 2 days and put them in a list
dates_to_add = list([])
two_days_ago = (datetime.now() - timedelta(days=2)).strftime("%Y/%m/%d %H:%M:%S")
two_days_ago_text = (datetime.now() - timedelta(days=2)).strftime("%B %d of %Y")
dates_to_add.append(dict({"datetime": two_days_ago, "datetext": two_days_ago_text}))
yesterday_was = (datetime.now() - timedelta(days=1)).strftime("%Y/%m/%d %H:%M:%S")
yesterday_was_text = (datetime.now() - timedelta(days=1)).strftime("%B %d of %Y")
dates_to_add.append(dict({"datetime": yesterday_was, "datetext": yesterday_was_text}))
now_is = datetime.now().strftime("%Y/%m/%d %H:%M:%S")
now_is_text = datetime.now().strftime("%B %d of %Y")
dates_to_add.append(dict({"datetime": now_is, "datetext": now_is_text}))
# Loop through each day and add some records
records_per_date = int(4)
data_now = pd.to_datetime(datetime.now().strftime("%Y/%m/%d %H:%M:%S"))
for date_to_add in dates_to_add:
    # Date and text to use
    date_is = pd.to_datetime(date_to_add['datetime'])
    text_is = "Record from " + date_to_add['datetext']
    # Add four records for each date
    for records_to_add in range(records_per_date):
        # Get a random number with 6 digits
        number_is = random.randint(100000, 1000000)
        # Populate some data
        df_sampledata = df_sampledata.append(pd.Series({'test_datetime': date_is, 'test_number': number_is, 'test_text': text_is, 'record_added': data_now}), ignore_index=True)

# View DataFrame we just created
now_stamp = datetime.now().strftime("%Y/%m/%d %H:%M:%S")
print(now_stamp + ": Data we just created that we will be writing to Microsoft SQL Server:")
print(df_sampledata)
# View DataFrame data field types
now_stamp = datetime.now().strftime("%Y/%m/%d %H:%M:%S")
print(now_stamp + ": Field types we just created:")
print(df_sampledata.convert_dtypes().dtypes)

# Database to create
mssql_database = "testdb"
# Connection string
db_connection = 'mssql+pyodbc://sa:SQLdev2019!@localhost:1433/' + mssql_database + '?driver=ODBC+Driver+17+for+SQL+Server'
# Database connection
db_inst = create_engine(db_connection, fast_executemany=True)
# Create database if it does not already exist
if not database_exists(db_inst.url):
    create_database(db_inst.url)
# SQL Server table to use
mssql_table = "testtable"

# Optional drop table
# now_stamp = datetime.now().strftime("%Y/%m/%d %H:%M:%S")
# print(now_stamp + ": Dropping existing Microsoft SQL Server table")
# mssql_drop = "DROP TABLE %s" % (str(mssql_table))
# db_inst.execute(mssql_drop)

# Append DataFrame to SQL Server table or create it if it does not exist
now_stamp = datetime.now().strftime("%Y/%m/%d %H:%M:%S")
print(now_stamp + ": Writing data to Microsoft SQL Server")
df_sampledata.to_sql(mssql_table, db_inst, if_exists='append', index=False)

# Build query to read table back
mssql_query = "SELECT * FROM %s" % (str(mssql_table))
# Run query
df_mssql = pd.read_sql_query(mssql_query, con=db_inst)

# View DataFrame data read from SQL Server
now_stamp = datetime.now().strftime("%Y/%m/%d %H:%M:%S")
print(now_stamp + ": Data read back from Microsoft SQL Server:")
print(df_mssql)
# View DataFrame data field types read from SQL Server
now_stamp = datetime.now().strftime("%Y/%m/%d %H:%M:%S")
print(now_stamp + ": Field types read back from Microsoft SQL Server:")
print(df_mssql.convert_dtypes().dtypes)