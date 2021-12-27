# ====================================================================================
#  Purpose     : SQL performance testing query
#                
#  Created By  : Dykema, Bill
#  Date        : 2021-11-08
# ====================================================================================
#  2021-11-08 - Dykema, Bill - initial version
#  2021-11-11 - Dykema, Bill - added long running query
#  2021-12-27 - Dykema, Bill - added custom query option
# ====================================================================================
#  Notes       : To use this script you must have the PowerShell SqlServer module,
#              : to install, run the following from PowerShell:
#              :     Install-Module -Name SqlServer
# ====================================================================================
 
# Setup variables
$ScriptName = $MyInvocation.MyCommand
$RunDir = "$(Get-Location)"
$LogFile = "$($RunDir)\SQLTest_$($env:COMPUTERNAME)"
 
# SQL connection
function GetSqlConnection
{
    $SQLConnString = "Server=$SQLServerInstance; database=$SQLDB;" +
                     " Integrated Security=True;"
    try
        {
            $SQLConnReturn = New-Object System.Data.SqlClient.SqlConnection
            $SQLConnReturn.ConnectionString = $SQLConnString
            $SQLConnReturn.Open()
            return $SQLConnReturn
        }
    catch
        {
            return $null
        }
}
 
# SQL query function
function GetSqlQuery($SQLQueryPassed)
{
    $SQLConnection = GetSqlConnection
 
    $SQLCmd = New-Object System.Data.SqlClient.SqlCommand
 
    $SQLCmd.CommandText = $SQLQueryPassed
    $SQLCmd.Connection = $SQLConnection
 
    $SQLReader = $SQLCmd.ExecuteReader()
 
    $SQLTableData = New-Object System.Data.DataTable
    $SQLTableData.Load($SQLReader)
   
    $SQLConnection.Close()
 
    return $SQLTableData
}
 
function SQLTables() {
 
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $SQLServerInstance,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $SQLDB
    )
 
    # Start
    Write-Host "Running SQL query from $env:COMPUTERNAME..."
 
    # Query to list database tables
    $SQLDBTables =  "DECLARE @QueryString NVARCHAR(MAX) ;" +
                    "SELECT @QueryString = COALESCE(@QueryString + ' UNION ALL ','')
                        + 'SELECT '
                        + '''' + QUOTENAME(SCHEMA_NAME(sOBJ.schema_id))
                        + '.' + QUOTENAME(sOBJ.name) + '''' + ' AS [TableName]
                        , COUNT(*) AS [RowCount] FROM '
                        + QUOTENAME(SCHEMA_NAME(sOBJ.schema_id))
                        + '.' + QUOTENAME(sOBJ.name) + ' WITH (NOLOCK) ' " +
                    "FROM $SQLDB.sys.objects AS sOBJ
                    WHERE
                        sOBJ.type = 'U'
                        AND sOBJ.is_ms_shipped = 0x0
                    ORDER BY SCHEMA_NAME(sOBJ.schema_id), sOBJ.name ;
                    EXEC sp_executesql @QueryString"
 
    # Database tables
    $DBTablesQuery = GetSqlQuery($SQLDBTables)
 
    # View tables
    $DBTablesQuery | Format-Table
 
}
 
function SQLTest() {
 
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $SQLServerInstance,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $SQLDB,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $SQLTable
    )
 
    # Break table into schema and table
    if ($SQLTable -like '*.*') {
        $SQLSchema = ($SQLTable -split "\.")[0]
        $SQLTable = ($SQLTable -split "\.")[1]
    } else {
        $SQLSchema = "dbo"
    }
 
    # Start
    Write-Host "Running SQL query from $env:COMPUTERNAME..."
    $RunDateTime = "$(Get-Date -UFormat '%Y-%m-%d_%T')"
    Write-Host "$RunDateTime - $SQLServerInstance server, $SQLDB database, $SQLSchema.$SQLTable table query starting"
    "$RunDateTime - $SQLServerInstance server, $SQLDB database, $SQLSchema.$SQLTable table query starting" | Out-File -FilePath $LogFile -Append
 
    # Get rows in table
    $SQLRows = "SELECT (SELECT COUNT(*) FROM $SQLSchema.$SQLTable) AS 'Rows'"
    $RowsQuery = GetSqlQuery($SQLRows)
    $RunDateTime = "$(Get-Date -UFormat '%Y-%m-%d_%T')"
    Write-Host "$RunDateTime - $($RowsQuery.Rows) rows returned"
    "$RunDateTime - $($RowsQuery.Rows) rows returned" | Out-File -FilePath $LogFile -Append
 
    # Get column names
    $SQLColumns = "SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = N'$SQLTable'"
    $ColumnsQuery = GetSqlQuery($SQLColumns)
    $ColumnNames = $ColumnsQuery.COLUMN_NAME
    $RunDateTime = "$(Get-Date -UFormat '%Y-%m-%d_%T')"
    Write-Host "$RunDateTime - $($ColumnNames.count) column names gathered"
    "$RunDateTime - $($ColumnNames.count) column names gathered" | Out-File -FilePath $LogFile -Append
    #$ColumnNames | Format-Table
 
    # Run query using each column to sort
    Foreach ($ColumnName in $ColumnNames) {
        $RunDateTime = "$(Get-Date -UFormat '%Y-%m-%d_%T')"
        Write-Host "$RunDateTime - Sorting with $ColumnName..."
        $SQLSorted = "SELECT * FROM $SQLSchema.$SQLTable ORDER BY [$ColumnName] ASC"
        $ColumnsQuery = GetSqlQuery($SQLSorted)
    }
 
    # Completed
    $RunDateTime = "$(Get-Date -UFormat '%Y-%m-%d_%T')"
    Write-Host "$RunDateTime - Completed running all sorts"
    "$RunDateTime - Completed running all sorts" | Out-File -FilePath $LogFile -Append
 
}
 
function SQLCustom() {
 
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $SQLServerInstance,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $SQLDB,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $SQLQueryFile
    )
 
    # Start
    Write-Host "Running SQL query from $env:COMPUTERNAME..."
 
    # Check to see if SQL file exists
    if (Test-Path $SQLQueryFile) {
        # Read the SQL file contents into a variable
        $SQLQuery = Get-Content $SQLQueryFile -Raw
    }
 
    # Run custom query
    $CustomResult = GetSqlQuery($SQLQuery)
 
    # View result
    $CustomResult | Format-Table
 
}
 
function SQLOptions {
    Write-Output "`nPlease use the following format to run a long running query against a table:"
    Write-Output "`t$ScriptName [SQLServer\SQLInstance] --SortTest [SQLDatabase] [SQLTable]"
    Write-Output "`nPlease use the following format to if you have added a custom query to this script:"
    Write-Output "`t$ScriptName [SQLServer\SQLInstance] --Custom [SQLDatabase] [SQLFileName]"
    Write-Output "`nPlease use the following format to list tables in a database:"
    Write-Output "`t$ScriptName [SQLServer\SQLInstance] --Tables [SQLDatabase]`n"
}
# Read arguments provided
if (!$args.length -gt 0) { # Not enough options provided
    SQLOptions
} elseif ($args.length -eq 3) { # Database list tables
    if ($args[1] -eq "--Tables") {
        SQLTables -SQLServerInstance $args[0] -SQLDB $args[2]
    } else { # Not valid option
        SQLOptions
    }
} elseif ($args.length -eq 4) { # Database table sort test or custom
    if ($args[1] -eq "--SortTest") {
        SQLTest -SQLServerInstance $args[0] -SQLDB $args[2] -SQLTable $args[3]
    } elseif ($args[1] -eq "--Custom") {
        SQLCustom -SQLServerInstance $args[0] -SQLDB $args[2] -SQLQueryFile $args[3]
    } else { # Not valid option
        SQLOptions
    }
} else { # Not valid number of options
    SQLOptions
}