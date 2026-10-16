# Genera blacklist.zip en la raiz del repositorio con el codigo listo para Elastic Beanstalk.
# Uso (desde cualquier carpeta):  powershell -ExecutionPolicy Bypass -File terraform\scripts\empaquetar.ps1
#
# Usa tar.exe (incluido en Windows 10/11) porque Compress-Archive de PowerShell 5
# guarda las rutas con "\" y en Linux los archivos quedan con nombres rotos.

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Push-Location $root

try {
    $zip = "blacklist.zip"
    if (Test-Path $zip) { Remove-Item $zip }

    $items = @("Dockerfile", ".dockerignore", "application.py", "requirements.txt", "app")
    if (Test-Path ".ebextensions") { $items += ".ebextensions" }

    foreach ($i in $items) {
        if (-not (Test-Path $i)) { throw "No se encontro '$i' en $root" }
    }

    tar -a -c -f $zip --exclude "__pycache__" --exclude "*.pyc" @items
    if ($LASTEXITCODE -ne 0) { throw "tar fallo con codigo $LASTEXITCODE" }

    Write-Host "Zip creado: $(Join-Path $root $zip)"
    tar -tf $zip
}
finally {
    Pop-Location
}
