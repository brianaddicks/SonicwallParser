[CmdletBinding()]
<#
    .SYNOPSIS
        Runs basic analysis on Sonicwall tech support file.
#>

Param (
    [Parameter(Mandatory=$True,Position=0)]
    [array]$ShowSupportOutput
)



$AccessPolicies = Get-SwAccessPolicy  -ShowSupportOutput $ShowSupportOutput
$AddressGroups  = Get-SwAddressGroup  -ShowSupportOutput $ShowSupportOutput
$AddressObjects = Get-SwAddressObject -ShowSupportOutput $ShowSupportOutput
$NatPolicies    = Get-SwNatPolicy     -ShowSupportOutput $ShowSupportOutput
$ServiceObjects = Get-SwServiceObject -ShowSupportOutput $ShowSupportOutput
$ServiceGroups  = Get-SwServiceGroup  -ShowSupportOutput $ShowSupportOutput
$AllObjects     = $AddressGroups + $AddressObjects + $ServiceGroups + $ServiceObjects

$ResolvedAccessPolicies = Resolve-SwPolicy -Policies $AccessPolicies -ObjectTable $AllObjects
$ResolvedNatPolicies    = Resolve-SwPolicy -Policies $NatPolicies -ObjectTable $AllObjects