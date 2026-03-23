#!/bin/bash
echo "Waiting for SQL Server to start..."
sleep 20
/opt/mssql-tools/bin/sqlcmd -S mssql -U sa -P "YourStrong!Passw0rd" -Q "IF NOT EXISTS(SELECT * FROM sys.databases WHERE name='moi-ops') CREATE DATABASE [moi-ops]"
/opt/mssql-tools/bin/sqlcmd -S mssql -U sa -P "YourStrong!Passw0rd" -Q "IF NOT EXISTS(SELECT * FROM sys.databases WHERE name='moi-al') CREATE DATABASE [moi-al]"
/opt/mssql-tools/bin/sqlcmd -S mssql -U sa -P "YourStrong!Passw0rd" -d "moi-ops" -i /shema.sql
/opt/mssql-tools/bin/sqlcmd -S mssql -U sa -P "YourStrong!Passw0rd" -d "moi-al" -i /shema.sql
echo "Databases initialized!"
