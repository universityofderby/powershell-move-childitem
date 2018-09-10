Function Move-ChildItem {
<#
.SYNOPSIS
Move child items of input path(s) to specified subdirectory.

.DESCRIPTION
Move child items of input path(s) to specified subdirectory.

.PARAMETER Path
One or more parent directories to move child items from.

.PARAMETER ChildPath
Subdirectory to move child items to.

.PARAMETER Exclude
Child items to exclude from being moved.

.PARAMETER LogPath
Log file path.

.PARAMETER LogToConsole
Enable/disable logging to console.

.PARAMETER LogToFile
Enable/disable logging to file.

.OUTPUTS
None

.EXAMPLE
PS> Get-ChildItem -Path '\\server\share' -Directory | Move-ChildItem
For each subdirectory of '\\server\share', move child items to '.\Documents'.

.EXAMPLE
PS> Get-ChildItem -Path '\\server\share' -Directory | Move-ChildItem -WhatIf
For each subdirectory of '\\server\share', list operations if child items were moved to '.\Documents'.

.EXAMPLE
PS> Move-ChildItem -Path (Get-Item 'C:\Dir1')
Move child items of 'C:\Dir1' to 'C:\Dir1\Documents'.

.EXAMPLE
PS> Move-ChildItem -Path (Get-Item 'C:\Dir1') -ChildPath 'Dir2'
Move child items of 'C:\Dir1' to 'C:\Dir1\Dir2'.

.EXAMPLE
PS> Move-ChildItem -Path (Get-Item 'C:\Dir1') -Exclude 'Documents','Music','Pictures'
Move child items of 'C:\Dir1' to "C:\Dir1\Documents", exclude directories matching 'Documents','Music','Pictures'.

.EXAMPLE
PS> Move-ChildItem -Path (Get-Item 'C:\Dir1') -WhatIf
List operations if child items of 'C:\Dir1' were moved to 'C:\Dir1\Documents'.

.EXAMPLE
PS> Move-ChildItem -Path (Get-Item 'C:\Dir1') -Confirm
Move child items of 'C:\Dir1' to 'C:\Dir1\Documents' with confirmation.

.EXAMPLE
PS> Move-ChildItem -Path (Get-Item 'C:\Dir1') -LogPath 'C:\Temp\Move-ChildItem.log'
Move child items of 'C:\Dir1' to 'C:\Dir1\Documents' with specific log file location.

.EXAMPLE
PS> Move-ChildItem -Path (Get-Item 'C:\Dir1') -LogToConsole $true
Move child items of 'C:\Dir1' to 'C:\Dir1\Documents' with logging to console enabled.

.NOTES
  Version: 0.2.0 - Add parameters to enable/disable logging to console/file
  Date: 2018-09-08

  Version: 0.1.0 - Initial version
  Date: 2018-09-07
  
  Author: Richard Lock

  Dependencies: Logging module (https://www.powershellgallery.com/packages/Logging/2.4.11)
#>

  # Support -WhatIf and -Confirm for cmdlet
  [CmdletBinding(SupportsShouldProcess=$true)]

  # Cmdlet parameters
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)] [System.IO.DirectoryInfo[]]$Path,   
    [Parameter()] [String]$ChildPath = 'Documents',
    [Parameter()] [String[]]$Exclude = @('.*','Desktop','Documents','Downloads','Favorites','Music','Pictures','Videos'),
    [Parameter()] [String]$LogPath = (Join-Path -Path (Get-Location) -ChildPath "Move-ChildItem_$(Get-Date -Format 'yyyy-MM-dd').log"),
    [Parameter()] [String]$LogToConsole = $false,
    [Parameter()] [String]$LogToFile = $true
  )
  
  Begin {
    Try {
      # Install Logging module
      Install-Module -Name Logging -Force
      # Set default logging level
      Set-LoggingDefaultLevel -Level 'INFO'
      # Enable/disable logging to console
      If ($LogToConsole) {
        Add-LoggingTarget -Name Console
      }
      # Enable/disable logging to file
      If ($LogToFile) {
        Add-LoggingTarget -Name File -Configuration @{Path = $LogPath}
      }
      # Start log
      Write-Log -Level 'INFO' -Message '*** Started execution ***'
      Write-Log -Level 'INFO' -Message "Excluded child items: $($Exclude -join ', ')"
    }
    Catch {
      Write-Warning "Exception while configuring logging: $($_.Exception.Message)"
      Exit
    }
  }
        
  Process {
    # Loop over each path
    $Path | ForEach-Object {
      $i++
      Write-Log -Level 'INFO' -Message "Path: $($_.FullName)"
      # Test if path is valid directory
      If (Test-Path -Path $_.FullName -PathType Container) {
        $destination = $null
        # Set destination directory
        $destination = Join-Path -Path $_.FullName -ChildPath $ChildPath
      
        # Test if destination directory exists
        If (-not(Test-Path -Path $destination)) {
          # Support -WhatIf for cmdlet
          If ($PSCmdlet.ShouldProcess("Destination: $destination", 'Create Directory')) {
            # Create new desintation directory if it doesn't exist
            Try {
              New-Item -Path $destination -ItemType Directory
              Write-Log -Level 'INFO' -Message "Created destination directory: $destination"
            }
            Catch {
              Write-Log -Level 'ERROR' -Message $_.Exception.Message
            }
          }
        }

        Write-Log -Level 'INFO' -Message "Started moving items from path: $($_.FullName) to destination: $destination"
        # Loop over each non-excluded child item of the directory
        Get-ChildItem -Path $Path.FullName -Exclude $Exclude -Force | ForEach-Object {
          # Support -WhatIf for cmdlet
          If ($PSCmdlet.ShouldProcess("Item: $_ Destination: $destination", 'Move Item')) {
            # Try moving child item to destination directory
            Try {
              $_ | Move-Item -Destination $destination
            }
            Catch {
              Write-Log -Level 'ERROR' -Message $_.Exception.Message
            }
          }
        }
        Write-Log -Level 'INFO' -Message "Finished moving items from path: $($_.FullName) to destination: $destination"
      }
      Write-Log -Level 'INFO' -Message "Total paths processed: $i"      
    }
  }

  End {
    # Finish log
    Write-Log -Level 'INFO' -Message '*** Finished execution ***'
    # Wait for logging to complete
    Wait-Logging
  }
}
