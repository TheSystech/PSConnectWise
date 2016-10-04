<#
.SYNOPSIS
    Gets ConnectWise board information. 
.PARAMETER ID
    ConnectWise board ID
.PARAMETER Name
    Name of the board 
.PARAMETER Filter
    Query String 
.PARAMETER SizeLimit
    Max number of items to return
.PARAMETER Descending
    Changes the sorting to descending order by IDs
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServiceBoard -ID 1 -Server $CWServer;
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServiceBoard -Query "ID in (1, 2, 3, 4, 5)" -Server $CWServer;
#>
function Get-CWServiceBoard
{
    [CmdLetBinding()]
    [OutputType("PSObject", ParameterSetName="Normal")]
    [OutputType("PSObject[]", ParameterSetName="Name")]
    [OutputType("PSObject[]", ParameterSetName="Query")]
    [CmdletBinding(DefaultParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$ID,
        [Parameter(ParameterSetName='Name', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(ParameterSetName='Query', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(ParameterSetName='Name')]
        [Parameter(ParameterSetName='Query')]
        [ValidateRange(1, 1000)]
        [uint32]$SizeLimit = 100,
        [Parameter(ParameterSetName='Name')]
        [Parameter(ParameterSetName='Query')]
        [switch]$Descending,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [Parameter(ParameterSetName='Name', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Session = $script:CWSession
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        [string]$OrderBy = [String]::Empty;

        # get the service
        $BoardSvc = $null;
        if ($Session -ne $null)
        {
            $BoardSvc = [CwApiServiceBoardSvc]::new($Session);
        } 
        else 
        {
            Write-Error "No open ConnectWise session. See Set-CWSession for more information.";
        }
        
        [uint32] $boardCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of ticket to request and total ticket count
        if (![String]::IsNullOrWhiteSpace($Filter) -or ![String]::IsNullOrWhiteSpace($Name))
        {
            if (![String]::IsNullOrWhiteSpace($Name))
            {
                $Filter = "name='$Name'";
                if ([RegEx]::IsMatch($Name, "\*"))
                {
                    $Filter = "name like '$Name'";

                }
                Write-Verbose "Created a Filter String Based on the Identifier Value ($Name): $Filter";
            }
            
            $boardCount = $BoardSvc.GetBoardCount($Filter);
            Write-Debug "Total Count Board the Filter ($Filter): $boardCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Board Count Excess SizeLimit; Setting Board Count to the SizeLimit: $SizeLimit"
                $boardCount = [Math]::Min($boardCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($boardCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Boards Per Pages): $pageCount";
        }
        
        #specify the ordering
        if ($Descending)
        {
            $OrderBy = " id desc";
        }
        
        # determines if to select all fields or specific fields
        [string[]] $Properties = $null;
        if ($null -ne $Property)
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
                
                if ($null -ne $boardCount -and $boardCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsRemainCount = $boardCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsRemainCount, $MAX_ITEMS_PER_PAGE);
                }
                
                Write-Debug "Requesting Board IDs that Meets this Filter: $Filter";
                $queriedBoards = $BoardSvc.ReadBoards($Filter, $OrderBy, $pageNum, $itemsPerPage);
                [pscustomobject[]] $Boards = $queriedBoards;
                
                foreach ($Board in $Boards)
                {
                    Write-Verbose "Requesting ConnectWise Board Number: $Board";
                    if ($null -eq $Properties -or $Properties.Length -eq 0)
                    {
                        $Board;
                    }
                    else 
                    {
                        $Board;
                    }
                }
                
            } else {
                
                Write-Debug "Retrieving ConnectWise Boards by Board ID"
                foreach ($Board in $ID)
                {
                    Write-Verbose "Requesting ConnectWise Board Number: $Board";
                    if ($null -eq $Properties -or $Properties.Length -eq 0)
                    {
                        $BoardSvc.ReadBoard($Board);
                    }
                    else 
                    {
                        $BoardSvc.ReadBoard($Board, $Properties);
                    }
                }
                
            }
            
        }
    }
    End
    {
        # do nothing here
    }
}

Export-ModuleMember -Function 'Get-CWServiceBoard';