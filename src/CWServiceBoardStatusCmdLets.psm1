#dot-source import the classes
. "$PSScriptRoot\PSCWApiClasses.ps1"

function Get-CWServiceBoardStatus
{
    [CmdLetBinding()]
    param
    (
        [Parameter(ParameterSetName='SingleBoard', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$BoardID,
        [Parameter(ParameterSetName='SingleBoard', Position=2, Mandatory=$true)]
        [Parameter(ParameterSetName='BoardQuery', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseApiUrl,
        [Parameter(ParameterSetName='SingleBoard', Position=3, Mandatory=$true)]
        [Parameter(ParameterSetName='BoardQuery', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,
        [Parameter(ParameterSetName='SingleBoard', Position=4, Mandatory=$true)]
        [Parameter(ParameterSetName='BoardQuery', Position=3, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKey,
        [Parameter(ParameterSetName='SingleBoard', Position=5, Mandatory=$true)]
        [Parameter(ParameterSetName='BoardQuery', Position=4, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKey
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        
        # get the Board service
        $BoardStatusSvc = [CwApiServiceBoardStatusSvc]::new($BaseApiUrl, $CompanyName, $PublicKey, $PrivateKey);
        
        [uint32] $statusCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of board status to request and total ticket count
        if ($BoardID -gt 0)
        {
            $statusCount = $BoardStatusSvc.GetStatusCount([uint32]$BoardID);
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Board Count Excess SizeLimit; Setting Board Count to the SizeLimit: $SizeLimit"
                $statusCount = [Math]::Min($statusCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($statusCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Boards Per Pages): $pageCount";
        }
    }
    Process
    {
        for ($pageNum = 1; $pageNum -le $pageCount; $pageNum++)
        {
            if ($BoardID -gt 0)
            {
                # find how many Status to retrieve
                $statusesPerPage = $statusCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                
                Write-Debug "Requesting Ticket IDs that Meets this Filter: $Filter";
                $queriedStatuses = $BoardStatusSvc.ReadStatuses($boardId, [string[]] @("*"), $pageNum, $statusesPerPage);
                [pscustomobject[]] $Statuses = $queriedStatuses;
                
                foreach ($Status in $Statuses)
                {
                    $Status
                }
                
            }  elseif ($StatusID -ne $null) {
                
                Write-Debug "Retrieving ConnectWise Status by Ticket ID"
                foreach ($status in $StatusID)
                {
                    Write-Verbose "Requesting ConnectWise Ticket Number: $status";
                    $BoardStatusSvc.ReadStatus($boardId, $status);
                }
                
            }
        }
    }
    End
    {
        # do nothing here
    }
}

Export-ModuleMember -Function 'Get-CWServiceBoardStatus';