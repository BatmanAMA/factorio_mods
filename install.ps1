param(
    [String[]]
    $ModList = (Get-Content $PSScriptRoot\mods.txt),
    [String]
    $ModDirectory = '/opt/factorio/mods',
    [datetime]
    $LastRun = [DateTime]::MinValue,
    [string]
    $GameVersion = '0.16'
)

$mods = @()
foreach ($mod in $ModList) {
    $oMod = (Invoke-RestMethod "https://mods.factorio.com/api/mods/$mod")
    $curRelease = $oMod.releases[-1]
    if ([datetime]$curRelease.released_at -gt $LastRun -and $curRelease.info_json.factorio_version -eq $GameVersion) {
        $finalLocation = Join-Path -Path $ModDirectory -ChildPath $curRelease.file_name
        $oldMod = Get-ChildItem -Path $ModDirectory -Filter ("*{0}*" -f $oMod.name)
        $dl = "https://mods.factorio.com" + $curRelease.download_url
        Invoke-WebRequest -Uri $dl -OutFile $finalLocation
        $oldMod | Remove-Item 
    }
    $mods += New-Object psobject -Property @{
        prettyname = $oMod.title
        name       = $oMod.name
        version    = $curRelease.version
        updatedOn  = $curRelease.released_at
    }
}
Out-File -InputObject (Get-Date) -FilePath ("$PSScriptRoot\lastrun")
Out-File -FilePath ("$PSScriptRoot\modlist.json") -InputObject ($mods | ConvertTo-Json)
