function Get-JavlibraryUrl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,
        [int]$Tries,
        [string]$ScriptRoot
    )

    begin {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Function started"
        $searchUrl = "http://www.javlibrary.com/cn/vl_searchbyid.php?keyword=$Name"
    }

    process {
        try {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Performing [GET] on Uri [$searchUrl] with Session: [$Session] and UserAgent: [$($Session.UserAgent)]"
            $webRequest = Invoke-WebRequest -Uri $searchUrl -Method Get -WebSession $Session -UserAgent $Session.UserAgent -Verbose:$false
        } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Session to JAVLibrary is unsuccessful, attempting to start a new session with Cloudflare"
            try {
                New-CloudflareSession -ScriptRoot $ScriptRoot
            } catch {
                throw $_
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Performing [GET] on Uri [$searchUrl] with Session: [$Session] and UserAgent: [$($Session.UserAgent)]"
            $webRequest = Invoke-WebRequest -Uri $searchUrl -Method Get -WebSession $Session -UserAgent $Session.UserAgent -Verbose:$false
        }

        # Check if the search uniquely matched a video page
        # If not, we will check the search results and check a few for if they are a match
        $searchResultUrl = $webRequest.BaseResponse.RequestMessage.RequestUri.AbsoluteUri
        if ($searchResultUrl -match 'http:\/\/www\.javlibrary\.com\/cn\/\?v=') {
            try {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Performing [GET] on Uri [$searchResultUrl] with Session: [$Session] and UserAgent: [$($Session.UserAgent)]"
                $webRequest = Invoke-WebRequest -Uri $searchResultUrl -Method Get -WebSession $Session -UserAgent $Session.UserAgent -Verbose:$false
            } catch {
                throw $_
            }

            $resultId = Get-JLId -WebRequest $webRequest
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Result is [$resultId]"
            if ($resultId -eq $Name) {
                $javlibraryUrl = $searchResultUrl
            }
        }

        if ($null -eq $javlibraryUrl) {
            $Tries = 5
            $searchResults = $webRequest.Links.href | Where-Object { $_ -match '\.\/\?v=(.*)' }
            $numResults = $searchResults.count

            if ($Tries -gt $numResults) {
                $Tries = $numResults
            }

            if ($numResults -ge 1) {
                $count = 1
                foreach ($result in $searchResults) {
                    $videoId = ($result -split '=')[1]
                    $directUrl = "http://www.javlibrary.com/cn/?v=$videoId"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Performing [GET] on Uri [$directUrl] with Session: [$Session] and UserAgent: [$($Session.UserAgent)]"
                    $webRequest = Invoke-WebRequest -Uri $directUrl -Method Get -WebSession $Session -UserAgent $Session.UserAgent -Verbose:$false
                    $resultId = Get-JLId -WebRequest $webRequest
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Result [$count] is [$resultId]"

                    if ($resultId -eq $Name) {
                        $javlibraryUrl = (Test-UrlLocation -Url $webRequest.BaseResponse.RequestMessage.RequestUri.AbsoluteUri).Url
                        break
                    }

                    if ($count -eq $Tries) {
                        break
                    }

                    $count++
                }
            }
        }

        if ($null -eq $javlibraryUrl) {
            Write-Warning "[$($MyInvocation.MyCommand.Name)] Search [$Name] not matched on JAVLibrary"
            return
        } else {
            Write-Output $javlibraryUrl
        }
    }

    end {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}

