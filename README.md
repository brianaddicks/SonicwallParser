# SonicwallParser

## Usage Example
```
$Config = gc $PathToConfigFile

$Objects  = Get-SwAddressGroup  $Config
$Objects += Get-SwAddressObject $Config
$Objects += Get-SwServiceGroup  $Config
$Objects += Get-SwServiceObject $Config

$AccessPolicies = Get-SwAccessPolicy $Config
$NatPolicies    = Get-SwNatPolicy    $Config

Resolve-SwPolicy $AccessPolicies $Objects | Export-csv $PathToExport -NoType
Resolve-SwPolicy $NatPolicies $Objects | Export-csv $PathToExport -NoType
```

### Known Limitations
* No support for IPv6 objects, frankly, it's unlikely I'll ever use this support myself

### Tested with Versions
* SonicOS Enhanced 6.2.2.1-14n
