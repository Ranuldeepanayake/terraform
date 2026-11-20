<#
.SYNOPSIS
Removes Terraform provider caches and dependency lock files under this repository.

.DESCRIPTION
Scans the repository containing this script and its downstream directories.
Only directories named ".terraform\providers" and files named
".terraform.lock.hcl" are cleanup targets. The containing ".terraform"
directory and all its other contents, including state files, are preserved.
Symbolic links and junctions are not traversed or removed.
Reports the total logical size of files in the cleanup targets before cleanup.

.PARAMETER DryRun
Logs the cleanup actions that would be performed without deleting anything.

.EXAMPLE
.\cleanup-terraform-cache.ps1 -DryRun

.EXAMPLE
If PowerShell blocks script execution, allow scripts for the current process
only, then run the dry run:

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\cleanup-terraform-cache.ps1 -DryRun

.EXAMPLE
.\cleanup-terraform-cache.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0

# Writes timestamped messages consistently for scans, estimates, and cleanup.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$timestamp] [$Level] $Message"
}

# Confirms a candidate is a descendant of the repository, not the root or a sibling.
function Test-PathWithinRepository {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$RepositoryRoot
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $rootPrefix = $RepositoryRoot.TrimEnd('\') + '\'
    # The trailing separator prevents similarly prefixed sibling paths from matching.
    return $fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)
}

# Totals file lengths without following links, so the estimate stays within the target.
function Get-TargetSizeBytes {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Target
    )

    if ($Target.Type -eq 'dependency lock file') {
        return [long](Get-Item -LiteralPath $Target.Path -Force -ErrorAction Stop).Length
    }

    $totalBytes = [long]0
    $directories = [System.Collections.Generic.Stack[string]]::new()
    $directories.Push($Target.Path)

    # Use an explicit stack to walk nested cache directories without recursive calls.
    while ($directories.Count -gt 0) {
        $directory = $directories.Pop()
        foreach ($item in Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop) {
            # Linked items may point outside the repository; neither count nor traverse them.
            $isReparsePoint = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
            if ($isReparsePoint) {
                continue
            }

            if ($item.PSIsContainer) {
                $directories.Push($item.FullName)
            }
            else {
                $totalBytes += [long]$item.Length
            }
        }
    }

    return $totalBytes
}

# Converts a byte count to a readable base-1024 unit for log output.
function Format-ByteCount {
    param(
        [Parameter(Mandatory = $true)]
        [long]$Bytes
    )

    $size = [double]$Bytes
    $units = @('B', 'KB', 'MB', 'GB', 'TB')
    $unitIndex = 0
    while ($size -ge 1024 -and $unitIndex -lt ($units.Count - 1)) {
        $size /= 1024
        $unitIndex++
    }

    return '{0:N2} {1}' -f $size, $units[$unitIndex]
}

try {
    $repositoryRoot = [System.IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')
    if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot '.git'))) {
        throw "The script directory is not a Git repository root: $repositoryRoot"
    }

    # PowerShell's -WhatIf also activates the no-change path, even without -DryRun.
    $effectiveDryRun = $DryRun -or $WhatIfPreference
    Write-Log -Level INFO -Message "Repository root: $repositoryRoot"
    if ($effectiveDryRun) {
        Write-Log -Level INFO -Message 'Dry run enabled; no files or directories will be removed.'
    }
    Write-Log -Level INFO -Message 'Terraform state and all files outside the two explicit target types are protected.'

    $directoriesToVisit = [System.Collections.Generic.Stack[string]]::new()
    $directoriesToVisit.Push($repositoryRoot)
    $targets = [System.Collections.Generic.List[object]]::new()
    $sizeEstimateComplete = $true

    while ($directoriesToVisit.Count -gt 0) {
        $currentDirectory = $directoriesToVisit.Pop()

        try {
            $children = Get-ChildItem -LiteralPath $currentDirectory -Force -ErrorAction Stop
        }
        catch {
            $script:ErrorCount++
            $sizeEstimateComplete = $false
            Write-Log -Level ERROR -Message "Could not scan '$currentDirectory': $($_.Exception.Message)"
            continue
        }

        foreach ($child in $children) {
            # Reparse points include symbolic links and junctions; don't traverse them.
            $isReparsePoint = ($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0

            if ($child.PSIsContainer) {
                # Git metadata is unrelated and can contain large or linked internal data.
                if ($child.Name -eq '.git') {
                    continue
                }

                if ($child.Name -eq '.terraform') {
                    if ($isReparsePoint) {
                        Write-Log -Level WARN -Message "Skipping linked .terraform directory: $($child.FullName)"
                        continue
                    }

                    # Target only the providers child; leave state and all other cache contents untouched.
                    $providersPath = Join-Path $child.FullName 'providers'
                    if (Test-Path -LiteralPath $providersPath) {
                        try {
                            $providersItem = Get-Item -LiteralPath $providersPath -Force -ErrorAction Stop
                            $providersIsLink = ($providersItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0

                            if ($providersItem.PSIsContainer -and -not $providersIsLink) {
                                if (Test-PathWithinRepository -Path $providersItem.FullName -RepositoryRoot $repositoryRoot) {
                                    $targets.Add([pscustomobject]@{
                                        Type = 'provider cache'
                                        Path = $providersItem.FullName
                                    })
                                }
                                else {
                                    $script:ErrorCount++
                                    $sizeEstimateComplete = $false
                                    Write-Log -Level ERROR -Message "Refusing target outside the repository: $($providersItem.FullName)"
                                }
                            }
                            elseif ($providersIsLink) {
                                Write-Log -Level WARN -Message "Skipping linked providers directory: $($providersItem.FullName)"
                            }
                        }
                        catch {
                            $script:ErrorCount++
                            $sizeEstimateComplete = $false
                            Write-Log -Level ERROR -Message "Could not inspect '$providersPath': $($_.Exception.Message)"
                        }
                    }

                    # Do not recurse into .terraform: state and other working data are out of scope.
                    continue
                }

                if ($isReparsePoint) {
                    Write-Log -Level WARN -Message "Skipping linked directory: $($child.FullName)"
                    continue
                }

                $directoriesToVisit.Push($child.FullName)
                continue
            }

            if ($child.Name -eq '.terraform.lock.hcl') {
                if ($isReparsePoint) {
                    Write-Log -Level WARN -Message "Skipping linked lock file: $($child.FullName)"
                    continue
                }

                if (Test-PathWithinRepository -Path $child.FullName -RepositoryRoot $repositoryRoot) {
                    $targets.Add([pscustomobject]@{
                        Type = 'dependency lock file'
                        Path = $child.FullName
                    })
                }
                else {
                    $script:ErrorCount++
                    $sizeEstimateComplete = $false
                    Write-Log -Level ERROR -Message "Refusing target outside the repository: $($child.FullName)"
                }
            }
        }
    }

    Write-Log -Level INFO -Message "Found $($targets.Count) cleanup target(s)."
    $reclaimableBytes = [long]0
    # Measure all targets before deleting any, so the estimate covers the full planned cleanup.
    foreach ($target in $targets) {
        try {
            $reclaimableBytes += Get-TargetSizeBytes -Target $target
        }
        catch {
            $script:ErrorCount++
            $sizeEstimateComplete = $false
            Write-Log -Level ERROR -Message "Could not measure '$($target.Path)': $($_.Exception.Message)"
        }
    }

    if ($sizeEstimateComplete) {
        Write-Log -Level INFO -Message "Estimated reclaimable file size: $(Format-ByteCount -Bytes $reclaimableBytes) ($reclaimableBytes bytes)."
    }
    else {
        # Report partial totals explicitly rather than presenting them as a complete estimate.
        Write-Log -Level WARN -Message "Partial reclaimable file-size estimate: $(Format-ByteCount -Bytes $reclaimableBytes) ($reclaimableBytes bytes); one or more paths could not be fully scanned or measured."
    }

    foreach ($target in $targets) {
        if ($effectiveDryRun) {
            Write-Log -Level INFO -Message "Would remove $($target.Type): $($target.Path)"
            continue
        }

        if (-not $PSCmdlet.ShouldProcess($target.Path, "Remove $($target.Type)")) {
            continue
        }

        try {
            Remove-Item -LiteralPath $target.Path -Recurse -Force -ErrorAction Stop
            Write-Log -Level INFO -Message "Removed $($target.Type): $($target.Path)"
        }
        catch {
            $script:ErrorCount++
            Write-Log -Level ERROR -Message "Failed to remove '$($target.Path)': $($_.Exception.Message)"
        }
    }

    if ($script:ErrorCount -gt 0) {
        Write-Log -Level ERROR -Message "Completed with $($script:ErrorCount) error(s)."
        throw 'Cleanup did not complete successfully.'
    }

    if ($effectiveDryRun) {
        Write-Log -Level INFO -Message 'Dry run completed; no changes were made.'
    }
    else {
        Write-Log -Level INFO -Message 'Cleanup completed successfully.'
    }
}
catch {
    Write-Log -Level ERROR -Message $_.Exception.Message
    exit 1
}
