function Resolve-SwPolicy {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$Policies,
		
		[Parameter(Mandatory=$True,Position=1)]
		[array]$ObjectTable
	)
	
	$VerbosePrefix = "Resolve-SwPolicy:"
	
	$i          = 0 
	
	switch ($Policies[0].GetType().Name) {
		AccessPolicy {
			$Fields = @(
				"Source"
				"Destination"
				"SourceService"
				"DestinationService"
			)
			Write-Verbose "$VerbosePrefix Resolving AccessPolicies"
		}
		NatPolicy {
			$Fields = @(
				"OriginalSource"
				"TranslatedSource"
				"OriginalDestination"
				"TranslatedDestination"
				"OriginalService"
				"TranslatedService"
			)
			Write-Verbose "$VerbosePrefix Resolving NatPolicies"
		}
		default {
			Throw "Array must contain objects of type NatPolicy or AccessPolicy"
		}
	}
	
	$Global:SwPolicyId = Get-Random
	foreach ($Field in $Fields) {
		Write-Verbose "$VerbosePrefix Resolving Field: $Field"
		$i++
		$TotalCount                     = $Fields.Count
		$PercentComplete                = [math]::truncate($i / $TotalCount * 100)
		$ProgressParams                 = @{}
		$ProgressParams.PercentComplete = $PercentComplete
		$ProgressParams.Activity        = "Resolving $Field"
		$ProgressParams.Status          = "$PercentComplete% $i/$TotalCount"
		
		$ProgressParams.Id              = $Global:SwPolicyId
		
		Write-Progress @ProgressParams
		
		if ($i -eq 1) {
			$ReturnObject = Resolve-SwField $Policies $Field $ObjectTable
		} else {
			$ReturnObject = Resolve-SwField $ReturnObject $Field $ObjectTable
		}
	}
	
	
	return $ReturnObject
}