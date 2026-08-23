# Minimal static file server (no external dependencies).
# Used by serve.sh to preview a rendered Quarto output directory
# (e.g. _site/ or docs/) without needing Python or a second quarto
# preview instance (quarto only allows one preview per project).

param(
    [string]$Root,
    [int]$Port
)

$Root = (Resolve-Path $Root).Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Output "Serving $Root on http://localhost:$Port/"

$mimeMap = @{
    ".html"="text/html"; ".htm"="text/html"; ".css"="text/css"; ".js"="application/javascript";
    ".json"="application/json"; ".png"="image/png"; ".jpg"="image/jpeg"; ".jpeg"="image/jpeg";
    ".gif"="image/gif"; ".svg"="image/svg+xml"; ".woff"="font/woff"; ".woff2"="font/woff2";
    ".ttf"="font/ttf"; ".ico"="image/x-icon"; ".xml"="application/xml"; ".pdf"="application/pdf";
    ".map"="application/json"; ".txt"="text/plain"; ".csv"="text/csv"; ".webmanifest"="application/manifest+json"
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $urlPath = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath)
        if ($urlPath -eq "/") { $urlPath = "/index.html" }
        $filePath = Join-Path $Root ($urlPath.TrimStart("/"))
        if (Test-Path $filePath -PathType Container) {
            $filePath = Join-Path $filePath "index.html"
        }
        $fullFilePath = [System.IO.Path]::GetFullPath($filePath)
        if (-not $fullFilePath.StartsWith($Root)) {
            $response.StatusCode = 403
            $response.Close()
            continue
        }
        if (Test-Path $fullFilePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($fullFilePath).ToLower()
            $contentType = $mimeMap[$ext]
            if (-not $contentType) { $contentType = "application/octet-stream" }
            $bytes = [System.IO.File]::ReadAllBytes($fullFilePath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            if ($request.HttpMethod -ne "HEAD") {
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $urlPath")
            $response.ContentLength64 = $errBytes.Length
            if ($request.HttpMethod -ne "HEAD") {
                $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
            }
        }
    } catch {
        Write-Output "Error: $_"
    } finally {
        try { $response.Close() } catch {}
    }
}
