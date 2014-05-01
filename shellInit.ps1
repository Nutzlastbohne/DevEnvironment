# generate PowerShell Profile under %USER%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
New-Item -path $profile -type file –force

# Allow Scripts to be executed
set-executionpolicy remotesigned