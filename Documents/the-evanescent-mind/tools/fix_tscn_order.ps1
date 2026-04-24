$proj = 'C:\Users\jakes\Documents\the-evanescent-mind'
$files = Get-ChildItem $proj -Recurse -Include '*.tscn' | Where-Object { $_.FullName -notlike '*\addons\*' }
$fixed = 0
foreach ($file in $files) {
    $lines = [System.IO.File]::ReadAllLines($file.FullName, [System.Text.UTF8Encoding]::new($false))
    if ($lines.Count -eq 0) { continue }
    $firstExt = -1; $firstSub = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($firstExt -eq -1 -and $lines[$i] -match '^\[ext_resource ') { $firstExt = $i }
        if ($firstSub -eq -1 -and $lines[$i] -match '^\[sub_resource ') { $firstSub = $i }
    }
    if ($firstExt -eq -1 -or $firstSub -eq -1 -or $firstExt -lt $firstSub) { continue }
    $extLines = @($lines | Where-Object { $_ -match '^\[ext_resource ' })
    $otherLines = @($lines[1..($lines.Count-1)] | Where-Object { $_ -notmatch '^\[ext_resource ' })
    $out = [System.Collections.Generic.List[string]]::new()
    $out.Add($lines[0]); $out.Add('')
    $extLines | ForEach-Object { $out.Add($_) }
    $out.Add('')
    $pb = $true
    foreach ($ol in $otherLines) {
        $ib = ($ol.Trim() -eq '')
        if ($ib -and $pb) { continue }
        $out.Add($ol); $pb = $ib
    }
    [System.IO.File]::WriteAllLines($file.FullName, $out, [System.Text.UTF8Encoding]::new($false))
    $fixed++; Write-Host ('Fixed: ' + $file.Name)
}
Write-Host ('Done: ' + $fixed + ' file(s) fixed.')
