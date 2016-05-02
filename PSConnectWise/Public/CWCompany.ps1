<#
.SYNOPSIS
    Gets ConnectWise company information. 
.PARAMETER ID
    ConnectWise company ID
.PARAMETER Identifier
    ConnectWise company identifier name
.PARAMETER Filter
    Query String 
.PARAMETER Property
    Name of the properties to return
.PARAMETER SizeLimit
    Max number of items to return
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWCompany -ID 1 -Server $CWServer;
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWCompany -Identifier "LabTechSoftware" -Server $CWServer;
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWCompany -Query "ID in (1, 2, 3, 4, 5)" -Server $CWServer;
#>
function Get-CWCompany
{
    
    [CmdLetBinding()]
    [OutputType("PSObject", ParameterSetName="Normal")]
    [OutputType("PSObject", ParameterSetName="Identifier")]
    [OutputType("PSObject[]", ParameterSetName="Query")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32[]]$ID,
        [Parameter(ParameterSetName='Identifier', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Identifier,
        [Parameter(ParameterSetName='Query', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(ParameterSetName='Normal', Position=1, Mandatory=$false)]
        [Parameter(ParameterSetName='Identifier', Position=1, Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Position=1, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Property,
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [uint32]$SizeLimit,
        [Parameter(ParameterSetName='Normal', Position=2, Mandatory=$false)]
        [Parameter(ParameterSetName='Identifier', Position=2, Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Position=2, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Server = $script:CWServerInfo
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        
        # get the Company service
        $CompanySvc = [CwApiCompanySvc]::new($Server)
        
        [uint32] $companyCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of ticket to request and total ticket count
        if (![String]::IsNullOrWhiteSpace($Filter))
        {
            $companyCount = $CompanySvc.GetCompanyCount($Filter);
            Write-Debug "Total Count Company the Filter ($Filter): $companyCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Company Count Excess SizeLimit; Setting Company Count to the SizeLimit: $SizeLimit"
                $companyCount = [Math]::Min($companyCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($companyCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Companies Per Pages): $pageCount";
        }
        
        # determines if to select all fields or specific fields
        [string[]] $Properties = $null;
        if ($Property -ne $null)
        {
            if (!($Property.Length -eq 1 -and $Property[0].Trim() -ne "*"))
            {
                # TODO add parser for valid fields only
                $Properties = $Property;
            }
        }
    }
    Process
    {
        
        for ($pageNum = 1; $pageNum -le $pageCount; $pageNum++)
        {
            if (![String]::IsNullOrWhiteSpace($Filter))
            {
                if ($companyCount -ne $null -and $companyCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsRemainCount = $companyCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsRemainCount, $MAX_ITEMS_PER_PAGE);
                }
                
                Write-Debug "Requesting Company IDs that Meets this Filter: $Filter";
                $queriedCompanies = $CompanySvc.ReadCompanies($Filter, $Properties, $pageNum, $itemsPerPage);
                [psobject[]] $Companies = $queriedCompanies;
                
                foreach ($Company in $Companies)
                {
                    $Company;
                }
                
            } else {
                
                if ($Identifier -ne $null)
                {
                    
                    Write-Debug "Retrieving ConnectWise Companies by Company Identifier"
                    foreach ($Company in $Identifier)
                    {
                        Write-Verbose "Requesting ConnectWise Company Number: $CompanyID";
                        if ($Properties -eq $null -or $Properties.Length -eq 0)
                        {
                            $CompanySvc.ReadCompany([string] $Company);
                        }
                        else 
                        {
                            $CompanySvc.ReadCompany([string] $Company, $Properties);
                        }
                    }
                    
                } else {                
                    
                    Write-Debug "Retrieving ConnectWise Companies by Company ID"
                    foreach ($CompanyID in $ID)
                    {
                        Write-Verbose "Requesting ConnectWise Company Number: $CompanyID";
                        if ($Properties -eq $null -or $Properties.Length -eq 0)
                        {
                            $CompanySvc.ReadCompany([uint32] $CompanyID);
                        }
                        else 
                        {
                            $CompanySvc.ReadCompany($CompanyID, $Properties);
                        }
                    }
                    
                } #end if              
            }
            
        } #end foreach for pagination   
    }
    End
    {
        # do nothing here
    }
}

Export-ModuleMember -Function 'Get-CWCompany';