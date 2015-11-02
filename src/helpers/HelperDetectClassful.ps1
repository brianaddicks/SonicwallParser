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