New-ItemProperty -Path hklm:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727 -Name "SystemDefaultTlsVersions" -PropertyType Dword -Value 1
New-ItemProperty -Path hklm:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727 -Name "SchUseStrongCrypto" -PropertyType Dword -Value 1
New-ItemProperty -Path hklm:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319 -Name "SystemDefaultTlsVersions" -PropertyType Dword -Value 1
New-ItemProperty -Path hklm:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319 -Name "SchUseStrongCrypto" -PropertyType Dword -Value 1
