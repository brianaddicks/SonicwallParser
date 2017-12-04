function Get-SwAccessPolicy {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-SwAccessPolicy:"
	
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
		
		$Regex = [regex] '^#Firewall\ :\ Access\ Rules_START$'
		$Match = HelperEvalRegex $Regex $line
		if ($Match) {
			$InSection = $true
			Write-Verbose "$VerbosePrefix Section Found"
			continue
		}
		
		if ($InSection) {
			
			###########################################################################################
			# Check for the Section close
			
			$Regex = [regex] '^#Firewall\ :\ Access\ Rules_END$'
			$Match = HelperEvalRegex $Regex $line
			if ($Match) { 
				Write-Verbose "$VerbosePrefix Section End: $($Match.Value)"
				break
			}
			
			###########################################################################################
			# Zones
			
			$Regex = [regex] '^From\ (?<source>\w+)\ To\ (?<dest>\w+)'
			$Eval  = HelperEvalRegex $Regex $line
			if ($Eval) {
				$SourceZone      = $Eval.Groups['source'].Value
				$DestinationZone = $Eval.Groups['dest'].Value
			}
			
			###########################################################################################
			# New Object
					
			$Regex = [regex] '^Rule\ (?<number>\d+)\ (?<action>\w+)\ Service\ (?<source>.+?)(\ -\>)\ (?<service>.+?)(\ \((?<status>\w+)\))$'
			$Eval  = HelperEvalRegex $Regex $line
			if ($Eval) {
				$NewObject                     = New-Object -TypeName SonicwallParser.AccessPolicy
				$ReturnObject                 += $NewObject
				$NewObject.Number              = $Eval.Groups['number'].Value
				$NewObject.Action              = $Eval.Groups['action'].Value
				$NewObject.SourceService       = $Eval.Groups['source'].Value
				$NewObject.DestinationService  = $Eval.Groups['service'].Value
				
				$Status = $Eval.Groups['status'].Value
				switch ($Status) {
					Enabled  { $Status = $true }
					Disabled { $Status = $false }
					default  { Throw "unknown status on line $i : $Status"}
				}
				$NewObject.Enabled             = $Status
				
				$NewObject.SourceZone          = $SourceZone
				$NewObject.DestinationZone     = $DestinationZone
			}
	
			if ($NewObject) {
				
				###########################################################################################
				# SpecialProperties
				$EvalParams = @{}
				$EvalParams.StringToEval   = $line
				
				# Source/Destination
				$EvalParams.Regex = [regex] '^\ +?IP:\ (?<source>.+?)(\ -\>)\ (?<destination>.+?)(\ +Iface)'
				$Eval             = HelperEvalRegex @EvalParams
				if ($Eval) {
					$NewObject.Source      = $Eval.Groups['source'].Value
					$NewObject.Destination = $Eval.Groups['destination'].Value
				}
				
				# Bytes Tx/Rx
				$EvalParams.Regex = [regex] '^Bytes,\ Packets:\ +Rx:\ (?<rx>\d+),\ \d+\ +Tx:\ (?<tx>\d+)'
				$Eval             = HelperEvalRegex @EvalParams
				if ($Eval) {
					$NewObject.BytesRx = $Eval.Groups['rx'].Value
					$NewObject.BytesTx = $Eval.Groups['tx'].Value
				}
				
				###########################################################################################
				# Regular Properties
				$EvalParams.VariableToUpdate = ([REF]$NewObject)
				$EvalParams.ReturnGroupNum   = 1
				$EvalParams.LoopName         = 'fileloop'
					
				# Comment
				$EvalParams.ObjectProperty = "Comment"
				$EvalParams.Regex          = [regex] "^Comment:\ +?(.+)"
				$Eval                      = HelperEvalRegex @EvalParams
				
				<#
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
				#>
			}
		}
	}	
	return $ReturnObject
}