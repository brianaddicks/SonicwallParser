function Resolve-SwObject {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$Objects,
		
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
	
	$ReturnObject = @()
	
	foreach ($Object in $Objects) {
		$i++
		
		if ($StopWatch.Elapsed.TotalMilliseconds -ge 1000) {
			$PercentComplete = [math]::truncate($i / $Objects.Count * 100)
	        Write-Progress -Activity "Resolving Objects" -Status "$PercentComplete% $i/$($Object.Count)" -PercentComplete $PercentComplete
	        $StopWatch.Reset()
			$StopWatch.Start()
		}
		
		if ($Object.Members) {
			foreach ($Member in $Object.Members) {
				$ReturnObject += Resolve-SwObject $Member $ObjectTable
			}
		} else {
			$Lookup = $ObjectTable | ? { $_.Name -ceq $Object }
			if ($Lookup) {
				if ($Lookup.Members) {
					$ReturnObject += Resolve-SwObject $Lookup.Members $ObjectTable
				}
			} else {
				$ReturnObject += $Object
			}
		}
	}
	
	return $ReturnObject
}