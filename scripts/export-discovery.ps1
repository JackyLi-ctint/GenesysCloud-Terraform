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

function Resolve-ProviderSettings {
    param([Parameter(Mandatory = $true)][string]$RegionOrHost)

    $value = $RegionOrHost.Trim().ToLowerInvariant()

    if ($value.StartsWith('https://')) {
        $value = $value.Substring(8)
    }

    if ($value.Contains('/')) {
        $value = $value.Split('/')[0]
    }

    $regionMap = @{
        'us-east-1'      = 'mypurecloud.com'
        'us-east-2'      = 'use2.us-gov-pure.cloud'
        'us-west-2'      = 'usw2.pure.cloud'
        'ca-central-1'   = 'cac1.pure.cloud'
        'eu-west-1'      = 'mypurecloud.ie'
        'eu-west-2'      = 'euw2.pure.cloud'
        'eu-central-1'   = 'mypurecloud.de'
        'eu-central-2'   = 'euc2.pure.cloud'
        'ap-southeast-2' = 'mypurecloud.com.au'
        'ap-northeast-1' = 'mypurecloud.jp'
        'ap-northeast-2' = 'apne2.pure.cloud'
        'ap-south-1'     = 'aps1.pure.cloud'
        'sa-east-1'      = 'sae1.pure.cloud'
        'me-central-1'   = 'mec1.pure.cloud'
    }

    if ($regionMap.ContainsKey($value)) {
        $providerRegion = $regionMap[$value]
        return [pscustomobject]@{
            provider_region = $providerRegion
            api_host = "api.$providerRegion"
        }
    }

    if ($value.Contains('.')) {
        $host = $value
        if ($host.StartsWith('api.')) {
            $providerRegion = $host.Substring(4)
            return [pscustomobject]@{
                provider_region = $providerRegion
                api_host = $host
            }
        }

        if ($host.StartsWith('login.')) {
            $providerRegion = $host.Substring(6)
            return [pscustomobject]@{
                provider_region = $providerRegion
                api_host = "api.$providerRegion"
            }
        }

        return [pscustomobject]@{
            provider_region = $host
            api_host = "api.$host"
        }
    }

    throw "Unrecognized SourceRegion '$RegionOrHost'. Provide a known Genesys region (for example us-east-1) or an API host (for example api.mypurecloud.com)."
}

function Save-Json {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Data
    )

    $json = $Data | ConvertTo-Json -Depth 100
    Set-Content -Path $Path -Value $json -Encoding UTF8
}

function Get-TerraformExecutable {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot
    )

    $localExe = Join-Path $RepoRoot 'terraform.exe'
    if (Test-Path -Path $localExe) {
        return $localExe
    }

    $terraformInPath = Get-Command terraform -ErrorAction SilentlyContinue
    if ($null -ne $terraformInPath) {
        return 'terraform'
    }

    throw "Terraform executable not found. Place terraform.exe at repository root or add terraform to PATH."
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

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $exportPath = Join-Path $repoRoot "exports/source/$timestamp"
    New-Item -Path $exportPath -ItemType Directory -Force | Out-Null
    $resolvedExportPath = (Resolve-Path -Path $exportPath).Path

    $providerSettings = Resolve-ProviderSettings -RegionOrHost $SourceRegion
    $terraformExe = Get-TerraformExecutable -RepoRoot $repoRoot
    $tempWorkDir = Join-Path ([System.IO.Path]::GetTempPath()) "genesys-export-$timestamp-$([Guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -Path $tempWorkDir -ItemType Directory -Force | Out-Null

    $tfConfig = @"
terraform {
  required_providers {
    genesyscloud = {
      source = "MyPureCloud/genesyscloud"
    }
  }
}

provider "genesyscloud" {}

resource "genesyscloud_tf_export" "source" {
  export_format                      = "hcl"
  include_state_file                 = false
  log_permission_errors              = true
  enable_dependency_resolution       = true
  use_legacy_architect_flow_exporter = false
}
"@
    $tfConfigPath = Join-Path $tempWorkDir 'main.tf'
    Set-Content -Path $tfConfigPath -Value $tfConfig -Encoding UTF8

    $previousClientId = $env:GENESYSCLOUD_OAUTHCLIENT_ID
    $previousClientSecret = $env:GENESYSCLOUD_OAUTHCLIENT_SECRET
    $previousRegion = $env:GENESYSCLOUD_REGION
    $previousApiHost = $env:GENESYSCLOUD_API_HOST

    $applySucceeded = $false
    try {
        $env:GENESYSCLOUD_OAUTHCLIENT_ID = $SourceOAuthClientId
        $env:GENESYSCLOUD_OAUTHCLIENT_SECRET = $SourceOAuthClientSecret
        $env:GENESYSCLOUD_REGION = $providerSettings.provider_region
        $env:GENESYSCLOUD_API_HOST = $providerSettings.api_host

        Write-Host "Starting provider export for source input '$SourceRegion'."
        Write-Host "Resolved provider region '$($providerSettings.provider_region)' and API host '$($providerSettings.api_host)'."
        Write-Host "Temporary Terraform directory: $tempWorkDir"
        Write-Host "Export output directory: $resolvedExportPath"

        & $terraformExe -chdir=$tempWorkDir init -no-color
        if ($LASTEXITCODE -ne 0) {
            throw "terraform init failed in temporary export directory."
        }

        & $terraformExe -chdir=$tempWorkDir apply -auto-approve -no-color
        if ($LASTEXITCODE -ne 0) {
            throw "terraform apply failed while running genesyscloud_tf_export."
        }

        $skipNames = @('main.tf', '.terraform.lock.hcl', 'terraform.tfstate', 'terraform.tfstate.backup')
        $allFiles = Get-ChildItem -Path $tempWorkDir -Recurse -File | Where-Object {
            $_.FullName -notmatch '\\.terraform(\\|$)' -and $skipNames -notcontains $_.Name
        }

        foreach ($file in $allFiles) {
            $relativePath = $file.FullName.Substring($tempWorkDir.Length).TrimStart('\\')
            $destinationPath = Join-Path $resolvedExportPath $relativePath
            $destinationDir = Split-Path -Path $destinationPath -Parent
            New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
            Copy-Item -Path $file.FullName -Destination $destinationPath -Force
        }

        $applySucceeded = $true
    }
    finally {
        if ($null -eq $previousClientId) { Remove-Item Env:GENESYSCLOUD_OAUTHCLIENT_ID -ErrorAction SilentlyContinue } else { $env:GENESYSCLOUD_OAUTHCLIENT_ID = $previousClientId }
        if ($null -eq $previousClientSecret) { Remove-Item Env:GENESYSCLOUD_OAUTHCLIENT_SECRET -ErrorAction SilentlyContinue } else { $env:GENESYSCLOUD_OAUTHCLIENT_SECRET = $previousClientSecret }
        if ($null -eq $previousRegion) { Remove-Item Env:GENESYSCLOUD_REGION -ErrorAction SilentlyContinue } else { $env:GENESYSCLOUD_REGION = $previousRegion }
        if ($null -eq $previousApiHost) { Remove-Item Env:GENESYSCLOUD_API_HOST -ErrorAction SilentlyContinue } else { $env:GENESYSCLOUD_API_HOST = $previousApiHost }
    }

    if (-not $applySucceeded) {
        throw 'Provider export did not complete successfully.'
    }

    $exportedFiles = Get-ChildItem -Path $resolvedExportPath -Recurse -File | Select-Object -ExpandProperty FullName
    $relativeExportedFiles = @($exportedFiles | ForEach-Object { $_.Substring($resolvedExportPath.Length).TrimStart('\\') })

    $summary = [pscustomobject]@{
        generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        export_path = $resolvedExportPath
        source_input = $SourceRegion
        provider_region = $providerSettings.provider_region
        provider_api_host = $providerSettings.api_host
        terraform_executable = $terraformExe
        key_settings = [pscustomobject]@{
            export_format = 'hcl'
            include_state_file = $false
            log_permission_errors = $true
            enable_dependency_resolution = $true
            use_legacy_architect_flow_exporter = $false
        }
        exported_file_count = @($relativeExportedFiles).Count
        exported_files = $relativeExportedFiles
    }

    Save-Json -Path (Join-Path $resolvedExportPath 'summary.json') -Data $summary

    Write-Host "Provider export complete. Artifacts: $resolvedExportPath"
    Write-Host "Summary file: $(Join-Path $resolvedExportPath 'summary.json')"
    exit 0
}
catch {
    Write-Error "Export/discovery failed. $($_.Exception.Message)"
    exit 1
}