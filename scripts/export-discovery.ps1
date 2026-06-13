[CmdletBinding()]
param(
    [Alias('source_genesyscloud_oauthclient_id')]
    [string]$SourceOAuthClientId,

    [Alias('source_genesyscloud_oauthclient_secret')]
    [string]$SourceOAuthClientSecret,

    [Alias('source_genesyscloud_region')]
    [string]$SourceRegion,

    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-Usage {
    Write-Host "Usage: ./scripts/export-discovery.ps1 -SourceOAuthClientId <id> -SourceOAuthClientSecret <secret> -SourceRegion <region-or-api-host>"
    Write-Host ""
    Write-Host "Credential-only env var fallback (any one set per value):"
    Write-Host "  source_genesyscloud_oauthclient_id or SOURCE_GENESYSCLOUD_OAUTHCLIENT_ID"
    Write-Host "  source_genesyscloud_oauthclient_secret or SOURCE_GENESYSCLOUD_OAUTHCLIENT_SECRET"
    Write-Host "  source_genesyscloud_region or SOURCE_GENESYSCLOUD_REGION"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  ./scripts/export-discovery.ps1 -SourceOAuthClientId 'abc' -SourceOAuthClientSecret '***' -SourceRegion 'us-east-1'"
    Write-Host "  ./scripts/export-discovery.ps1"
}

function Get-FirstNonEmpty {
    param([string[]]$Values)

    foreach ($v in $Values) {
        if (-not [string]::IsNullOrWhiteSpace($v)) {
            return $v
        }
    }

    return $null
}

function Resolve-GenesysApiHost {
    param([Parameter(Mandatory = $true)][string]$RegionOrHost)

    $value = $RegionOrHost.Trim().ToLowerInvariant()

    if ($value.StartsWith('https://')) {
        $value = $value.Substring(8)
    }

    if ($value.Contains('/')) {
        $value = $value.Split('/')[0]
    }

    if ($value.Contains('.')) {
        return $value
    }

    $regionMap = @{
        'mypurecloud.com'   = 'api.mypurecloud.com'
        'us-east-1'         = 'api.mypurecloud.com'
        'us-east-2'         = 'api.use2.us-gov-pure.cloud'
        'us-west-2'         = 'api.usw2.pure.cloud'
        'ca-central-1'      = 'api.cac1.pure.cloud'
        'eu-west-1'         = 'api.mypurecloud.ie'
        'eu-west-2'         = 'api.euw2.pure.cloud'
        'eu-central-1'      = 'api.mypurecloud.de'
        'eu-central-2'      = 'api.euc2.pure.cloud'
        'ap-southeast-2'    = 'api.mypurecloud.com.au'
        'ap-northeast-1'    = 'api.mypurecloud.jp'
        'ap-northeast-2'    = 'api.apne2.pure.cloud'
        'ap-south-1'        = 'api.aps1.pure.cloud'
        'sa-east-1'         = 'api.sae1.pure.cloud'
        'me-central-1'      = 'api.mec1.pure.cloud'
    }

    if ($regionMap.ContainsKey($value)) {
        return $regionMap[$value]
    }

    throw "Unrecognized SourceRegion '$RegionOrHost'. Provide a known Genesys region (for example us-east-1) or an API host (for example api.mypurecloud.com)."
}

function Resolve-GenesysLoginHost {
    param([Parameter(Mandatory = $true)][string]$ApiHost)

    $host = $ApiHost.Trim().ToLowerInvariant()

    if ($host.StartsWith('api.')) {
        return "login.$($host.Substring(4))"
    }

    if ($host.StartsWith('api-')) {
        return "login-$($host.Substring(4))"
    }

    return "login.$host"
}

function Get-OAuthToken {
    param(
        [Parameter(Mandatory = $true)][string]$LoginHost,
        [Parameter(Mandatory = $true)][string]$ClientId,
        [Parameter(Mandatory = $true)][string]$ClientSecret
    )

    $tokenUri = "https://$LoginHost/oauth/token"
    $basicBytes = [System.Text.Encoding]::UTF8.GetBytes("$ClientId`:$ClientSecret")
    $basicAuth = [Convert]::ToBase64String($basicBytes)

    try {
        $response = Invoke-RestMethod -Method Post -Uri $tokenUri -Headers @{ Authorization = "Basic $basicAuth" } -ContentType 'application/x-www-form-urlencoded' -Body @{ grant_type = 'client_credentials' }
    }
    catch {
        throw "Failed to obtain OAuth token from '$tokenUri'. Verify source OAuth credentials and region/host."
    }

    if ([string]::IsNullOrWhiteSpace($response.access_token)) {
        throw "OAuth response did not include an access token."
    }

    return [string]$response.access_token
}

function Invoke-GenesysPagedGet {
    param(
        [Parameter(Mandatory = $true)][string]$ApiBase,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][hashtable]$Headers,
        [int]$PageSize = 100
    )

    $all = New-Object System.Collections.Generic.List[object]
    $pageNumber = 1
    $maxPages = 500

    while ($pageNumber -le $maxPages) {
        $separator = '?'
        if ($RelativePath.Contains('?')) {
            $separator = '&'
        }

        $uri = "$ApiBase$RelativePath$separator" + "pageSize=$PageSize&pageNumber=$pageNumber"

        try {
            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers
        }
        catch {
            throw "Failed API request: GET $uri"
        }

        $entities = @()
        if ($null -ne $response.entities) {
            $entities = @($response.entities)
        }
        elseif ($null -ne $response.items) {
            $entities = @($response.items)
        }
        elseif ($null -ne $response.data) {
            $entities = @($response.data)
        }

        foreach ($entity in $entities) {
            [void]$all.Add($entity)
        }

        $hasNext = $false
        if ($null -ne $response.nextUri -and -not [string]::IsNullOrWhiteSpace([string]$response.nextUri)) {
            $hasNext = $true
        }
        elseif ($null -ne $response.pageCount -and $response.pageNumber -lt $response.pageCount) {
            $hasNext = $true
        }
        elseif ($null -ne $response.total -and (($pageNumber * $PageSize) -lt [int]$response.total)) {
            $hasNext = $true
        }

        if (-not $hasNext) {
            break
        }

        $pageNumber++
    }

    if ($pageNumber -gt $maxPages) {
        throw "Exceeded pagination safety limit ($maxPages pages) for path '$RelativePath'."
    }

    return @($all.ToArray())
}

function Invoke-GenesysGet {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][hashtable]$Headers
    )

    try {
        return Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers
    }
    catch {
        throw "Failed API request: GET $Uri"
    }
}

function Save-Json {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Data
    )

    $json = $Data | ConvertTo-Json -Depth 100
    Set-Content -Path $Path -Value $json -Encoding UTF8
}

function Get-Flows {
    param(
        [Parameter(Mandatory = $true)][string]$ApiBase,
        [Parameter(Mandatory = $true)][hashtable]$Headers
    )

    $flowTypes = @('inboundcall', 'inqueuecall', 'securecall', 'commonmodule', 'outboundcall')
    $dedup = @{}

    foreach ($type in $flowTypes) {
        try {
            $typeFlows = Invoke-GenesysPagedGet -ApiBase $ApiBase -RelativePath "/flows?type=$type" -Headers $Headers
            foreach ($flow in $typeFlows) {
                if ($null -ne $flow.id -and -not $dedup.ContainsKey([string]$flow.id)) {
                    $dedup[[string]$flow.id] = $flow
                }
            }
        }
        catch {
            Write-Warning "Flow discovery failed for type '$type'. Continuing."
        }
    }

    return @($dedup.Values)
}

try {
    if ($Help) {
        Show-Usage
        exit 0
    }

    $SourceOAuthClientId = Get-FirstNonEmpty @(
        $SourceOAuthClientId,
        $env:source_genesyscloud_oauthclient_id,
        $env:SOURCE_GENESYSCLOUD_OAUTHCLIENT_ID
    )
    $SourceOAuthClientSecret = Get-FirstNonEmpty @(
        $SourceOAuthClientSecret,
        $env:source_genesyscloud_oauthclient_secret,
        $env:SOURCE_GENESYSCLOUD_OAUTHCLIENT_SECRET
    )
    $SourceRegion = Get-FirstNonEmpty @(
        $SourceRegion,
        $env:source_genesyscloud_region,
        $env:SOURCE_GENESYSCLOUD_REGION
    )

    $missing = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($SourceOAuthClientId)) { [void]$missing.Add('source_genesyscloud_oauthclient_id') }
    if ([string]::IsNullOrWhiteSpace($SourceOAuthClientSecret)) { [void]$missing.Add('source_genesyscloud_oauthclient_secret') }
    if ([string]::IsNullOrWhiteSpace($SourceRegion)) { [void]$missing.Add('source_genesyscloud_region') }

    if ($missing.Count -gt 0) {
        Show-Usage
        throw "Missing required input(s): $($missing -join ', ')"
    }

    $apiHost = Resolve-GenesysApiHost -RegionOrHost $SourceRegion
    $loginHost = Resolve-GenesysLoginHost -ApiHost $apiHost
    $apiBase = "https://$apiHost/api/v2"

    Write-Host "Authenticating to source org host '$apiHost'."
    $accessToken = Get-OAuthToken -LoginHost $loginHost -ClientId $SourceOAuthClientId -ClientSecret $SourceOAuthClientSecret
    $headers = @{ Authorization = "Bearer $accessToken" }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $runPath = Join-Path $repoRoot "exports/source/$timestamp"
    New-Item -Path $runPath -ItemType Directory -Force | Out-Null
    $resolvedRunPath = (Resolve-Path -Path $runPath).Path

    Write-Host "Resolved export directory: $resolvedRunPath"

    Write-Host 'Discovering flows...'
    $flows = Get-Flows -ApiBase $apiBase -Headers $headers

    Write-Host 'Discovering routing queues...'
    $queues = Invoke-GenesysPagedGet -ApiBase $apiBase -RelativePath '/routing/queues' -Headers $headers

    Write-Host 'Discovering integrations...'
    $integrations = Invoke-GenesysPagedGet -ApiBase $apiBase -RelativePath '/integrations' -Headers $headers

    Write-Host 'Discovering integration actions...'
    $integrationActions = New-Object System.Collections.Generic.List[object]
    foreach ($integration in $integrations) {
        if ($null -eq $integration.id) {
            continue
        }

        $integrationId = [string]$integration.id
        $actionsUri = "$apiBase/integrations/$integrationId/actions"

        try {
            $actionResponse = Invoke-GenesysGet -Uri $actionsUri -Headers $headers
            $actions = @()
            if ($null -ne $actionResponse.entities) {
                $actions = @($actionResponse.entities)
            }
            elseif ($null -ne $actionResponse.actions) {
                $actions = @($actionResponse.actions)
            }

            [void]$integrationActions.Add([pscustomobject]@{
                integrationId = $integrationId
                integrationName = $integration.name
                actionCount = $actions.Count
                actions = $actions
            })
        }
        catch {
            Write-Warning "Integration action discovery failed for integration '$integrationId'. Continuing."
            [void]$integrationActions.Add([pscustomobject]@{
                integrationId = $integrationId
                integrationName = $integration.name
                actionCount = 0
                actions = @()
                error = 'discovery_failed'
            })
        }
    }

    Write-Host 'Discovering routing skills...'
    $routingSkills = Invoke-GenesysPagedGet -ApiBase $apiBase -RelativePath '/routing/skills' -Headers $headers

    Write-Host 'Discovering routing languages...'
    $routingLanguages = Invoke-GenesysPagedGet -ApiBase $apiBase -RelativePath '/routing/languages' -Headers $headers

    Write-Host 'Discovering wrap-up codes...'
    $wrapUpCodes = Invoke-GenesysPagedGet -ApiBase $apiBase -RelativePath '/routing/wrapupcodes' -Headers $headers

    Save-Json -Path (Join-Path $runPath 'flows.json') -Data $flows
    Save-Json -Path (Join-Path $runPath 'queues.json') -Data $queues
    Save-Json -Path (Join-Path $runPath 'integrations.json') -Data $integrations
    Save-Json -Path (Join-Path $runPath 'integration_actions.json') -Data @($integrationActions.ToArray())
    Save-Json -Path (Join-Path $runPath 'routing_skills.json') -Data $routingSkills
    Save-Json -Path (Join-Path $runPath 'routing_languages.json') -Data $routingLanguages
    Save-Json -Path (Join-Path $runPath 'wrap_up_codes.json') -Data $wrapUpCodes

    $summary = [pscustomobject]@{
        generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        source_region_input = $SourceRegion
        source_api_host = $apiHost
        export_path = $resolvedRunPath
        counts = [pscustomobject]@{
            flows = @($flows).Count
            queues = @($queues).Count
            integrations = @($integrations).Count
            integration_action_sets = @($integrationActions.ToArray()).Count
            routing_skills = @($routingSkills).Count
            routing_languages = @($routingLanguages).Count
            wrap_up_codes = @($wrapUpCodes).Count
        }
        files = @(
            'flows.json',
            'queues.json',
            'integrations.json',
            'integration_actions.json',
            'routing_skills.json',
            'routing_languages.json',
            'wrap_up_codes.json',
            'summary.json'
        )
    }

    Save-Json -Path (Join-Path $runPath 'summary.json') -Data $summary

    Write-Host "Export/discovery complete. Artifacts: $resolvedRunPath"
    Write-Host "Summary file: $(Join-Path $resolvedRunPath 'summary.json')"
    exit 0
}
catch {
    Write-Error "Export/discovery failed. $($_.Exception.Message)"
    exit 1
}