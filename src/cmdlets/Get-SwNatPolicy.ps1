function Get-SwNatPolicy {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-SwNatPolicy:"
	
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
		
		$Regex = [regex] '^#Network\ :\ NAT\ Policies_START$'
		$Match = HelperEvalRegex $Regex $line
		if ($Match) {
			$InSection = $true
			Write-Verbose "$VerbosePrefix Section Found"
			continue
		}
		
		if ($InSection) {
			
			###########################################################################################
			# Check for the Section close
			
			$Regex = [regex] '^#Network\ :\ NAT\ Policies_END$'
			$Match = HelperEvalRegex $Regex $line
			if ($Match) { 
				Write-Verbose "$VerbosePrefix Section End: $($Match.Value)"
				break
			}
			
			###########################################################################################
			# New Object
					
			$Regex = [regex] '^Index\ +:\ (\d+)'
			$Eval  = HelperEvalRegex $Regex $line -ReturnGroupNum 1
			if ($Eval) {
				$NewObject        = New-Object -TypeName SonicwallParser.NatPolicy
				$NewObject.Index  = [int]$Eval
				$ReturnObject    += $NewObject
			}
	
			if ($NewObject) {
				
				###########################################################################################
				# SpecialProperties
				$EvalParams = @{}
				$EvalParams.StringToEval   = $line
				
				# Enabled
				$EvalParams.Regex          = [regex] '^Enable\ NAT\ Policy\ +:\ (\d+)'
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval -eq '0') { $NewObject.Enabled = $false }
				if ($Eval -eq '1') { $NewObject.Enabled = $true  }
				
				# Builtin
				$EvalParams.Regex          = [regex] '^System Policy\ +:\ (\d+)'
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval -eq '0') { $NewObject.BuiltIn = $false }
				if ($Eval -eq '1') { $NewObject.BuiltIn = $true  }
				
				###########################################################################################
				# Regular Properties
				$EvalParams.VariableToUpdate = ([REF]$NewObject)
				$EvalParams.ReturnGroupNum   = 1
				$EvalParams.LoopName         = 'fileloop'
				
				# OriginalSource
				$EvalParams.ObjectProperty = "OriginalSource"
				$EvalParams.Regex          = [regex] "^Original\ Source\ +:\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# TranslatedSource
				$EvalParams.ObjectProperty = "TranslatedSource"
				$EvalParams.Regex          = [regex] "^Translated\ Source\ +:\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# OriginalDestination
				$EvalParams.ObjectProperty = "OriginalDestination"
				$EvalParams.Regex          = [regex] "^Original\ Destination\ +:\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# TranslatedDestination
				$EvalParams.ObjectProperty = "TranslatedDestination"
				$EvalParams.Regex          = [regex] "^Translated\ Destination\ +:\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# OriginalService
				$EvalParams.ObjectProperty = "OriginalService"
				$EvalParams.Regex          = [regex] "^Original\ Service\ +:\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# TranslatedService
				$EvalParams.ObjectProperty = "TranslatedService"
				$EvalParams.Regex          = [regex] "^Translated\ Service\ +:\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# InboundInterface
				$EvalParams.ObjectProperty = "InboundInterface"
				$EvalParams.Regex          = [regex] "^Inbound\ Interface\ +:\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# OutboundInterface
				$EvalParams.ObjectProperty = "OutboundInterface"
				$EvalParams.Regex          = [regex] "^Outbound\ Interface\ +:\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# Comment
				$EvalParams.ObjectProperty = "Comment"
				$EvalParams.Regex          = [regex] "^Comment\ +:\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams
				
				# Usage
				$EvalParams.ObjectProperty = "Usage"
				$EvalParams.Regex          = [regex] "^Usage\ +:\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams
			}
		}
	}	
	return $ReturnObject
}