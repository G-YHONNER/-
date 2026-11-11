# Servidor local para pruebas en la misma red Wi-Fi
$port = 8080
$folder = $PSScriptRoot
$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi*' -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
if (!$ip) { $ip = "127.0.0.1" }

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
if ($ip -ne "127.0.0.1") {
    $listener.Prefixes.Add("http://${ip}:$port/")
}

try {
    $listener.Start()
} catch {
    Write-Host "Error iniciando el servidor: $($_.Exception.Message)"
    exit 1
}

Write-Host "=========================================================="
Write-Host "  🌹 SERVIDOR LOCAL ACTIVO" -ForegroundColor Green
Write-Host "=========================================================="
Write-Host "En tu PC abre:     http://localhost:$port/index.html" -ForegroundColor Cyan
Write-Host "En tu CELULAR abre: http://${ip}:$port/remote.html" -ForegroundColor Yellow
Write-Host "=========================================================="
Write-Host "Presiona Ctrl+C para detener el servidor.`n"

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $urlPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($urlPath)) { $urlPath = "index.html" }

        $filePath = Join-Path $folder $urlPath

        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            switch ($ext) {
                ".html" { $response.ContentType = "text/html; charset=utf-8" }
                ".css"  { $response.ContentType = "text/css; charset=utf-8" }
                ".js"   { $response.ContentType = "application/javascript; charset=utf-8" }
                ".png"  { $response.ContentType = "image/png" }
                ".jpg"  { $response.ContentType = "image/jpeg" }
                default { $response.ContentType = "application/octet-stream" }
            }
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("Archivo no encontrado")
            $response.OutputStream.Write($msg, 0, $msg.Length)
        }
        $response.OutputStream.Close()
    } catch {
        # Ignorar errores de desconexión del cliente
    }
}

