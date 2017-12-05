function Get-SwServiceGroup {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-SwServiceGroup:"
	
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
		
		$Regex = [regex] '^--Service Group Table--$'
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
				$NewObject.Type         = "service-group"
				$ReturnObject          += $NewObject
			}
	
			if ($NewObject) {
				
				###########################################################################################
				# Bool Properties and Properties that need special processing
				# Eval Parameters for this section
				$EvalParams = @{}
				$EvalParams.StringToEval     = $line
				
				
				# Members (older firmware)
				$EvalParams.Regex          = [regex] '^\ +member\:\ Name:(.+?)(\ Handle)'
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval) { $NewObject.Members += $Eval }

				# Members (newer firmware)
				$EvalParams.Regex          = [regex] '^\ +member\:\ (.+)'
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval) {
					$MemberNames = $Eval.Split(',')
					Write-Verbose "$VerbosePrefix $Eval"
					foreach ($member in $MemberNames) {
						$NewMember = $member.Trim()
						if ($NewMember -ne "") {
							$NewObject.Members += $NewMember
						}
					}
				}
			}
		}
	}	
	return $ReturnObject
}