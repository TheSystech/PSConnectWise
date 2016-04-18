# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "CWConnectionInfoCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWConnectionInfoCmdLets.psm1" -Force 
Remove-Module "CWCompanyCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWCompanyCmdLets.psm1" -Force 

Describe 'CWCompany' {
		
	. "$WorkspaceRoot\test\LoadTestSettings.ps1"
	
	# get the server connnection
	$pstrServer = Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWCompany' {
        
        $pstrCompanyIDs = $pstrComp.companyIds;
		$pstrCompanyID  = $pstrComp.companyIds[0];
    
	
        It 'gets company and checks for the id field' {
			$companyID = $pstrCompanyID;
			$company = Get-CWCompany -ID $companyID -Server $pstrServer
			$company.id | Should Be $companyID;		
		} 
		
		It 'gets company and pipes it through the Select-Object cmdlet for the id property' {
			$companyID = $pstrCompanyID;
			$company = Get-CWCompany -ID $companyID -Server $pstrServer;
			$company | Select-Object -ExpandProperty id | Should Be $companyID;		
		}
		
		It 'gets the id and subject properties of a company by using the -Property param' {
			$companyID = $pstrCompanyID;
			$fields = @("id", "identifier", "name");
			$company = Get-CWCompany -ID $companyID -Property $fields -Server $pstrServer;
			$company.PSObject.Properties | Measure-Object | Select -ExpandProperty Count | Should Be $fields.Count;		
		}
		
		It 'gets tickets by passing array of company ids to the -ID param' {
			$companyIDs = $pstrCompanyIDs;
			$tickets = Get-CWCompany -ID $companyIDs -Server $pstrServer;
			$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $companyIDs.Count;		
		}
		
		It 'gets list of tickets that were piped to the cmdlet' {
			$companyIDs = $pstrCompanyIDs;
			$tickets = $companyIDs | Get-CWCompany -Server $pstrServer
			$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $companyIDs.Count;		
		}
		
		It 'gets company based on the -Filter param' {
			$filter = "id = $pstrCompanyID";
			$company = Get-CWCompany -Filter $filter -Server $pstrServer;
			$company.id | Should Be $pstrCompanyID;		
		}
		
		It 'gets company based on the -Filter param and uses the SizeLimit param' {
			$filter = "id IN ($([String]::Join(',', $pstrCompanyIDs)))";
			$sizeLimit =  2;
			$tickets = Get-CWCompany -Filter $filter -SizeLimit $sizeLimit -Server $pstrServer;
			$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets tickets and sorts company id by descending piping cmdlet through Sort-Object cmdlet' {
			$companyIDs = $pstrCompanyIDs;
			$tickets = Get-CWCompany -ID $companyIDs -Server $pstrServer | Sort -Descending id;
			$maxTicketId = $companyIDs | Measure-Object -Maximum | Select -ExpandProperty Maximum
			$tickets[0].id | Should Be $maxTicketId;		
		}
        
    }

}