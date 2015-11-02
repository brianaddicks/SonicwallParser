###############################################################################
## Start Powershell Cmdlets
###############################################################################

###############################################################################
# Get-SwAccessPolicy

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
					
			$Regex = [regex] '^Rule\ (?<number>\d+)\ (?<action>\w+)\ Service\ (?<source>.+?)(\ -\>)\ (?<service>.+?)(\ \((?<status>\w+)\))'
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
					default  { Throw "unknown status: $Status"}
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

###############################################################################
# Get-SwAddressGroup

function Get-SwAddressGroup {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
	)
	
	$VerbosePrefix = "Get-SwAddressGroup:"
	
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
		
		$Regex = [regex] '^--Address Group Table--$'
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
				
				
				# DhcpRelayEnabled
				$EvalParams.Regex          = [regex] '^\ +member\:\ Name:(.+?)(\ Handle)'
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval) { $NewObject.Members += $Eval }
				
			}
		}
	}	
	return $ReturnObject
}

###############################################################################
# Get-SwAddressObject

function Get-SwAddressObject {
    [CmdletBinding()]
	<#
        .SYNOPSIS
            Gets Interface Info from Hp Switch Configuration
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[array]$ShowSupportOutput
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
				
				
				# Host
				$EvalParams.Regex          = [regex] "^HOST:\ (?<value>$IpRx)" 
				$Eval                      = HelperEvalRegex @EvalParams
				if ($Eval) {
					$NewObject.Members = $Eval.Groups['value'].Value + "/32"
				}
				
				# Network
				$EvalParams.Regex          = [regex] "^NETWORK:\ (?<net>$IpRx)\ -\ (?<mask>$IpRx)" 
				$Eval                      = HelperEvalRegex @EvalParams
				if ($Eval) {
					$NewObject.Members = $Eval.Groups['net'].Value + '/' + (ConvertTo-MaskLength $Eval.Groups['mask'].Value)
				}
				
				# FQDN
				$EvalParams.Regex          = [regex] "^FQDN:\ (.+)"
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval) {
					$NewObject.Members = $Eval
				}
			}
		}
	}	
	return $ReturnObject
}

###############################################################################
# Get-SwNatPolicy

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

###############################################################################
# Get-SwServiceGroup

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
				
				
				# DhcpRelayEnabled
				$EvalParams.Regex          = [regex] '^\ +member\:\ Name:(.+?)(\ Handle)'
				$Eval                      = HelperEvalRegex @EvalParams -ReturnGroupNum 1
				if ($Eval) { $NewObject.Members += $Eval }
			}
		}
	}	
	return $ReturnObject
}

###############################################################################
# Get-SwServiceObject

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

###############################################################################
# Resolve-SwObject

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

###############################################################################
## Start Helper Functions
###############################################################################

###############################################################################
# HelperDetectClassful

function HelperDetectClassful {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True,Position=0,ParameterSetName='RxString')]
		[ValidatePattern("(\d+\.){3}\d+")]
		[String]$IpAddress
	)
	
	$VerbosePrefix = "HelperDetectClassful: "
	
	$Regex = [regex] "(?x)
					  (?<first>\d+)\.
					  (?<second>\d+)\.
					  (?<third>\d+)\.
					  (?<fourth>\d+)"
						  
	$Match = HelperEvalRegex $Regex $IpAddress
	
	$First  = $Match.Groups['first'].Value
	$Second = $Match.Groups['second'].Value
	$Third  = $Match.Groups['third'].Value
	$Fourth = $Match.Groups['fourth'].Value
	
	$Mask = 32
	if ($Fourth -eq "0") {
		$Mask -= 8
		if ($Third -eq "0") {
			$Mask -= 8
			if ($Second -eq "0") {
				$Mask -= 8
			}
		}
	}
	
	return "$IpAddress/$([string]$Mask)"
}

###############################################################################
# HelperEvalRegex

function HelperEvalRegex {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True,Position=0,ParameterSetName='RxString')]
		[String]$RegexString,
		
		[Parameter(Mandatory=$True,Position=0,ParameterSetName='Rx')]
		[regex]$Regex,
		
		[Parameter(Mandatory=$True,Position=1)]
		[string]$StringToEval,
		
		[Parameter(Mandatory=$False)]
		[string]$ReturnGroupName,
		
		[Parameter(Mandatory=$False)]
		[int]$ReturnGroupNumber,
		
		[Parameter(Mandatory=$False)]
		$VariableToUpdate,
		
		[Parameter(Mandatory=$False)]
		[string]$ObjectProperty,
		
		[Parameter(Mandatory=$False)]
		[string]$LoopName
	)
	
	$VerbosePrefix = "HelperEvalRegex: "
	
	if ($RegexString) {
		$Regex = [Regex] $RegexString
	}
	
	if ($ReturnGroupName) { $ReturnGroup = $ReturnGroupName }
	if ($ReturnGroupNumber) { $ReturnGroup = $ReturnGroupNumber }
	
	$Match = $Regex.Match($StringToEval)
	if ($Match.Success) {
		#Write-Verbose "$VerbosePrefix Matched: $($Match.Value)"
		if ($ReturnGroup) {
			#Write-Verbose "$VerbosePrefix ReturnGroup"
			switch ($ReturnGroup.Gettype().Name) {
				"Int32" {
					$ReturnValue = $Match.Groups[$ReturnGroup].Value.Trim()
				}
				"String" {
					$ReturnValue = $Match.Groups["$ReturnGroup"].Value.Trim()
				}
				default { Throw "ReturnGroup type invalid" }
			}
			if ($VariableToUpdate) {
				if ($VariableToUpdate.Value.$ObjectProperty) {
					#Property already set on Variable
					continue $LoopName
				} else {
					$VariableToUpdate.Value.$ObjectProperty = $ReturnValue
					Write-Verbose "$ObjectProperty`: $ReturnValue"
				}
				continue $LoopName
			} else {
				return $ReturnValue
			}
		} else {
			return $Match
		}
	} else {
		if ($ObjectToUpdate) {
			return
			# No Match
		} else {
			return $false
		}
	}
}

###############################################################################
# HelperTestVerbose

function HelperTestVerbose {
[CmdletBinding()]
param()
    [System.Management.Automation.ActionPreference]::SilentlyContinue -ne $VerbosePreference
}

###############################################################################
## Export Cmdlets
###############################################################################

Export-ModuleMember *-*
