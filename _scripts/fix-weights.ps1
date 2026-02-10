# Fix weight patterns in all pallet files
Get-ChildItem -Path "C:\dev\DAO\substrate-runtime\pallets" -Recurse -Filter "lib.rs" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $fixed = $content -replace 'reads_writes\((\d+), (\d+)\)\]', 'reads_writes($1, $2))]'
    Set-Content -Path $_.FullName -Value $fixed -NoNewline
    Write-Host "Fixed: $($_.FullName)"
}
Write-Host "All weight patterns fixed!"
