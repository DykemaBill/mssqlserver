# ====================================================================================
#  Purpose     : SQL performance testing query
#                
#  Created By  : Dykema, Bill
#  Date        : 2021-11-08
# ====================================================================================
#  2021-11-08 - Dykema, Bill - initial version
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
 
    # View talbes
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
 
    # Start
    Write-Host "Running SQL query from $env:COMPUTERNAME..."
 
    # Test query
    $SQLQuery = "SELECT * from $SQLTable"
 
    # Time stamp
    $RunDateTime = "$(Get-Date -UFormat '%Y-%m-%d_%H%M')"
    Write-Host "$RunDateTime - $SQLServerInstance server, $SQLDB database, $SQLTable table query starting"
    "$RunDateTime - $SQLServerInstance server, $SQLDB database, $SQLTable table query starting" | Out-File -FilePath $LogFile -Append
 
    # Run query
    $TableQuery = GetSqlQuery($SQLQuery)
 
    # Number of rows returned
    $RunDateTime = "$(Get-Date -UFormat '%Y-%m-%d_%H%M')"
    $RowsReturned = ($TableQuery | Format-Table).Count
    Write-Host "$RunDateTime - $RowsReturned rows returned"
    "$RunDateTime - $RowsReturned rows returned" | Out-File -FilePath $LogFile -Append
 
    # View data
    #Write-Host "Table query result..."
    #$TableQuery | Format-Table
 
}
 
function SQLOptions {
    Write-Output "`nPlease use the following format to run a query against a table:"
    Write-Output "`t$ScriptName [SQLServer\SQLInstance] [SQLDatabase] [SQLTable]"
    Write-Output "`nPlease use the following format to list tables in a database:"
    Write-Output "`t$ScriptName [SQLServer\SQLInstance] [SQLDatabase]`n"
}
 
# Read arguments provided
if ($args.length -lt 2) { # No option provided
    SQLOptions
} elseif ($args.length -eq 2) { # Database list tables
    SQLTables -SQLServerInstance $args[0] -SQLDB $args[1]
} elseif ($args.length -eq 3) { # Database table test
    SQLTest -SQLServerInstance $args[0] -SQLDB $args[1] -SQLTable $args[2]
} else { # Not valid number of options
    SQLOptions
}