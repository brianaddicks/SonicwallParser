function Resolve-SwObject {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[string]$ObjectName,
		
		[Parameter(Mandatory=$True,Position=1)]
		[array]$ObjectTable
	)
	
	$VerbosePrefix = "Resolve-SwObject:"
	
	$IpRx     = [regex] "(\d+\.){3}\d+"
	$IpMaskRx = [regex] "$IpRx\/\d+"
	$FqdnRx   = [regex] "([a-zA-Z0-9\-]+\.)+[a-zA-Z0-9\-]+"

	$TotalLines = $ShowSupportOutput.Count
	$i          = 0 
	$StopWatch  = [System.Diagnostics.Stopwatch]::StartNew() # used by Write-Progress so it doesn't slow the whole function down
	$ParentId   = Get-Random
	
	$ReturnObject = @()
	
	$Lookup = $ObjectTable | ? { $_.Name -ceq $ObjectName }
	switch ($Lookup.Type) {
		{ $_ -match '-group' } {
			foreach ($Member in $Lookup.Members) {
				$ReturnObject += Resolve-SwObject $Member $ObjectTable
			}
		}
		default {
			if ($Lookup.Members) {
				$ReturnObject += $Lookup.Members
			}
		} 
	}
	
	return $ReturnObject
}