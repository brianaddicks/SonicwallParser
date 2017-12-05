function Resolve-SwField {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[object]$Policies,
		
		[Parameter(Mandatory=$True,Position=1)]
		[string]$Field,
		
		[Parameter(Mandatory=$True,Position=2)]
		[array]$ObjectTable
	)
	
	$VerbosePrefix = "Resolve-SwField:"
	Write-Verbose "$VerbosePrefix Field: $Field"
	$Field         = $Field.substring(0,1).toupper() + $Field.substring(1).tolower()
	$i             = 0
	$ReturnObject  = @()
	Write-Verbose "$VerbosePrefix Field: $Field"
	
	foreach ($Policy in $Policies) {
		$global:policytest = $Policy
		Write-Verbose "$VerbosePrefix Resolving `"$Field`" for Policy: $($Policy.SourceZone) -> $($Policy.DestinationZone): $($Policy.Number)"
		$i++
		$TotalCount                     = $Policies.Count
		$PercentComplete                = [math]::truncate($i / $TotalCount * 100)
		$ProgressParams                 = @{}
		$ProgressParams.PercentComplete = $PercentComplete
		$ProgressParams.Activity        = "Resolving $Field"
		$ProgressParams.Status          = "$PercentComplete% $i/$TotalCount"  
		$ProgressParams.ParentId        = $Global:SwPolicyId
		
		Write-Progress @ProgressParams
		
		$Properties = @()
		foreach ($Property in ($Policy | gm -MemberType *Property)) { $Properties += $Property.Name }
		if (!($Policy.$Field)) {
			Write-Verbose "Field not found: $Field"
		} else {
			$Properties += "$Field`Resolved"
		}
		
		$NewPolicy = "" | Select $Properties
		foreach ($Property in $Properties) { $NewPolicy.$Property = $Policy.$Property }
		if (!($Policy.$Field)) {
			$ReturnObject += $NewPolicy
			continue
		}
		
		$ResolvedField = Resolve-SwObject $Policy.$Field $ObjectTable
		if ($ResolvedField) {
			foreach ($r in $ResolvedField) {
				$NewPolicy                    = $NewPolicy.psobject.copy()
				$NewPolicy."$Field`Resolved"  = $r
				$ReturnObject                += $NewPolicy
			}
		} else {
			switch ($NewPolicy.$Field) {
				               'Any' { $NewPolicy."$Field`Resolved" = "any" }
					      'ORIGINAL' { $NewPolicy."$Field`Resolved" = "original" }
				{ $_ -match "IPv6" } { $NewPolicy."$Field`Resolved" = "ipv6" }
				             default { Throw "Unhandled value: $($NewPolicy.$Field)" }
			}
			$ReturnObject += $NewPolicy
		}
	}
	
	$ProgressParams.Completed = $true
	Write-Progress @$ProgressParams
	
	return $ReturnObject
}