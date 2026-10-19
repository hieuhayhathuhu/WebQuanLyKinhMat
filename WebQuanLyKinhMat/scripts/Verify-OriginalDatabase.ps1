#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('Baseline','Compare')][string]$Mode,
    [Parameter()][string]$SnapshotFile
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$databaseName = 'QuanLyKinhMat'
if ([string]::IsNullOrWhiteSpace($SnapshotFile)) {
    $SnapshotFile = Join-Path $projectRoot 'artifacts\original-database-baseline.json'
}
$SnapshotFile = [System.IO.Path]::GetFullPath($SnapshotFile)
if ($Mode -eq 'Baseline' -and (Test-Path -LiteralPath $SnapshotFile)) {
    throw 'Baseline da ton tai; dung SnapshotFile moi de khong ghi de bang chung cu.'
}
if ($Mode -eq 'Compare' -and -not (Test-Path -LiteralPath $SnapshotFile -PathType Leaf)) {
    throw 'Khong tim thay baseline de so sanh.'
}

Add-Type -AssemblyName System.Data
$settingsPath = Join-Path $projectRoot 'appsettings.json'
$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
$configured = New-Object System.Data.SqlClient.SqlConnectionStringBuilder($settings.ConnectionStrings.Store)
if ([string]::IsNullOrWhiteSpace($configured.DataSource)) { throw 'appsettings.json khong co SQL Server hop le.' }

# Only the server is inherited. Always use Windows authentication and the original database.
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source'] = $configured.DataSource
$builder['Initial Catalog'] = $databaseName
$builder['Integrated Security'] = $true
$builder['Encrypt'] = $true
$builder['TrustServerCertificate'] = $true
$builder['Connect Timeout'] = 10
$builder['Application Name'] = 'KinhMat.VerifyOriginal.ReadOnly'
$builder['ApplicationIntent'] = 'ReadOnly'
if ($builder.InitialCatalog -cne 'QuanLyKinhMat' -or -not $builder.IntegratedSecurity) {
    throw 'Dung lai: chi cho phep QuanLyKinhMat voi Windows authentication.'
}
$connection = New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString)
$transaction = $null

function New-ReadCommand([string]$Sql) {
    $command = $connection.CreateCommand()
    $command.Transaction = $transaction
    $command.CommandTimeout = 180
    $command.CommandText = $Sql
    return $command
}
function Add-HashBytes([System.Security.Cryptography.HashAlgorithm]$Hash, [byte[]]$Bytes) {
    if ($Bytes.Length -gt 0) { [void]$Hash.TransformBlock($Bytes, 0, $Bytes.Length, $Bytes, 0) }
}
function Complete-Hash([System.Security.Cryptography.HashAlgorithm]$Hash) {
    [void]$Hash.TransformFinalBlock([byte[]]@(), 0, 0)
    return [BitConverter]::ToString($Hash.Hash).Replace('-', '').ToLowerInvariant()
}
function Quote-Identifier([string]$Name) { return '[' + $Name.Replace(']', ']]') + ']' }

# Metadata is serialized inside SQL in an explicit order; only its SHA256 leaves memory.
# Column definitions, defaults, computed columns, identity, keys, indexes, foreign keys,
# checks, and SQL module definitions are covered without exposing their contents.
$schemaQuery = @'
SELECT s.name AS schemaName,s.principal_id AS principalId
FROM sys.schemas s WHERE EXISTS(SELECT 1 FROM sys.objects o WHERE o.schema_id=s.schema_id AND o.is_ms_shipped=0)
ORDER BY s.name FOR JSON PATH,INCLUDE_NULL_VALUES;
SELECT s.name AS schemaName,t.name AS tableName,t.temporal_type,t.is_memory_optimized,t.lock_escalation_desc
FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0
ORDER BY s.name,t.name FOR JSON PATH,INCLUDE_NULL_VALUES;
SELECT s.name AS schemaName,t.name AS tableName,c.column_id,c.name AS columnName,ts.name AS typeSchema,ty.name AS typeName,
c.system_type_id,c.max_length,c.precision,c.scale,c.collation_name,c.is_nullable,c.is_ansi_padded,c.is_rowguidcol,c.is_identity,
c.is_computed,c.is_sparse,c.is_column_set,c.generated_always_type,dc.name AS defaultName,dc.definition AS defaultDefinition,
cc.definition AS computedDefinition,cc.is_persisted,CONVERT(nvarchar(100),ic.seed_value) AS identitySeed,
CONVERT(nvarchar(100),ic.increment_value) AS identityIncrement,ic.is_not_for_replication
FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.columns c ON c.object_id=t.object_id
JOIN sys.types ty ON ty.user_type_id=c.user_type_id JOIN sys.schemas ts ON ts.schema_id=ty.schema_id
LEFT JOIN sys.default_constraints dc ON dc.object_id=c.default_object_id
LEFT JOIN sys.computed_columns cc ON cc.object_id=c.object_id AND cc.column_id=c.column_id
LEFT JOIN sys.identity_columns ic ON ic.object_id=c.object_id AND ic.column_id=c.column_id
WHERE t.is_ms_shipped=0 ORDER BY s.name,t.name,c.column_id FOR JSON PATH,INCLUDE_NULL_VALUES;
SELECT s.name AS schemaName,t.name AS tableName,i.name AS indexName,i.type_desc,i.is_unique,i.is_primary_key,
i.is_unique_constraint,i.is_disabled,i.has_filter,i.filter_definition,i.fill_factor,i.ignore_dup_key,
ic.index_column_id,ic.key_ordinal,ic.is_descending_key,ic.is_included_column,c.name AS columnName
FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.indexes i ON i.object_id=t.object_id
LEFT JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
LEFT JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE t.is_ms_shipped=0 AND i.index_id>0
ORDER BY s.name,t.name,i.name,ic.index_column_id FOR JSON PATH,INCLUDE_NULL_VALUES;
SELECT s.name AS schemaName,t.name AS tableName,f.name AS foreignKeyName,fc.constraint_column_id,c.name AS columnName,
rs.name AS referencedSchema,rt.name AS referencedTable,rc.name AS referencedColumn,
f.delete_referential_action,f.update_referential_action,f.is_disabled,f.is_not_trusted,f.is_not_for_replication
FROM sys.foreign_keys f JOIN sys.tables t ON t.object_id=f.parent_object_id JOIN sys.schemas s ON s.schema_id=t.schema_id
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id
JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=fc.parent_column_id
JOIN sys.tables rt ON rt.object_id=f.referenced_object_id JOIN sys.schemas rs ON rs.schema_id=rt.schema_id
JOIN sys.columns rc ON rc.object_id=rt.object_id AND rc.column_id=fc.referenced_column_id
WHERE t.is_ms_shipped=0 ORDER BY s.name,t.name,f.name,fc.constraint_column_id FOR JSON PATH,INCLUDE_NULL_VALUES;
SELECT s.name AS schemaName,t.name AS tableName,cc.name AS checkName,cc.definition,cc.is_disabled,cc.is_not_trusted,cc.is_not_for_replication
FROM sys.check_constraints cc JOIN sys.tables t ON t.object_id=cc.parent_object_id JOIN sys.schemas s ON s.schema_id=t.schema_id
WHERE t.is_ms_shipped=0 ORDER BY s.name,t.name,cc.name FOR JSON PATH,INCLUDE_NULL_VALUES;
SELECT s.name AS schemaName,o.name AS objectName,o.type_desc,m.definition,m.uses_ansi_nulls,m.uses_quoted_identifier,
m.is_schema_bound,m.execute_as_principal_id,tr.is_disabled,tr.is_instead_of_trigger
FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
LEFT JOIN sys.triggers tr ON tr.object_id=o.object_id
WHERE o.is_ms_shipped=0 AND (m.object_id IS NOT NULL OR tr.object_id IS NOT NULL)
ORDER BY s.name,o.name,o.type_desc FOR JSON PATH,INCLUDE_NULL_VALUES;
'@

function Get-SchemaFingerprint {
    $hash = [System.Security.Cryptography.SHA256]::Create()
    $command = New-ReadCommand $schemaQuery
    $reader = $null
    try {
        $reader = $command.ExecuteReader()
        $section = 0
        do {
            # Separate the result sets, then hash UTF-16 bytes without chunk delimiters.
            # This preserves surrogate pairs even if SQL splits its JSON into chunks.
            Add-HashBytes $hash ([BitConverter]::GetBytes([long]$section))
            while ($reader.Read()) {
                Add-HashBytes $hash ([System.Text.Encoding]::Unicode.GetBytes($reader.GetString(0)))
            }
            Add-HashBytes $hash ([byte[]]@(0,0))
            $section++
        } while ($reader.NextResult())
        return Complete-Hash $hash
    } finally {
        if ($null -ne $reader) { $reader.Dispose() }
        $command.Dispose(); $hash.Dispose()
    }
}

function Get-TableFingerprint([object]$Table) {
    $command = New-ReadCommand 'SELECT c.name,c.system_type_id FROM sys.columns c JOIN sys.tables t ON t.object_id=c.object_id JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE s.name=@schema AND t.name=@table ORDER BY c.column_id;'
    [void]$command.Parameters.AddWithValue('@schema', $Table.schema)
    [void]$command.Parameters.AddWithValue('@table', $Table.table)
    $reader = $null
    $projections = New-Object 'System.Collections.Generic.List[string]'
    try {
        $reader = $command.ExecuteReader()
        while ($reader.Read()) {
            $column = Quote-Identifier $reader.GetString(0)
            $systemType = $reader.GetByte(1)
            if ($systemType -eq 241) {
                # XML requires a string conversion before binary conversion.
                $projections.Add("CONVERT(varbinary(max),CONVERT(nvarchar(max),$column))")
            } elseif ($systemType -eq 98 -or $systemType -eq 240) {
                throw 'Database co sql_variant/CLR UDT: can bo sung canonical serializer truoc khi tao baseline.'
            } else {
                $projections.Add("CONVERT(varbinary(max),$column)")
            }
        }
    } finally {
        if ($null -ne $reader) { $reader.Dispose() }
        $command.Dispose()
    }
    if ($projections.Count -eq 0) { throw 'Bang khong co metadata cot; dung lai thay vi tao fingerprint khong day du.' }

    $qualified = (Quote-Identifier $Table.schema) + '.' + (Quote-Identifier $Table.table)
    $command = New-ReadCommand ('SELECT ' + [string]::Join(',', $projections) + ' FROM ' + $qualified + ' WITH(HOLDLOCK);')
    $reader = $null
    $rowHashes = New-Object 'System.Collections.Generic.List[string]'
    [long]$count = 0
    try {
        $reader = $command.ExecuteReader()
        while ($reader.Read()) {
            $rowHash = [System.Security.Cryptography.SHA256]::Create()
            try {
                for ($columnIndex=0; $columnIndex -lt $reader.FieldCount; $columnIndex++) {
                    if ($reader.IsDBNull($columnIndex)) {
                        Add-HashBytes $rowHash ([BitConverter]::GetBytes([long]-1))
                    } else {
                        [byte[]]$bytes = $reader.GetValue($columnIndex)
                        # Length framing distinguishes NULL, empty data, and column boundaries.
                        Add-HashBytes $rowHash ([BitConverter]::GetBytes([long]$bytes.Length))
                        Add-HashBytes $rowHash $bytes
                    }
                }
                $rowHashes.Add((Complete-Hash $rowHash))
                $count++
            } finally { $rowHash.Dispose() }
        }
    } finally {
        if ($null -ne $reader) { $reader.Dispose() }
        $command.Dispose()
    }
    # Sort the fixed-width row hashes, retaining duplicates. Physical row order is irrelevant.
    $rowHashes.Sort([System.StringComparer]::Ordinal)
    $tableHash = [System.Security.Cryptography.SHA256]::Create()
    try {
        foreach ($row in $rowHashes) { Add-HashBytes $tableHash ([System.Text.Encoding]::ASCII.GetBytes($row)) }
        $fingerprint = Complete-Hash $tableHash
    } finally { $tableHash.Dispose() }
    return [PSCustomObject][ordered]@{ schema=$Table.schema; table=$Table.table; columns=$projections.Count; rows=$count; sha256=$fingerprint }
}

try {
    $connection.Open()
    $guard = $connection.CreateCommand()
    try {
        $guard.CommandText = 'SELECT DB_NAME();'
        if ([string]$guard.ExecuteScalar() -cne 'QuanLyKinhMat') { throw 'Wrong database: original verification stopped.' }
        $guard.CommandText = "SELECT HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION');"
        if ([int]$guard.ExecuteScalar() -ne 1) { throw 'Can quyen VIEW DEFINITION de fingerprint schema day du; khong tao baseline mot phan.' }
    } finally { $guard.Dispose() }

    # Serializable SELECTs hold read locks for a consistent capture; no INSERT/UPDATE/DELETE/DDL is issued.
    $transaction = $connection.BeginTransaction([System.Data.IsolationLevel]::Serializable)
    $schemaFingerprint = Get-SchemaFingerprint
    $command = New-ReadCommand 'SELECT s.name,t.name FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0 ORDER BY s.name,t.name;'
    $reader = $null
    $tables = New-Object 'System.Collections.Generic.List[object]'
    try {
        $reader = $command.ExecuteReader()
        while ($reader.Read()) { $tables.Add([PSCustomObject]@{ schema=$reader.GetString(0); table=$reader.GetString(1) }) }
    } finally {
        if ($null -ne $reader) { $reader.Dispose() }
        $command.Dispose()
    }
    if ($tables.Count -eq 0) { throw 'Khong thay bang trong database goc; khong tao baseline rong.' }
    $fingerprints = New-Object 'System.Collections.Generic.List[object]'
    foreach ($table in $tables) { $fingerprints.Add((Get-TableFingerprint $table)) }
    # A second metadata read also rejects concurrent DDL instead of accepting a mixed capture.
    if ($schemaFingerprint -cne (Get-SchemaFingerprint)) { throw 'Schema thay doi trong khi doc; chay lai khi database on dinh.' }
    $transaction.Commit(); $transaction.Dispose(); $transaction = $null
    $snapshot = [PSCustomObject][ordered]@{
        formatVersion=1; algorithm='SHA256(sorted SHA256(length-prefixed SQL binary row values))'
        createdAt=[DateTime]::UtcNow.ToString('o'); server=$builder.DataSource; database=$databaseName
        schemaSha256=$schemaFingerprint; tables=@($fingerprints.ToArray())
    }
    if ($Mode -eq 'Baseline') {
        $parent = Split-Path -Parent $SnapshotFile
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void][System.IO.Directory]::CreateDirectory($parent) }
        $json = $snapshot | ConvertTo-Json -Depth 8
        # CreateNew protects an existing baseline, including one created concurrently.
        $stream = New-Object System.IO.FileStream($SnapshotFile,[System.IO.FileMode]::CreateNew,[System.IO.FileAccess]::Write,[System.IO.FileShare]::None)
        try {
            $encoded = (New-Object System.Text.UTF8Encoding($false)).GetBytes($json)
            $stream.Write($encoded,0,$encoded.Length)
        } finally { $stream.Dispose() }
        Write-Host "Da tao baseline chi doc: $($snapshot.tables.Count) bang trong QuanLyKinhMat."
        Write-Host "Snapshot: $SnapshotFile"
    } else {
        $baseline = Get-Content -LiteralPath $SnapshotFile -Raw | ConvertFrom-Json
        if ($baseline.formatVersion -ne 1 -or $baseline.database -cne $databaseName -or $baseline.algorithm -cne $snapshot.algorithm) { throw 'Snapshot khong dung dinh dang/Database/algorithm.' }
        if (-not [string]::Equals([string]$baseline.server,[string]$snapshot.server,[StringComparison]::OrdinalIgnoreCase)) { throw 'SQL Server khac baseline; khong so sanh nham database.' }
        if ($baseline.schemaSha256 -cne $snapshot.schemaSha256) { throw 'KHONG DAT: schema database goc khac baseline.' }
        $expected = @($baseline.tables)
        $actual = @($snapshot.tables)
        if ($expected.Count -ne $actual.Count) { throw 'KHONG DAT: so bang database goc khac baseline.' }
        for ($index=0; $index -lt $expected.Count; $index++) {
            $left = $expected[$index]; $right = $actual[$index]
            if ($left.schema -cne $right.schema -or $left.table -cne $right.table -or $left.columns -ne $right.columns -or $left.rows -ne $right.rows -or $left.sha256 -cne $right.sha256) {
                throw "KHONG DAT: bang $($right.schema).$($right.table) khac baseline (ten/cot/so dong/SHA256)."
            }
        }
        Write-Host "DAT: $($actual.Count) bang, schema, so dong va SHA256 cua QuanLyKinhMat deu trung baseline."
    }
} finally {
    if ($null -ne $transaction) { try { $transaction.Rollback() } finally { $transaction.Dispose() } }
    $connection.Dispose()
}
