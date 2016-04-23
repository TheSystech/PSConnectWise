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
    [OutputType("PSObject[]", ParameterSetName="Identifier")]
    [OutputType("PSObject[]", ParameterSetName="Query")]
    [CmdletBinding(DefaultParameterSetName="Normal")]
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
        [Parameter(ParameterSetName='Identifier', Position=1, Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [ValidateRange(1, 1000)]
        [uint32]$SizeLimit = 100,
        [Parameter(ParameterSetName='Normal', Position=2, Mandatory=$true)]
        [Parameter(ParameterSetName='Identifier', Position=2, Mandatory=$true)]
        [Parameter(ParameterSetName='Query', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Server
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        [CwApiCompanySvc] $CompanySvr = $null; 
        
        # get the Company service
        if ($Server -ne $null)
        {
            $CompanySvc = [CwApiCompanySvc]::new($Server);
        } 
        else 
        {
            # TODO: determine whether or not to keep this as an option
            $CompanySvc = [CwApiCompanySvc]::new($Domain, $CompanyName, $PublicKey, $PrivateKey);
        }
        
        [uint32] $companyCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of ticket to request and total ticket count
        if (![String]::IsNullOrWhiteSpace($Filter) -or ![String]::IsNullOrWhiteSpace($Identifier))
        {
            if (![String]::IsNullOrWhiteSpace($Identifier))
            {
                $Filter = "identifier='$Identifier'";
                if ($Identifier -contains "*")
                {
                    $Filter = "identifier like '$Identifier'";

                }
                Write-Verbose "Created a Filter String Based on the Identifier Value ($Identifier): $Filter";
            }
            
            $companyCount = $CompanySvc.GetCompanyCount($Filter);
            Write-Debug "Total Count Company using Filter ($Filter): $companyCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Company Count Excess SizeLimit; Setting Company Count to the SizeLimit: $SizeLimit"
                $companyCount = [Math]::Min($companyCount, $SizeLimit);
            }
            
            $pageCount = [Math]::Ceiling([double]($companyCount / $MAX_ITEMS_PER_PAGE));
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Companies Per Pages): $pageCount";
        } # end if for filter/identifier check
        
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
            if (![String]::IsNullOrWhiteSpace($Filter) -or ![String]::IsNullOrWhiteSpace($Identifier))
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
                
            } 
            else 
            {
                
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
            
        } #end foreach for pagination   
    }
    End
    {
        # do nothing here
    }
}

Export-ModuleMember -Function 'Get-CWCompany';