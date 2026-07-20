$j = Get-Content -Raw 'C:\Users\burak\.cursor\projects\c-Users-burak-OneDrive-Desktop-LifeOS\agent-tools\d8ecd1f4-d29d-4e92-8f80-a31bf55616a9.txt' | ConvertFrom-Json
$stableHash = $j.current_release.stable
$rel = $j.releases | Where-Object { $_.hash -eq $stableHash } | Select-Object -First 1
Write-Output ("VERSION=" + $rel.version)
Write-Output ("ARCHIVE=" + $rel.archive)
Write-Output ("BASEURL=" + $j.base_url)
