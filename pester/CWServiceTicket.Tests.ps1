# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "ConnectWisePSModule" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\ConnectWisePSModule.psm1" -Force 

# dot-sources the definition file to get static variables (prefixed with 'pstr') to be used for testing
. "$WorkspaceRoot\pester\.pester.variables.ps1" 

Describe 'Get-CWServiceTicket' {
	
	It 'gets ticket and checks for the id field' {
		$ticketID = $pstrTicketID;
		$ticket = Get-CWServiceTicket -TicketID $ticketID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
		$ticket.id | Should Be $ticketID;		
	}
	
	It 'gets ticket and pipes it through the Select-Object cmdlet for the id property' {
		$ticketID = $pstrTicketID;
		$ticket = Get-CWServiceTicket -TicketID $ticketID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
		$ticket | Select-Object -ExpandProperty id | Should Be $ticketID;		
	}
	
	It 'gets the id and subject properties of a ticket by using the -Property param' {
		$ticketID = $pstrTicketID;
		$fields = @("id", "summary");
		$ticket = Get-CWServiceTicket -TicketID $ticketID -Property $fields -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
		$ticket.PSObject.Properties | Measure-Object | Select -ExpandProperty Count | Should Be $fields.Count;		
	}
	
	It 'gets tickets by passing array of ticket ids to the -TicketID param' {
		$ticketIDs = $pstrTicketIDs;
		$tickets = Get-CWServiceTicket -TicketID $ticketIDs -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
		$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $ticketIDs.Count;		
	}
	
	It 'gets list of tickets that were piped to the cmdlet' {
		$ticketIDs = $pstrTicketIDs;
		$tickets = $ticketIDs | Get-CWServiceTicket -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
		$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $ticketIDs.Count;		
	}
	
	It 'gets ticket based on the -Filter param' {
		$filter = "id = $pstrTicketID";
		$ticket = Get-CWServiceTicket -Filter $filter -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
		$ticket.id | Should Be $pstrTicketID;		
	}

} 