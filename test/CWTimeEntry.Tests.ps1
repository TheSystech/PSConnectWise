# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWTimeEntry' {
	
	. $($WorkspaceRoot + '\test\LoadTestSettings.ps1');
	[hashtable] $pstrSharedValues = @{};
	
	# get the server connnection
	Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
 
 	Context "Add-CWTimeEntry"  {
		
		$pstrTicketID    = $pstrGenSvc.ticketIds[0];
		$pstrMemberID    = $pstrProcTimeEntry.memberId;

		$pstrSharedValues.Add("timeEntries", [psobject[]] @());
	
		It 'create a new time entry on a ticket' {
			$start = (Get-Date).AddMinutes(-15)
			$end   = Get-Date
			$message = "Testing Time Entries" 
			$entry = Add-CWTimeEntry -TicketID $pstrTicketID -Start $start -End $end -Message $message -MemberID $pstrMemberID -AddToInternal
			$pstrSharedValues.timeEntries += @($entry);
			$pstrSharedValues.timeEntries[0].id -gt 0 | Should Be $true;
		} 

		It 'create a new time entry on a ticket by passing a hashtable' {
			$data = @{
                TicketID     = $pstrTicketID;
                Start        = (Get-Date).AddMinutes(-1);
                End          = (Get-Date);
                Message      = "Testing Time Entries";
                AddTo        = @("Internal");
                MemberID     = $pstrMemberID;
			}

			$entry = Add-CWTimeEntry -HashTimeEntry $data;
			$pstrSharedValues.timeEntries += @($entry);
			$pstrSharedValues.timeEntries[0].id -gt 0 | Should Be $true;
		} 

		It 'create a new multi-day time entry on a ticket' {
			$start = (Get-Date).AddHours(-25)
			$end   = Get-Date
			$message = "Testing Time Entries" 
			$entries = Add-CWTimeEntry -TicketID $pstrTicketID -Start $start -End $end -Message $message -MemberID $pstrMemberID -AddToInternal
			$pstrSharedValues.timeEntries += @($entries);
			$entries.Count -gt 0 | Should Be $true; 
		} 
		
	} # end of Context "New-CWTimeEntry" 
 
	Context 'Get-CWTimeEntry' {
		
		$pstrTicketID     = $pstrGenSvc.ticketIds[0];
		$pstrTimeEntryID  = $pstrSharedValues.timeEntries[0].id;
		$pstrTimeEntryIDs = @($pstrSharedValues.timeEntries | Select-Object -ExpandProperty id);
		
		It 'gets time entries for a ticket by using the TicketID parameter' {
			$ticketID = $pstrTicketID;
			$entries = Get-CWTimeEntry -TicketID $ticketID;
			$pstrSharedValues.timeEntries += @($entries);
			$entries -ne $null | Should Be $true;
		} 
		
		It 'gets ticket and pipes it through the Select-Object cmdlet for the id property' {
			$entries = Get-CWTimeEntry -ID $pstrTimeEntryID;
			$entries | Select-Object -ExpandProperty id | Should Be $pstrTimeEntryID;		
		}
		
		It 'gets list of time entries that were piped to the cmdlet' {
			$entryIDs = $pstrTimeEntryIDs
			$entries = $entryIDs | Get-CWTimeEntry;
			$entries | Measure-Object | Select-Object -ExpandProperty Count | Should Be $entryIDs.Count;		
		}
		
		It 'gets tickets and sorts ticket id by descending piping cmdlet through Sort-Object cmdlet' {
			$ticketID = $pstrTicketID;
			$entries = [psobject[]] @(Get-CWTimeEntry -TicketID $ticketID | Sort-Object -Descending id);
			$maxTimeEntryId = $entries | Select-Object -ExpandProperty id| Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
			$entries[0].id | Should Be $maxTimeEntryId;
		}
		
		
	} # end of Context 'Get-CWTimeEntry'
	
		Context "Update-CWTimeEntry"  {
		
		$pstrTicketID     = $pstrGenSvc.ticketIds[0];
		$pstrTimeEntryID  = $pstrSharedValues.timeEntries[0].id;
		$pstrTimeEntryIDs = @($pstrSharedValues.timeEntries | Select-Object -ExpandProperty id);
	
		It "change the internal note of a ticket" {
			$ticketID = $pstrTicketID;
			$msg = "test";
			$ticket = Update-CWTimeEntry -ID $pstrTimeEntryID -InternalNote $msg;
			$ticket.internalnotes.Trim() -eq $msg.Trim() | Should Be $true; 
		}
		
		It "change the status of a ticket and set the board ID" {
			$start = (Get-Date).AddMinutes(-1);
			$end = (Get-Date)			
			$ticket = Update-CWTimeEntry -ID $pstrTimeEntryID -Start $start -End $end;
			$isStartValid = (Get-Date $ticket.timeStart).ToUniversalTime().ToString("yyyy-MM-ddThh:mm:ssZ") -eq (Get-Date $start).ToUniversalTime().ToString("yyyy-MM-ddThh:mm:ssZ") 
			$isEndValid = (Get-Date $ticket.timeEnd).ToUniversalTime().ToString("yyyy-MM-ddThh:mm:ssZ") -eq (Get-Date $end).ToUniversalTime().ToString("yyyy-MM-ddThh:mm:ssZ") 
			$isStartValid -and $isEndValid | Should Be $true; 
		}
		
		
	} # end of Context "Update-CWTimeEntry" 

	Context "Remove-CWTimeEntry"  {

		$pstrTicketID     = $pstrGenSvc.ticketIds[0];
		$pstrTimeEntryID  = $pstrSharedValues.timeEntries[0].id;
		$pstrTimeEntryIDs = @($pstrSharedValues.timeEntries | Select-Object -ExpandProperty id);
		
		It "deletes a ticket and check for a return value of true if successful with the WhatIf parameter" {
			$wasDeleted = Remove-CWTimeEntry -ID $pstrTimeEntryID -WhatIf;
			$wasDeleted | Should Be $true; 
		}
	
	}
	
		
} # end of Describe 'CWTimeEntry'