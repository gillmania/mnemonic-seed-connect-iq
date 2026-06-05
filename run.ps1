$sdk  = "C:\Users\46707\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.1.0-2026-03-09-6a872a80b\bin"
$base = $PSScriptRoot
$key  = "$base\developer_key.der"
$jungle = "$base\monkey.jungle"

$devices = @(
    "fr955","fr965","fr970","fr265","fr265s","fr255","fr165",
    "fenix847mm","fenix843mm","fenix8solar47mm","fenix8solar51mm",
    "fenix7","fenix7pro","fenix7x","fenixe",
    "epix2","epix2pro47mm","epix2pro51mm",
    "instinct3amoled45mm","instinct3amoled50mm",
    "instinct3solar45mm","instincte40mm","instincte45mm",
    "venu3","venu3s","venux1","vivoactive5","vivoactive6",
    "marq2","d2mach1","descentg2","enduro3","approachs7047mm"
)

Write-Host ""
Write-Host "=== Mnemonic Seed – välj enhet ==="
for ($i = 0; $i -lt $devices.Count; $i++) {
    Write-Host ("  {0,2}. {1}" -f ($i+1), $devices[$i])
}
Write-Host ""
$choice = Read-Host "Nummer"
$idx = [int]$choice - 1
if ($idx -lt 0 -or $idx -ge $devices.Count) { Write-Host "Ogiltigt val."; exit 1 }

$d = $devices[$idx]
Write-Host "Bygger för $d ..."
$out = "$base\bin\run_${d}.prg"
$result = & "$sdk\monkeyc.bat" -d $d -f $jungle -o $out -y $key 2>&1
if ($result -notmatch "BUILD SUCCESSFUL") { Write-Host "Build misslyckades: $result"; exit 1 }
Write-Host "Startar simulatorn ..."
Start-Process "$sdk\monkeydo.bat" -ArgumentList $out,$d
