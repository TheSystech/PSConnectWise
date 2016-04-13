# Testing

1. Change the name of "testSettings.example.json" to "testSettings.json"
1. Update value of each properties.
1. Execute from the project's root.
    `Invoke-Pester`
    
#Troubleshooting

###Pester 

This Test task runner requires an updated version of Pester (>=3.4.0) in order for the 
problemMatcher to find failed test information (message, line, file). If you don't have that 
version, you can update Pester from the PowerShell Gallery with this command:

    `Update-Module Pester`
   
If that gives an error like: "Module 'Pester' was not installed by using Install-Module, so it 
cannot be updated." then execute:

    `Install-Module Pester -Scope CurrentUser -Force`
    
*Source: [vscode-powershell](https://github.com/PowerShell/vscode-powershell)*
