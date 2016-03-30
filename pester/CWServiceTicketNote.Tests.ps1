# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "CWServiceBoardStatusCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWServiceTicketNoteCmdLets.psm1" -Force 

# dot-sources the definition file to get static variables (prefixed with 'pstr') to be used for testing
. "$WorkspaceRoot\pester\.test.variables.ps1" 

Describe 'Get-CWServiceTicketNote' {
	
	It 'gets ticket note entries for a ticket and check that the results is an array' {
		$ticketID = $pstrTicketID;
		$timeEntries = Get-CWServiceTicketNote -TicketID $ticketID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
		$timeEntries.GetType().BaseType.Name | Should Be "Array";		
	}
	
	It 'gets a single note from a ticket and pipes it through the Select-Object cmdlet for the id property of the first object' {
		$noteID = $pstrNoteID;
		$ticketID = $pstrTicketID;
		$note = Get-CWServiceTicketNote -TicketID $ticketID -NoteID $noteID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey | Select-Object -First 1;
		$note | Select-Object -ExpandProperty ticketID | Should Be $ticketID;		
	}
	
	It 'add a new ticket note to a ticket then checks the return object for the ticket id' {
		$ticketID = $pstrTicketID;
		$message = "Testing the ability to add note entries to a ticket."
		$note = Add-CWServiceTicketNote -TicketID 7857582 -Message $message -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
		$note | Select-Object -ExpandProperty ticketId | Should Be $ticketID;	
	}

} 