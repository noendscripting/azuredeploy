

if((Get-WmiObject -class win32_OperatingSystem).version -notlike "10*")
{
    Invoke-WebRequest 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=49186&6B49FDFB-8E5B-4B07-BC31-15695C5A2143=1' -OutFile "$($PWD)\PackageManagement_x64.msi" -ErrorAction Stop
    Start-Process "$($PWD)\PackageManagement_x64.msi" -ArgumentList "/qn" -Wait
    Install-Module PSWindowsUpdate -Force
    Install-WindowsUpdate -Category 'Critical','Important' -AcceptAll -AutoReboot -Verbose
}
else
{
    Install-Module PSWindowsUpdate -Force
    Install-WindowsUpdate  -AutoReboot -AcceptAll  -KBArticleID "KB4132216","KB4343887" -Verbose
}


#Instainstall-WindowsUpdate -RootCategories 'Critical Updates', 'Security Updates', 'Update Rollups' -AcceptAll -AutoReboot -Verbose


[String]$ConnectionString="Server=tcp:aclxraysqlubertest.database.windows.net,1433;Initial Catalog=ACLXRAY;Persist Security Info=False;User ID='vadmin';Password='Test@2016!';MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$Conn = new-object System.Data.SqlClient.SqlConnection($ConnectionString)










