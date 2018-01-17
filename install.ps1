param(
    [String[]]
    $ModList = (Get-Content $PSScriptRoot\mods.txt),
    [String]
    $ModDirectory = '/opt/factorio/mods',
    [datetime]
    $LastRun = (Get-Content $PSScriptRoot\lastrun)
)
$mods = @()
foreach ($mod in $ModList)
{
    $mod = (Invoke-RestMethod "https://mods.factorio.com/api/mods/$mod")
    if ([datetime]$mod.updated_at -gt $LastRun)
    {
        $finalLocation = Join-Path -Path $ModDirectory -ChildPath $mod.releases[0].file_name
        $oldMod = Get-ChildItem -Path $ModDirectory -Filter ("*{0}*" -f $mod.name)
        $dl = "https://mods.factorio.com" + $mod.releases[0].download_url
        Invoke-WebRequest -Uri $dl -OutFile $finalLocation
        $oldMod | Remove-Item 
    }
    $mods += New-Object psobject -Property @{
        prettyname = $mod.title
        name       = $mod.name
        version    = $mod.releases[0].version
        updatedOn  = $mod.updated_at
    }
}
Out-File -InputObject (Get-Date) -FilePath ("$PSScriptRoot\lastrun")
Out-File -FilePath ("$PSScriptRoot\modlist.json") -InputObject ($mods | ConvertTo-Json)
