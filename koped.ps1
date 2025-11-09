# koded.ps1 - versi aman & transparan
# Mengunduh file CMD dari GitHub, menjalankan, dan menampilkan log tanpa auto-close.

[System.Net.ServicePointManager]::SecurityProtocol =
    [System.Net.SecurityProtocolType]::Tls12

$DownloadURL = 'https://raw.githubusercontent.com/Sincan2/koped/refs/heads/main/koped.cmd'
$FilePath = "$env:TEMP\IDMA.cmd"

Write-Host "Mengunduh file dari $DownloadURL ..."
try {
    Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing -OutFile $FilePath -ErrorAction Stop
    Write-Host "✅ Berhasil diunduh ke: $FilePath"
} catch {
    Write-Host "❌ Gagal mengunduh file: $($_.Exception.Message)" -ForegroundColor Red
    pause
    exit
}

if (Test-Path $FilePath) {
    Write-Host "Menjalankan file CMD..."
    # Jalankan CMD di jendela baru agar tidak menutup PowerShell
    Start-Process -FilePath "cmd.exe" -ArgumentList "/K `"$FilePath`""
    Write-Host "CMD sudah dijalankan. File tidak akan dihapus otomatis."
} else {
    Write-Host "❌ File tidak ditemukan: $FilePath" -ForegroundColor Red
}

pause
