# Give it a Version to help keep track v0.0.2
# Define the application name for the event log
$eventSource = "MyWindowsUpdates"
$eventLogName = "Application"

# Check if the event source exists, if not, create it
if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
    New-EventLog -LogName $eventLogName -Source $eventSource
    Write-Host "Event source '$eventSource' created."
}

# Import the PSWindowsUpdate module
Import-Module PSWindowsUpdate

# Log the start of the update process
Write-EventLog -LogName $eventLogName -Source $eventSource -EntryType Information -EventId 1001 -Message "Started checking for Windows updates."

# Check for available updates
$updates = Get-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose -Confirm:$false
Write-EventLog -LogName $eventLogName -Source $eventSource -EntryType Information -EventId 1002 -Message "Updates details: $($updates | Out-String)"

if ($updates) {
    Write-Host "Updates found. Beginning installation."
    
    # Log that updates were found and installation is starting 1003 update related activity
    Write-EventLog -LogName $eventLogName -Source $eventSource -EntryType Information -EventId 1003 -Message "Found updates. Beginning installation."    
    Install-WindowsUpdate -AcceptAll -Install -Verbose -IgnoreReboot -Confirm:$false 
    Write-EventLog -LogName $eventLogName -Source $eventSource -EntryType Information -EventId 1003 -Message "Finished installing updates."

    # Check if a reboot is required after installing updates
    $rebootRequired = $updates | Where-Object { $_.RebootRequired -eq $true }

    if ($rebootRequired) {
        # If a reboot is required log it with 1004 activity
        $rebootRequiredContent = $rebootRequired | Out-String
        Write-EventLog -LogName $eventLogName -Source $eventSource -EntryType Information -EventId 1004 -Message "Reboot required: $rebootRequiredContent"

        
        $rebootTimer = 5400  # set your timer in seconds here
		$rebootTime = (Get-Date).AddHours(1.5)  # This is so i can display reboot time in msg * to all users
		$formattedRebootTime = $rebootTime.ToString("hh:mm tt")  # Format as hh:mm AM/PM

        # Notify all users
        msg * /time:5400 "Reboot required. The computer will restart at $formattedRebootTime. You can choose to reboot earlier to avoid auto Reboot."
        Write-EventLog -LogName $eventLogName -Source $eventSource -EntryType Information -EventId 1004 -Message "Message sent to users about reboot at $formattedRebootTime."

        # Schedule the restart
        shutdown.exe /r /t $rebootTimer /c "Updates installed. Rebooting in 90 Minutes."

        # Log the scheduled reboot scheduled reboots 1005 activity
        Write-EventLog -LogName $eventLogName -Source $eventSource -EntryType Warning -EventId 1005 -Message "Reboot scheduled for $formattedRebootTime."
		wuauclt /reportnow #Throw a report out update related 1003
		Write-EventLog -LogName $eventLogName -Source $eventSource -EntryType Warning -EventId 1003 -Message "Report to WSUS Server"
    } else {
        Write-Host "No reboot required after updates." #no reboot is 1007 activity
        Write-EventLog -LogName $eventLogName -Source $eventSource -EntryType Information -EventId 1007 -Message "No reboot required after installing updates."
    }
} else {
    Write-Host "No updates available." #1008 no udpates found. 
    Write-EventLog -LogName $eventLogName -Source $eventSource -EntryType Information -EventId 1008 -Message "No updates available."
	wuauclt /reportnow #report out 
 Write-EventLog -LogName $eventLogName -Source $eventSource -EntryType Warning -EventId 1003 -Message "Report to WSUS Server"
}
