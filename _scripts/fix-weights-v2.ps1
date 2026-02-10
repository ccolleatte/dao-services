# Fix Weight API syntax errors in all pallets
# Adds missing closing parenthesis before )]

$palletsPath = "C:\dev\DAO\substrate-runtime\pallets"

Get-ChildItem -Path $palletsPath -Recurse -Filter "lib.rs" | ForEach-Object {
    $file = $_.FullName
    Write-Host "Processing: $file" -ForegroundColor Cyan

    $content = Get-Content $file -Raw
    $originalContent = $content

    # Fix: .reads_writes(N, M)] should be .reads_writes(N, M)))]
    $content = $content -replace '\.reads_writes\((\d+),\s*(\d+)\)\]', '.reads_writes($1, $2)))]'

    # Fix: .reads(N)] should be .reads(N)))]
    $content = $content -replace '\.reads\((\d+)\)\]', '.reads($1)))]'

    # Fix: .writes(N)] should be .writes(N)))]
    $content = $content -replace '\.writes\((\d+)\)\]', '.writes($1)))]'

    if ($content -ne $originalContent) {
        Set-Content -Path $file -Value $content -NoNewline
        Write-Host "  ✓ Fixed weight syntax" -ForegroundColor Green
    } else {
        Write-Host "  - No changes needed" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "All pallets processed!" -ForegroundColor Green
