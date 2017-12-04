function Get-SwAddressObject {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput,

		[Parameter(Mandatory=$False,Position=1)]
		[array]$AddressGroups
	)
	
	$VerbosePrefix = "Get-SwAddressObject:"
	
	$IpRx = [regex] "(\d+\.){3}\d+"
	
	$TotalLines = $ShowSupportOutput.Count
	$i          = 0 
	$StopWatch  = [System.Diagnostics.Stopwatch]::StartNew() # used by Write-Progress so it doesn't slow the whole function down
	
	$ReturnObject = @()
	
	:fileloop foreach ($line in $ShowSupportOutput) {
		$i++
		
		# Write progress bar, we're only updating every 1000ms, if we do it every line it takes forever
		
		if ($StopWatch.Elapsed.TotalMilliseconds -ge 1000) {
			$PercentComplete = [math]::truncate($i / $TotalLines * 100)
	        Write-Progress -Activity "Reading Support Output" -Status "$PercentComplete% $i/$TotalLines" -PercentComplete $PercentComplete
	        $StopWatch.Reset()
			$StopWatch.Start()
		}
		
		if ($line -eq "") { continue }
		
		###########################################################################################
		# Check for the Section
		
		$Regex = [regex] '^--Address Object Table--$'
		$Match = HelperEvalRegex $Regex $line
		if ($Match) {
			$InSection = $true
			Write-Verbose "$VerbosePrefix Section Found"
			continue
		}
		
		if ($InSection) {
			
			###########################################################################################
			# Check for the Section close
			
			$Regex = [regex] '^--[\w\ ]+?--$'
			$Match = HelperEvalRegex $Regex $line
			if ($Match) { 
				Write-Verbose "$VerbosePrefix Section End: $($Match.Value)"
				break
			}
			
			###########################################################################################
			# New Object
					
			$Regex = [regex] '^-------(?<name>.+?)((?<!\ )\((?<desc>.+)\)(?=-))?-------$'
			$Match = HelperEvalRegex $Regex $line
			if ($Match) {
				$NewObject              = New-Object -TypeName SonicwallParser.FirewallObject
				$NewObject.Name         = $Match.Groups['name'].Value
				$NewObject.Description  = $Match.Groups['description'].Value
				$NewObject.Type         = "address"
				$ReturnObject          += $NewObject
			}
	
			if ($NewObject) {
				
				###########################################################################################
				# Bool Properties and Properties that need special processing
				# Eval Parameters for this section
				$EvalParams = @{}
				$EvalParams.StringToEval     = $line
				
				
				# Host
				$EvalParams.Regex          = [regex] "^(?<type>HOST):\ (?<value>$IpRx)" 
				$Eval                      = HelperEvalRegex @EvalParams
				if ($Eval) {
					$NewObject.Members = $Eval.Groups['value'].Value + "/32"
				}
				
				# Network
				$EvalParams.Regex          = [regex] "^(?<type>NETWORK):\ (?<net>$IpRx)\ -\ (?<mask>$IpRx)"
				$Eval                      = HelperEvalRegex @EvalParams
				if ($Eval) {
					$NewObject.Members = $Eval.Groups['net'].Value + '/' + (ConvertTo-MaskLength $Eval.Groups['mask'].Value)
				}
				
				# FQDN
				$EvalParams.Regex          = [regex] "^(?<type>FQDN):\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval) {
					$NewObject.Members = $Eval
				}
				
				# Range
				$EvalParams.Regex          = [regex] "^(?<type>RANGE):\ (?<start>$IpRx)\ -\ (?<stop>$IpRx)"
				$Eval                      = HelperEvalRegex @EvalParams
				if ($Eval) {
					$NewObject.Members = $Eval.Groups['start'].Value + '-' + $Eval.Groups['stop'].Value
				}

				# Check for Group Membership

				if ($AddressGroups) {
					# Host
					$EvalParams.Regex          = [regex] "^\ +Group\ \(Member\ of\):\ +(.+)," 
					$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
					if ($Eval) {
						$GroupLookup = $AddressGroups | Where-Object { $_.Name -eq $Eval }
						if ($GroupLookup) {
							$GroupLookup.Members += $Eval
						} else {
							Throw "$VerbosePrefix Group Lookup Failed for $($NewObject.Name): $Eval"
						}
					}

				}
			}
		}
	}	
	return $ReturnObject
}