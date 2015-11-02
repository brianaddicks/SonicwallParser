function Get-SwServiceObject {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-SwServiceObject:"
	
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
		
		$Regex = [regex] '^--Service Object Table--$'
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
					
			$Regex = [regex] '-------(?<name>.+?)(\((?<description>.+?)\))?-------'
			$Match = HelperEvalRegex $Regex $line
			if ($Match) {
				$NewObject              = New-Object -TypeName SonicwallParser.FirewallObject
				$NewObject.Name         = $Match.Groups['name'].Value
				$NewObject.Description  = $Match.Groups['description'].Value
				$ReturnObject          += $NewObject
			}
	
			if ($NewObject) {
				
				###########################################################################################
				# Bool Properties and Properties that need special processing
				# Eval Parameters for this section
				$EvalParams = @{}
				$EvalParams.StringToEval     = $line
				
				
				# Protocol/Port
				$EvalParams.Regex          = [regex] "^IpType:\ (?<type>\d+),\ +Ports:\ (?<start>\d+)~(?<stop>\d+)" 
				$Eval                      = HelperEvalRegex @EvalParams
				if ($Eval) {
					$Protocol = $Eval.Groups['type'].Value
					$Start    = $Eval.Groups['start'].Value
					$Stop     = $Eval.Groups['stop'].Value
					
					$ProtocolHash = @{
						'6'   = 'tcp'
						'17'  = 'udp'
						'50'  = 'exp'
						'1'   = 'icmp'
						'108' = 'ipcomp'
						'41'  = 'ipv6'
						'47'  = 'gre'
					    '58'  = 'ipv6-icmp'
						'2'   = 'igmp'
					}
					
					$NewProtocol = $ProtocolHash.$Protocol
					if (!($NewProtocol)) { Throw "unknown protocol: $Protocol" }
					
					if ($Start -eq $Stop) {
						$Ports = $Start
					} else {
						$Ports = $Start + '-' + $Stop
					}
					
					$NewObject.Members = $NewProtocol + '/' + $Ports
				}
			}
		}
	}	
	return $ReturnObject
}