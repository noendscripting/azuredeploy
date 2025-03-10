
"SQLitePCLRaw.core", "SQLitePCLRaw.provider.e_sqlite3", "SQLitePCLRaw.bundle_green", "Microsoft.Data.Sqlite" | ForEach-Object {
    
    $parentPath = ((Get-Package Microsoft.Data.Sqlite.Core).source) | Split-Path -Parent
    $packagePath = Join-Path -Path $parentPath -ChildPath "lib\netstandard2.0"
    if (Test-Path $packagePath) {
        $dlls = Get-ChildItem -Path $packagePath -Filter "*.dll" -Recurse
        foreach ($dll in $dlls) {
            [System.Reflection.Assembly]::LoadFile($dll.FullName) | Out-Null
        }
    }
    
}

$dlls | ForEach-Object { Import-Module  $_ }

Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    
    public static class Kernel32 {
        [DllImport("kernel32")]
        public static extern IntPtr LoadLibrary(string lpFileName);
    }    
"@
[Kernel32]::LoadLibrary('C:\Program Files\PackageManagement\NuGet\Packages\SQLitePCLRaw.lib.e_sqlite3.2.1.11\runtimes\win-x64\native\e_sqlite3.dll') | Out-Null