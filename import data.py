import pandas as pd
from sqlalchemy import create_engine
import os

# Define the MySQL database connection parameters
user = 'root'  # please replace with your username
password = 'root'  # please replace with your password
host = 'localhost'  # or the IP address where your MySQL instance is running
database = 'turisticka_agencija'  # please replace with your database name

# Create the connection string for SQL Alchemy
conn_string = f"mysql+mysqlconnector://{user}:{password}@{host}/{database}"
engine = create_engine(conn_string)

# Specify the directory where your CSV files are
dir_path = 'C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\data'

# Loop over all CSV files in the directory
for filename in os.listdir(dir_path):
    if filename.endswith(".csv"):  # check if the file is a CSV
        # Read the CSV file using pandas
        df = pd.read_csv(os.path.join(dir_path, filename))
        # Get the table name from the filename by removing .csv
        table_name = filename[:-4]
        # Upload the dataframe to the MySQL database
        df.to_sql(table_name, con=engine, if_exists='replace', index=False)

print("All CSV files have been imported to MySQL!")
