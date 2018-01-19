param(
    [String[]]
    $ModList = (Get-Content $PSScriptRoot/mods.txt),
    [String]
    $ModDirectory = '/opt/factorio/mods',
    [datetime]
    $LastRun = [DateTime]::MinValue,
    [string]
    $GameVersion = '0.16'
)

$FactorioList = Get-Content $ModDirectory/mod-list.json | ConvertFrom-Json
foreach ($mod in $ModList) {
    $oMod = (Invoke-RestMethod "https://mods.factorio.com/api/mods/$mod")
    $curRelease = $oMod.releases[-1]
    if (
        [datetime]$curRelease.released_at -gt $LastRun -and 
        $curRelease.info_json.factorio_version -eq $GameVersion
    ) {
        $finalLocation = Join-Path -Path $ModDirectory -ChildPath $curRelease.file_name
        $oldMod = Get-ChildItem -Path $ModDirectory -Filter ("*{0}*" -f $oMod.name)
        $dl = "https://mods.factorio.com" + $curRelease.download_url
        Invoke-WebRequest -Uri $dl | Out-File $finalLocation -Encoding default -Force
        $oldMod | Remove-Item 
    }
    $FactorioList.mods += New-Object psobject -Property @{
        name    = $oMod.name
        enabled = $true
    }
}

Out-File -InputObject (Get-Date) -FilePath ("$PSScriptRoot/lastrun")
Out-File -FilePath ("$ModDirectory/mod-list.json") -InputObject ($FactorioList | ConvertTo-Json)
