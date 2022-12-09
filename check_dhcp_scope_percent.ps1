#Edited by @wetcoriginal for Centreon
#usage : ./check_dhcp_scope.ps1 -Warning 60 -Critical 80
#Adjust value of warning and critical to meet your needs
#Value are in percentage

Param (
	[ValidateRange(0,100)][Int]
	$Warning = 80,
	
	[ValidateRange(0,100)][Int]
	$Critical = 90
)

$Message = ""

$IsWarning  = 0
$IsCritical = 0

$ActiveScopes = Get-DhcpServerv4Scope | Where { $_.State -eq 'Active' }

# Initialize the counts for each status
$global:WarningCount = 0
$global:CriticalCount = 0
$global:OkCount = 0

if ($ActiveScopes) {
	$ActiveScopes | Foreach {
		$Scope = $_
		$Stats = Get-DhcpServerv4ScopeStatistics $Scope.ScopeId
		
		    $Used = [Int] $Stats.PercentageInUse
    $Free = [Int] $Stats.Free

    # Check if scope is in critical status
    if ($Used -ge $Critical) {
        $IsCritical = $IsCritical + 1
        $Message += "CRITICAL - $($Scope.Name) is ($Used% used, $Free IP's available)`n"
        # Increment the count for the CRITICAL status
        $global:CriticalCount++
    }
    # Check if scope is in warning status and not critical
    elseif ($Used -ge $Warning) {
        $IsWarning = $IsWarning + 1
        $Message += "WARNING - $($Scope.Name) is ($Used% used, $Free IP's available)`n"
        # Increment the count for the WARNING status
        $global:WarningCount++
    }
    # If the scope is not in WARNING or CRITICAL status, it must be OK
    # but we will not display any information about it
    else {
        # Increment the count for the OK status
        $global:OkCount++
		}
	}
}

# Calculate the total number of scopes
$TotalCount = $global:WarningDisabledCount + $global:WarningCount + $global:CriticalCount + $global:OkCount

if ($Message) {
	$output = $Message | Out-String
}

if ($IsCritical -gt 0) {
	# Set the exit code to 2 if there are any CRITICAL scopes
	$global:ExitCode = 2
}
elseif ($IsWarning -gt 0) {
	# Set the exit code to 1 if there are any WARNING scopes
	$global:ExitCode = 1
}
else {
	# If there are no WARNING or CRITICAL scopes, the exit code is 0
	$global:ExitCode = 0
}


#Ajout du nombre total d'erreur détectés
$TotalCount=$global:WarningCount + $global:CriticalCount + $global:OkCount
$global:OutMessage="TOTAL=>" + $TotalCount + " / OK=>" + $global:OkCount + " / CRITICAL=>" + $global:CriticalCount + " / WARNING=>" + $global:WarningCount
$global:OutMessage+="`r`n"



Write-Output $global:OutMessage
Write-Output $output
exit $global:ExitCode

