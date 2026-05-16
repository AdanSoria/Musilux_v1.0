# Ejecuta todas las pruebas automatizadas del proyecto Flutter.
# Uso desde la raiz del proyecto:  .\scripts\test_flutter.ps1
# Uso con cobertura:                .\scripts\test_flutter.ps1 -Coverage

param(
    [switch]$Coverage
)

$projectDir = Join-Path $PSScriptRoot "..\musilux"

Write-Host ""
Write-Host "=== Musilux — Tests Flutter ===" -ForegroundColor Cyan
Write-Host "Directorio: $projectDir"
Write-Host ""

Push-Location $projectDir
try {
    if ($Coverage) {
        flutter test --reporter=expanded --coverage
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "Reporte de cobertura generado en: coverage/lcov.info" -ForegroundColor Green
        }
    } else {
        flutter test --reporter=expanded
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Todos los tests pasaron." -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Algunos tests fallaron. Revisa la salida arriba." -ForegroundColor Red
    }
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
