#Requires -Version 5.0

using namespace System

Set-StrictMode -Version Latest


#region Public functions


function New-TestV5SemVer {
    [cmdletbinding()]
    param ()

    New-Object -TypeName PoShSemanticVersion
}


#endregion Public functions


#region Classes


class PoShSemanticVersion : IComparable {
    [ValidateRange(0, 2147483647)]
    [int32] $Major

    [ValidateRange(0, 2147483647)]
    [int32] $Minor

    [ValidateRange(0, 2147483647)]
    [int32] $Patch

    # A string.
    #[ValidatePattern('^(|(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)$')]
    [ValidatePattern('^(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)$')]
    [string[]]
    $PreRelease

    # A string.
    #[ValidatePattern('^(|([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))$')]
    [ValidatePattern('^([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)$')]
    [string[]]
    $Build

    PoshSemanticVersion()
    {
        $this.Major = 0
        $this.Minor = 0
        $this.Patch = 0
        $this.PreRelease = @()
        $this.Build = @()
    }

    [int] CompareTo([object] $obj)
    {
        if ($obj -eq $null)
        {
            return -1
        }
        elseif ($this.Major -gt $obj.Major)
        {
            return 1
        }
        elseif ($this.Major -lt $obj.Major)
        {
            return -1
        }
        elseif ($this.Minor -gt $obj.Minor)
        {
            return 1
        }
        elseif ($this.Minor -lt $obj.Minor)
        {
            return -1
        }
        elseif ($this.Patch -gt $obj.Patch)
        {
            return 1
        }
        elseif ($this.Patch -lt $obj.Patch)
        {
            return -1
        }
        elseif ($this.PreRelease.Count -eq 0 -and ($obj.PreRelease.Count -gt 0))
        {
            return 1
        }
        elseif ($this.PreRelease.Count -gt 0 -and ($obj.PreRelease.Count -eq 0))
        {
            return -1
        }
        elseif ($this.PreRelease.Count -gt 0 -and ($obj.PreRelease.Count -gt 0))
        {
            [int] $leastIdentifiers = $this.PreRelease.Count
            if ($obj.PreRelease.Count -lt $leastIdentifiers)
            {
                $leastIdentifiers = $obj.PreRelease.Count
            }

            for ([int] $i = 0; $i -lt $leastIdentifiers; $i++)
            {
                if ($this.PreRelease[$i] -gt $obj.PreRelease[$i])
                {
                    return 1
                }
                elseif ($this.PreRelease[$i] -lt $obj.PreRelease[$i])
                {
                    return -1
                }
            }

            if ($this.PreRelease.Count -gt $obj.PreRelease.Count)
            {
                return 1
            }
            elseif ($this.PreRelease.Count -lt $obj.PreRelease.Count)
            {
                return -1
            }
        }

        return 0
    }

    [bool] Equals([object] $obj)
    {
        if ($this.CompareTo($obj) -eq 0) {
            return $true
        }
        else
        {
            return $false
        }
    }

    [string] ToString()
    {
        [string] $returnValue = '{0}.{1}.{2}{3}{4}' -f $this.Major,$this.Minor,$this.Patch,$(if ($this.PreRelease.Count -ne 0) {'-{0}' -f ($this.PreRelease -join '.')} else {''}),$(if ($this.Build.Count -ne 0) {'+{0}' -f ($this.Build -join '.')} else {''})

        return $returnValue
    }
}


#endregion Classes


#Export-ModuleMember -Function *

Set-StrictMode -Off