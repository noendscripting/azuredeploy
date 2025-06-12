
<#"SQLitePCLRaw.core", "SQLitePCLRaw.provider.e_sqlite3", "SQLitePCLRaw.bundle_green", "Microsoft.Data.Sqlite" | ForEach-Object {
    
    $parentPath = ((Get-Package Microsoft.Data.Sqlite.Core).source) | Split-Path -Parent
    $packagePath = Join-Path -Path $parentPath -ChildPath "lib\netstandard2.0"
    if (Test-Path $packagePath) {
        $dlls = Get-ChildItem -Path $packagePath -Filter "*.dll" -Recurse
        foreach ($dll in $dlls) {
            [System.Reflection.Assembly]::LoadFile($dll.FullName) | Out-Null
        }
    }
    
}#>

$packages = Join-Path $env:USERPROFILE '.nuget\packages'
$dlls = 'sqlitepclraw.core\2.1.10\lib\netstandard2.0\SQLitePCLRaw.core.dll',
        'sqlitepclraw.provider.e_sqlite3\2.1.10\lib\netstandard2.0\SQLitePCLRaw.provider.e_sqlite3.dll',
        'sqlitepclraw.bundle_e_sqlite3\2.1.10\lib\netstandard2.0\SQLitePCLRaw.batteries_v2.dll',
        'microsoft.data.sqlite\9.0.2\lib\netstandard2.0\Microsoft.Data.Sqlite.dll'    
$dlls | %{ Join-Path $packages $_ } | Import-Module


Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    
    public static class Kernel32 {
        [DllImport("kernel32")]
        public static extern IntPtr LoadLibrary(string lpFileName);
    }    
"@

Add-Type -TypeDefinition @"
    using System;
    using Microsoft.EntityFrameworkCore.Sqlite;"@
    
   
[Kernel32]::LoadLibrary((Join-Path $packages 'sqlitepclraw.provider.e_sqlite3\2.1.10\lib\netstandard2.0\SQLitePCLRaw.provider.e_sqlite3.dll')) #| Out-Null

$connection = New-Object Microsoft.Data.Sqlite.SqliteConnection 'Data Source=:memory:'
$connection.Open()