function Get-NewFileDirName {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$DataObject,
        [object]$Settings
    )

    begin {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Function started"
        $folderFormat = $settings.General.'rename-folder-string'
        $fileFormat = $settings.General.'rename-file-string'
        $displayNameFormat = $settings.General.'cms-displayname-string'
        $fileDirObject = @()
    }

    process {
        $newFolderName       = Convert-FormatString -FormatString $folderFormat
        $newDisplayName      = Convert-FormatString -FormatString $displayNameFormat -DisplayName
        $originalNewFileName = Convert-FormatString -FormatString $fileFormat

        if ($null -ne $DataObject.PartNumber) {
            $newFileName = $originalNewFileName + "-pt$($dataObject.PartNumber)"
        } else {
            $newFileName = $originalNewFileName
        }

        $fileDirObject = [pscustomobject]@{
            FolderName       = $newFolderName
            FileName         = $newFileName
            OriginalFileName = $originalNewFileName
            DisplayName      = $newDisplayName
        }

        Write-Output $fileDirObject
    }

    end {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}

function Convert-FormatString {
    param (
        [string]$FormatString,
        [switch]$DisplayName
    )

    begin {
        $invalidSymbols = @(
            '\',
            '/',
            ':',
            '*',
            '?',
            '"',
            '<',
            '>',
            '|',
            "'"
        )
    }

    process {
        $title = $DataObject.Title
        $studio = $DataObject.Maker

        # Remove invalid Windows filename symbols from title
        foreach ($symbol in $invalidSymbols) {
            if ([regex]::Escape($symbol) -eq '/') {
                $title = $title -replace [regex]::Escape($symbol), '-'
                $studio = $studio -replace [regex]::Escape($symbol), '-'
            } else {
                $title = $title -replace [regex]::Escape($symbol), ''
                $studio = $studio -replace [regex]::Escape($symbol), ''
            }
        }

        if (-not ($DisplayName.IsPresent)) {
            if ($title.Length -ge $Settings.General.'max-title-length') {
                $shortTitle = $title.Substring(0, $Settings.General.'max-title-length')
                $splitTitle = $shortTitle -split ' '
                if ($splitTitle.Count -gt 1) {
                    # Remove the last word of the title just in case it is cut off
                    $title = ($splitTitle[0..($splitTitle.Length - 2)] -join ' ')
                    if ($title[-1] -match '\W') {
                        $title = ($title.Substring(0, $title.Length - 2)) + '...'
                    } else {
                        $title = $title + '...'
                    }
                } else {
                    $title = $shortTitle + '...'
                }
            }
        }

        $FormatString = $FormatString[1..($FormatString.Length - 2)] -join ''
        $newName = $FormatString `
            -replace '<ID>', "$($DataObject.Id)" `
            -replace '<TITLE>', "$title" `
            -replace '<RELEASEDATE>', "$($DataObject.ReleaseDate)" `
            -replace '<YEAR>', "$($DataObject.ReleaseYear)" `
            -replace '<STUDIO>', "$studio" `
            -replace '<RUNTIME>', "$($DataObject.Runtime)"

        Write-Output $newName
    }
}
