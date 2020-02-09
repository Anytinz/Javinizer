function Get-JavlibraryDataObject {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Position = 0)]
        [string]$Name,
        [Parameter(Position = 1)]
        [string]$Url,
        [string]$ScriptRoot
    )

    begin {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Function started"
        $movieDataObject = @()
    }

    process {
        if ($Url) {
            $javlibraryUrl = $Url
        } else {
            $javlibraryUrl = Get-JavLibraryUrl -Name $Name -ScriptRoot $ScriptRoot
        }

        if ($null -ne $javlibraryUrl) {
            try {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Performing [GET] on Uri [$javlibraryUrl] with Session: [$Session] and UserAgent: [$($Session.UserAgent)]"
                $webRequest = Invoke-WebRequest -Uri $javlibraryUrl -Method Get -WebSession $Session -UserAgent $Session.UserAgent -Verbose:$false
            } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Session to JAVLibrary is unsuccessful, attempting to start a new session with Cloudflare"
                try {
                    New-CloudflareSession -ScriptRoot $ScriptRoot
                } catch {
                    throw $_
                }

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Performing [GET] on Uri [$javlibraryUrl] with Session: [$Session] and UserAgent: [$($Session.UserAgent)]"
                $webRequest = Invoke-WebRequest -Uri $javlibraryUrl -Method Get -WebSession $Session -UserAgent $Session.UserAgent -Verbose:$false
            }

            $movieDataObject = [pscustomobject]@{
                Source        = 'javlibrary'
                Url           = $javlibraryUrl
                Id            = Get-JLId -WebRequest $webRequest
                Title         = Get-JLTitle -WebRequest $webRequest
                Date          = Get-JLReleaseDate -WebRequest $webRequest
                Year          = Get-JLReleaseYear -WebRequest $webRequest
                Runtime       = Get-JLRuntime -WebRequest $webRequest
                Director      = Get-JLDirector -WebRequest $webRequest
                Maker         = Get-JLMaker -WebRequest $webRequest
                Label         = Get-JLLabel -WebRequest $webRequest
                Rating        = Get-JLRating -WebRequest $webRequest
                Actress       = Get-JLActress -WebRequest $webRequest
                Genre         = Get-JLGenre -WebRequest $webRequest
                CoverUrl      = Get-JLCoverUrl -WebRequest $webRequest
                ScreenshotUrl = Get-JLScreenshotUrl -WebRequest $webRequest
            }
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)] JAVLibrary data object:"
        $movieDataObject | Format-List | Out-String | Write-Debug
        Write-Output $movieDataObject
    }

    end {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}

function Get-JLId {
    param (
        [object]$WebRequest
    )

    process {
        $id = ((($WebRequest.Content -split '<td class="header">识别码:<\/td>')[1] -split '<\/td>')[0] -split '>')[1]
        Write-Output $id
    }
}

# TODO: Add specific functionality to match video IDs containing trailing alpha characters (e.g. IBW-123z)
function Get-JLTitle {
    param (
        [object]$WebRequest
    )
    process {
        $fullTitle = ((($WebRequest.Content -split '<title>')[1] -split ' - JAVLibrary<\/title>')[0] -split ' ')
        $joinedTitle = $fullTitle[1..$fullTitle.length] -join ' '
        $title = Convert-HtmlCharacter -String $joinedTitle
        Write-Output $title
    }
}

function Get-JLReleaseDate {
    param (
        [object]$WebRequest
    )

    process {
        $releaseDate = ((($WebRequest.Content -split '<td class="header">发行日期:<\/td>')[1] -split '<\/td>')[0] -split '>')[1]
        Write-Output $releaseDate
    }
}

function Get-JLReleaseYear {
    param (
        [object]$WebRequest
    )

    process {
        $releaseYear = Get-JLReleaseDate -WebRequest $WebRequest
        $releaseYear = ($releaseYear -split '-')[0]
        Write-Output $releaseYear
    }
}

function Get-JLRuntime {
    param (
        [object]$WebRequest
    )

    process {
        $length = ((($WebRequest.Content -split '<td class="header">长度:<\/td>')[1] -split '<\/span>')[0] -split '"text">')[1]
        Write-Output $length
    }
}

function Get-JLDirector {
    param (
        [object]$WebRequest
    )

    process {
        $director = (((($WebRequest.Content -split '<td class="header">导演:</td>')[1]) -split '<\/td>')[0])
        if ($director -match '<\/a>') {
            $director = (($director -split 'rel="tag">')[1] -split '<\/a')[0]
        } else {
            $director = $null
        }
        $director = Convert-HtmlCharacter -String $director
        Write-Output $director
    }
}

function Get-JLMaker {
    param (
        [object]$WebRequest
    )

    process {
        $maker = (((($WebRequest.Content -split '<td class="header">制作商:</td>')[1]) -split '<\/a>')[0] -split 'rel="tag">')[1]
        $maker = Convert-HtmlCharacter -String $maker
        Write-Output $maker
    }
}

function Get-JLLabel {
    param (
        [object]$WebRequest
    )

    process {
        $label = (((($WebRequest.Content -split '<td class="header">发行商:</td>')[1]) -split '<\/a>')[0] -split 'rel="tag">')[1]
        $label = Convert-HtmlCharacter -String $label
        Write-Output $label
    }
}

function Get-JLRating {
    param (
        [object]$WebRequest
    )

    process {
        $rating = (((($WebRequest.Content -split '<td class="header">使用者评价:</td>')[1]) -split '<\/span>')[0] -split '<span class="score">')[1]
        $rating = ($rating -replace '\(', '') -replace '\)', ''
        Write-Output $rating
    }
}

function Get-JLGenre {
    param (
        [object]$WebRequest
    )

    begin {
        $genre = @()
    }

    process {
        $genreHtml = ($WebRequest.Content -split '<td class="header">类别:<\/td>')[1]
        $genreHtml = ($genreHtml -split '<\/td>')[0]
        $genreHtml = $genreHtml -split 'rel="category tag">'

        foreach ($genres in $genreHtml[1..($genreHtml.Length - 1)]) {
            $genres = ($genres -split '<')[0]
            $genres = Convert-HtmlCharacter -String $genres
            $genre += $genres
        }

        if ($genre.Count -eq 0) {
            $genre = $null
        }

        Write-Output $genre
    }
}

function Get-JLActress {
    param (
        [object]$WebRequest
    )

    begin {
        $actress = @()
    }

    process {
        $actressSplitString = '<span class="star">'
        $actressSplitHtml = $WebRequest.Content -split $actressSplitString

        foreach ($section in $actressSplitHtml) {
            $fullName = (($section -split "rel=`"tag`">")[1] -split "<\/a><\/span>")[0]
            if ($fullName -ne '') {
                if ($fullName.Length -lt 25) {
                    $actress += $fullName
                }
            }
        }

        if ($actress.Count -eq 0) {
            $actress = $null
        }

        Write-Output $actress
    }
}

function Get-JLCoverUrl {
    param (
        [object]$WebRequest
    )

    process {
        $coverUrl = (($WebRequest.Content -split '<img id="video_jacket_img" src="')[1] -split '"')[0]
        if ($coverUrl -like '*pixhost*') {
            $coverUrl = 'http:' + $coverUrl
        } else {
            $coverUrl = 'https:' + $coverUrl
        }
        Write-Output $coverUrl
    }
}

function Get-JLScreenshotUrl {
    param (
        [object]$WebRequest
    )

    begin {
        $screenshotUrl = @()
    }

    process {
        $screenshotHtml = (($WebRequest.Content -split '<div class="previewthumbs" style="display:block; margin:10px auto;">')[1] -split '<\/div>')[0]
        $screenshotHtml = $screenshotHtml -split '<img src="'
        foreach ($screenshot in $screenshotHtml) {
            if ($screenshot -ne '') {
                $screenshot = 'https:' + ($screenshot -split '"')[0]
                $screenshot = $screenshot -replace '-', 'jp-'
                if ($screenshot -match 'pics.dmm') {
                    $screenshotUrl += $screenshot
                }
            }
        }

        Write-Output $screenshotUrl
    }
}
