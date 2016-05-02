# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWCompanyContact' {
	
	. "$WorkspaceRoot\test\LoadTestSettings.ps1"
	
	# get the server connnection
	Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWCompanyContact' {

		$pstrCompanyIDs  = $pstrComp.companyIds;
		$pstrCompanyID   = $pstrComp.companyIds[0];
		$pstrContactIDs  = $pstrComp.contactIds;
		$pstrContactID   = $pstrComp.contactIds[0];
	
		It 'gets company contact entries for a company and check that the results is an array' {
			$companyID = $pstrCompanyID;
			$contacts = Get-CWCompanyContact -CompanyID $companyID;
			$contacts.GetType().BaseType.Name | Should Be "Array";		
		}
		
		It 'gets a single contact from a company and pipes it through the Select-Object cmdlet for the id property of the first object' {
			$companyID = $pstrCompanyID;
			$contact = Get-CWCompanyContact -CompanyID $companyID | Select-Object -First 1;
			$contact.company.id | Should Be $companyID;		
		}
		
		It 'gets a single contact' {
			$contactID = $pstrContactID;
			$contact = Get-CWCompanyContact -ID $contactID;
			$contact | Select-Object -ExpandProperty id | Should Be $contactID;		
		}
				
	}
	
} 