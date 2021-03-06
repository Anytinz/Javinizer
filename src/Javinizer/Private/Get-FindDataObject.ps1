function Get-FindDataObject {
    [CmdletBinding()]
    param(
        [string]$Find,
        [object]$Settings,
        [switch]$Aggregated,
        [switch]$Dmm,
        [switch]$Javlibrary,
        [switch]$R18
    )

    begin {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Function started"
        $urlList = @()

        if (-not ($PSBoundParameters.ContainsKey('r18')) -and `
            (-not ($PSBoundParameters.ContainsKey('dmm')) -and `
                (-not ($PSBoundParameters.ContainsKey('javlibrary')) -and `
                    (-not ($PSBoundParameters.ContainsKey('7mmtv')))))) {
            if ($Settings.Main.'scrape-r18' -eq 'true') { $R18 = $true }
            if ($Settings.Main.'scrape-dmm' -eq 'true') { $Dmm = $true }
            if ($Settings.Main.'scrape-javlibrary' -eq 'true') { $Javlibrary = $true }
            if ($Settings.Main.'scrape-7mmtv' -eq 'true') { $7mmtv = $true }
        }
    }

    process {
        if (Test-Path -Path $Find) {
            $getItem = Get-Item $Find
        }

        if ($Find -match 'http:\/\/' -or $Find -match 'https:\/\/') {
            $urlList = Convert-CommaDelimitedString -String $Find
            $urlLocation = Test-UrlLocation -Url $urlList
            if ($Aggregated.IsPresent) {
                $aggregatedDataObject = Get-AggregatedDataObject -UrlLocation $urlLocation -Settings $Settings -ScriptRoot $ScriptRoot -ErrorAction 'SilentlyContinue'
                Write-Output $aggregatedDataObject | Select-Object Search, Id, Title, AlternateTitle, Description, ReleaseDate, ReleaseYear, Runtime, Director, Maker, Label, Series, Rating, RatingCount, Actress, Genre, ActressThumbUrl, CoverUrl, ScreenshotUrl, TrailerUrl, DisplayName, FolderName, FileName
            } else {
                if ($urlLocation.Result -eq 'r18') {
                    $r18Data = Get-R18DataObject -Url $Find -ErrorAction 'SilentlyContinue'
                    Write-Output $r18Data | Select-Object Url, Id, ContentId, Title, Description, Date, Year, Runtime, Director, Maker, Label, Series, Actress, Genre, ActressThumbUrl, CoverUrl, ScreenshotUrl, TrailerUrl
                }

                if ($urlLocation.Result -eq 'dmm') {
                    $dmmData = Get-DmmDataObject -Url $Find -ErrorAction 'SilentlyContinue'
                    Write-Output $dmmData | Select-Object Url, Id, Title, Description, Date, Year, Runtime, Director, Maker, Label, Series, Rating, RatingCount, Actress, Genre, CoverUrl, ScreenshotUrl
                }

                if ($urlLocation.Result -eq 'javlibrary') {
                    $javlibraryData = Get-JavlibraryDataObject -Url $Find -ScriptRoot $ScriptRoot -ErrorAction 'SilentlyContinue'
                    Write-Output $javlibraryData | Select-Object Url, Id, Title, Date, Year, Runtime, Director, Maker, Label, Series, Rating, Actress, Genre, CoverUrl, ScreenshotUrl
                }
            }
        } elseif ($null -ne $getItem) {
            if (Test-Path -Path $getItem -PathType Leaf) {
                $fileDetails = Convert-JavTitle -Path $Find -Recurse:$Recurse -Settings $Settings
                if ($Aggregated.IsPresent) {
                    $aggregatedDataObject = Get-AggregatedDataObject -FileDetails $fileDetails -Settings $ettings -R18:$R18 -Dmm:$Dmm -Javlibrary:$Javlibrary -ScriptRoot $ScriptRoot -ErrorAction 'SilentlyContinue'
                    Write-Output $aggregatedDataObject | Select-Object Search, Id, Title, AlternateTitle, Description, ReleaseDate, ReleaseYear, Runtime, Director, Maker, Label, Series, Rating, RatingCount, Actress, Genre, ActressThumbUrl, CoverUrl, ScreenshotUrl, TrailerUrl, DisplayName, FolderName, FileName
                } else {
                    if ($r18) {
                        $r18Data = Get-R18DataObject -Name $fileDetails.Id  -AltName $fileDetails.ContentId -ErrorAction 'SilentlyContinue'
                        Write-Output $r18Data | Select-Object Url, Id, ContentId, Title, Description, Date, Year, Runtime, Director, Maker, Label, Series, Actress, Genre, ActressThumbUrl, CoverUrl, ScreenshotUrl, TrailerUrl
                    }

                    if ($dmm) {
                        $dmmData = Get-DmmDataObject -Name $fileDetails.Id  -AltName $fileDetails.ContentId -ErrorAction 'SilentlyContinue'
                        Write-Output $dmmData | Select-Object Url, Id, Title, Description, Date, Year, Runtime, Director, Maker, Label, Series, Rating, RatingCount, Actress, Genre, CoverUrl, ScreenshotUrl
                    }

                    if ($javlibrary) {
                        $javlibraryData = Get-JavlibraryDataObject -Name $fileDetails.Id -ScriptRoot $ScriptRoot -ErrorAction 'SilentlyContinue'
                        Write-Output $javlibraryData | Select-Object Url, Id, Title, Date, Year, Runtime, Director, Maker, Label, Series, Rating, Actress, Genre, CoverUrl, ScreenshotUrl
                    }
                }
            }
        } else {
            if ($Aggregated.IsPresent) {
                $aggregatedDataObject = Get-AggregatedDataObject -Id $Find -Settings $Settings -R18:$R18 -Dmm:$Dmm -Javlibrary:$Javlibrary -ScriptRoot $ScriptRoot -ErrorAction 'SilentlyContinue'
                Write-Output $aggregatedDataObject | Select-Object Search, Id, Title, AlternateTitle, Description, ReleaseDate, ReleaseYear, Runtime, Director, Maker, Label, Series, Rating, RatingCount, Actress, Genre, ActressThumbUrl, CoverUrl, ScreenshotUrl, TrailerUrl, DisplayName, FolderName, FileName
            } else {
                if ($r18) {
                    $r18Data = Get-R18DataObject -Name $Find -ErrorAction 'SilentlyContinue'
                    Write-Output $r18Data | Select-Object Url, Id, ContentId, Title, Description, Date, Year, Runtime, Director, Maker, Label, Series, Actress, Genre, ActressThumbUrl, CoverUrl, ScreenshotUrl, TrailerUrl
                }

                if ($dmm) {
                    $dmmData = Get-DmmDataObject -Name $Find -ErrorAction 'SilentlyContinue'
                    Write-Output $dmmData | Select-Object Url, Id, Title, Description, Date, Year, Runtime, Director, Maker, Label, Series, Rating, RatingCount, Actress, Genre, CoverUrl, ScreenshotUrl
                }

                if ($javlibrary) {
                    $javlibraryData = Get-JavlibraryDataObject -Name $Find -ScriptRoot $ScriptRoot -ErrorAction 'SilentlyContinue'
                    Write-Output $javlibraryData | Select-Object Url, Id, Title, Date, Year, Runtime, Director, Maker, Label, Series, Rating, Actress, Genre, CoverUrl, ScreenshotUrl
                }
            }
        }
    }

    end {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
