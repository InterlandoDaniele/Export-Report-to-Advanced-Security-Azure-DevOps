# Recupera variabili di ambiente da Azure DevOps
$orgName = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI -replace "https://dev.azure.com/", "" -replace "/$", ""
$projName = $env:SYSTEM_TEAMPROJECT
$repoName = $env:BUILD_REPOSITORY_NAME
$patToken = $env:SYSTEM_ACCESSTOKEN
$apiVersion = "7.2-preview.1"

# Verifica variabili
if (-not $orgName -or -not $projName -or -not $repoName -or -not $patToken) {
    Write-Error "Variabili di ambiente mancanti. Abilita 'Allow scripts to access the OAuth token'."
    exit 1
}

# Configurazione autenticazione
$authHeader = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$patToken"))
    "Content-Type" = "application/json"
}

# Ottieni l'ID del repository
try {
    $repoApiUrl = "https://dev.azure.com/$orgName/$projName/_apis/git/repositories?api-version=$apiVersion"
    $repoData = Invoke-RestMethod -Uri $repoApiUrl -Headers $authHeader -Method Get
    $repoId = ($repoData.value | Where-Object { $_.name -eq $repoName }).id
    if (-not $repoId) {
        Write-Error "Repository $repoName non trovato!"
        exit 1
    }
} catch {
    Write-Error "Errore nel recupero del repository: $($_.Exception.Message)"
    exit 1
}

# Genera timestamp e directory di output
$timeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputDir = "AdvancedSecurityReport_$repoName_$timeStamp"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

# Funzione per estrarre ricorsivamente le proprietà
function Extract-Properties {
    param ($object, $prefix = "")
    $properties = @{}
    if ($object -is [PSCustomObject]) {
        foreach ($prop in $object.PSObject.Properties) {
            $key = if ($prefix) { "$prefix.$($prop.Name)" } else { $prop.Name }
            if ($prop.Value -is [Array] -and $prop.Value.Count -gt 0) {
                for ($i = 0; $i -lt $prop.Value.Count; $i++) {
                    $properties += Extract-Properties -object $prop.Value[$i] -prefix "$key[$i]"
                }
            } elseif ($prop.Value -is [PSCustomObject]) {
                $properties += Extract-Properties -object $prop.Value -prefix $key
            } else {
                $properties[$key] = $prop.Value
            }
        }
    }
    return $properties
}

# Funzione per recuperare e processare gli alert
function Get-SecurityAlerts {
    $alertsUrl = "https://advsec.dev.azure.com/$orgName/$projName/_apis/alert/repositories/$repoId/alerts?api-version=$apiVersion"
    $allAlerts = @()
    $nextLink = $null

    do {
        $currentUrl = if ($nextLink) { $nextLink } else { $alertsUrl }
        try {
            Write-Host "Richiedendo: $currentUrl" # Debug
            $apiResponse = Invoke-RestMethod -Uri $currentUrl -Headers $authHeader -Method Get -ErrorAction Stop
            Write-Host "Risposta: $($apiResponse | ConvertTo-Json -Depth 5)" # Debug

            if ($apiResponse.PSObject.Properties.Name -contains "value" -and $apiResponse.value) {
                foreach ($alert in $apiResponse.value) {
                    Write-Host "Elaborando alert: $($alert | ConvertTo-Json -Depth 5)" # Debug
                    $alertProps = Extract-Properties -object $alert
                    $alertObj = New-Object PSObject -Property $alertProps
                    $allAlerts += $alertObj
                }
            } else {
                Write-Host "Nessun alert nella risposta: $($apiResponse | ConvertTo-Json -Depth 5)"
            }
            $nextLink = if ($apiResponse.PSObject.Properties.Name -contains "@odata.nextLink") { $apiResponse."@odata.nextLink" } else { $null }
        } catch {
            Write-Error "Errore API: $($_.Exception.Message) - Dettagli: $($_.Exception.Response.Content)"
            break
        }
    } while ($nextLink)

    return $allAlerts
}

# Esegui la funzione e genera il report
$securityAlerts = Get-SecurityAlerts
if ($securityAlerts.Count -eq 0) {
    Write-Host "Nessun alert trovato. Creazione di un report vuoto."
    $securityAlerts += [PSCustomObject]@{ "AlertType" = "N/A"; "State" = "N/A"; "FirstSeen" = "N/A"; "FilePath" = "N/A" }
}

# Esporta in CSV
$outputFile = Join-Path $outputDir "AdvancedSecurityReport_$timeStamp.csv"
$securityAlerts | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Host "Report salvato in: $outputFile"

# Pubblica l'artefatto
$artifactPath = Resolve-Path $outputDir
Write-Host "##vso[artifact.upload containerfolder=$repoName-$timeStamp;artifactname=AdvancedSecurityReports]$artifactPath"

Write-Host "##[section]Finishing: PowerShell Script"
