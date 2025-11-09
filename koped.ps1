# koped.ps1 (VERSI AMAN - Bahasa Indonesia)
# Alur: unduh .cmd -> scan isi -> jika aman jalankan di cmd /K -> tanya hapus
# Skrip ini TIDAK akan mengeksekusi file yang berisi pola bypass lisensi / modifikasi registry.

[System.Net.ServicePointManager]::SecurityProtocol =
    [System.Net.SecurityProtocolType]::Tls12

# URL file .cmd (sama pola aslinya)
$DownloadURL = 'https://raw.githubusercontent.com/Sincan2/koped/refs/heads/main/koped.cmd'
$FilePath = Join-Path $env:TEMP 'IDMA.cmd'
$LogPath  = Join-Path $env:TEMP 'koped-safe.log'

function Log($txt) {
    $line = "{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $txt
    $line | Out-File -FilePath $LogPath -Append -Encoding UTF8
    Write-Host $txt
}

Log "Mulai: mengunduh $DownloadURL ..."
try {
    Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing -OutFile $FilePath -ErrorAction Stop
    Log "✅ Berhasil unduh ke: $FilePath"
} catch {
    Log "❌ Gagal mengunduh: $($_.Exception.Message)"
    Write-Host "Gagal mengunduh file. Cek koneksi atau URL."
    Read-Host "Tekan ENTER untuk keluar..." > $null
    exit 1
}

if (-not (Test-Path $FilePath)) {
    Log "❌ File tidak ada setelah unduh."
    Read-Host "Tekan ENTER untuk keluar..." > $null
    exit 1
}

$size = (Get-Item $FilePath).Length
Log "Info file: $FilePath ($size bytes)."

# Pola yang dianggap berisiko — tambahkan jika perlu
$dangerPatterns = @(
    'hkcu\software\downloadmanager',
    'hklm\software\internet download manager',
    'hklm\software\wow6432node\internet download manager',
    'hkey_local_machine',
    'hkey_current_user',
    'reg add',
    'reg delete',
    'regedit',
    'setacl',
    'takeown',
    'takeownership',
    'advintdriverenabled',
    'serial',
    'sc create',
    'sc stop',
    'sebackupprivilege',
    'setacl',
    'runas',
    'openasadmin'
)

# Baca isi dan periksa pola
try {
    $contents = Get-Content -LiteralPath $FilePath -Raw -ErrorAction Stop
} catch {
    Log "❌ Gagal baca file: $($_.Exception.Message)"
    Read-Host "Tekan ENTER untuk keluar..." > $null
    exit 1
}

$lc = $contents.ToLowerInvariant()
$found = @()
foreach ($pat in $dangerPatterns) {
    if ($lc.Contains($pat.ToLower())) {
        $found += $pat
    }
}

if ($found.Count -gt 0) {
    Log "⚠️ Terdeteksi pola berisiko di file:"
    foreach ($f in $found) { Log "   - $f" }
    Write-Host ""
    Write-Host "File mengandung keyword yang berpotensi memodifikasi registry / lisensi."
    Write-Host "Untuk keamanan dan kepatuhan, EKSEKUSI DIBATALKAN."
    Write-Host "Lokasi file: $FilePath"
    Write-Host "Jika Anda yakin aman, periksa file manual (Notepad) dan jalankan manual."
    Write-Host ""
    Log "Aksi: eksekusi dibatalkan."
    Read-Host "Tekan ENTER untuk keluar..." > $null
    exit 2
}

# Jika aman -> jalankan pada jendela baru agar terlihat output
Log "✅ Tidak ditemukan pola berbahaya. Menjalankan file di jendela baru (cmd.exe /K)."

try {
    Start-Process -FilePath "cmd.exe" -ArgumentList "/K `"$FilePath`"" -WindowStyle Normal
    Log "cmd.exe diluncurkan dengan argumen /K $FilePath"
} catch {
    Log "❌ Gagal menjalankan cmd.exe: $($_.Exception.Message)"
    Read-Host "Tekan ENTER untuk keluar..." > $null
    exit 3
}

# Tanyakan apakah ingin menghapus file .cmd setelah run
$ans = Read-Host "Hapus file $FilePath dari TEMP? (y/N)"
if ($ans.Trim().ToLower() -eq 'y') {
    try { Remove-Item -LiteralPath $FilePath -Force -ErrorAction Stop; Log "File dihapus: $FilePath" }
    catch { Log "⚠️ Gagal hapus file: $($_.Exception.Message)" }
} else {
    Log "File dibiarkan: $FilePath"
}

Log "Selesai."
Read-Host "Tekan ENTER untuk keluar..." > $null
