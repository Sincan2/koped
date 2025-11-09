# koped-safe.ps1
# Versi aman & transparan dari koped.ps1
# Alur: unduh .cmd -> scan isi -> jika aman jalankan -> jika diminta hapus
# WARNING: Skrip ini TIDAK akan mengeksekusi file yang berisi pola bypass lisensi.

[System.Net.ServicePointManager]::SecurityProtocol =
    [System.Net.SecurityProtocolType]::Tls12

# URL yang akan diunduh (sama seperti aslinya)
$DownloadURL = 'https://raw.githubusercontent.com/Sincan2/koped/refs/heads/main/koped.cmd'
$FilePath = Join-Path $env:TEMP 'IDMA.cmd'
$LogPath = Join-Path $env:TEMP 'koped-safe.log'

Function Log {
    param([string]$Text)
    $t = "{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $Text
    $t | Out-File -FilePath $LogPath -Append -Encoding UTF8
    Write-Host $Text
}

Log "Mulai: mengunduh $DownloadURL ke $FilePath ..."

try {
    # Unduh (lebih kompatibel: Invoke-WebRequest)
    Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing -OutFile $FilePath -ErrorAction Stop
    Log "✅ Berhasil unduh file."
} catch {
    Log "❌ Gagal mengunduh: $($_.Exception.Message)"
    Write-Host "Tekan ENTER untuk keluar..." ; Read-Host > $null
    exit 1
}

# Pastikan file ada dan ukurannya wajar
if (-not (Test-Path $FilePath)) {
    Log "❌ File tidak ditemukan setelah unduh."
    Read-Host "Tekan ENTER untuk keluar..." > $null
    exit 1
}

$size = (Get-Item $FilePath).Length
Log "Info file: $FilePath ($size bytes)."

# BACA ISI dan scan untuk pola berisiko (kamu bisa tambahkan kata kunci lain)
$dangerPatterns = @(
    'HKCU\\Software\\DownloadManager',
    'HKLM\\SOFTWARE\\Wow6432Node\\Internet Download Manager',
    'HKLM\\Software\\Internet Download Manager',
    'Serial', 'AdvIntDriverEnabled', 'TakeOwnership',
    'reg add', 'reg delete', 'reg query', 'regedit',
    'SetRegistry', 'HKEY_LOCAL_MACHINE', 'HKEY_CURRENT_USER'
)

$contents = Get-Content -LiteralPath $FilePath -Raw -ErrorAction SilentlyContinue

if ($null -eq $contents) {
    Log "❌ Gagal baca isi file. Mungkin file corrupt."
    Read-Host "Tekan ENTER untuk keluar..." > $null
    exit 1
}

# Normalisasi untuk cek (case-insensitive)
$lc = $contents.ToLowerInvariant()

$found = @()
foreach ($pat in $dangerPatterns) {
    if ($lc.Contains($pat.ToLower())) {
        $found += $pat
    }
}

if ($found.Count -gt 0) {
    Log "⚠️ DITEMUKAN pola berisiko di dalam file:"
    foreach ($f in $found) { Log "   - $f" }
    Write-Host ""
    Write-Host "File berisi perintah/keyword yang terindikasi berpotensi untuk memodifikasi registry / lisensi."
    Write-Host "Untuk alasan keamanan dan kepatuhan, skrip ini TIDAK akan mengeksekusi file tersebut."
    Write-Host ""
    Write-Host "Lokasi file yang diunduh: $FilePath"
    Write-Host "Jika Anda yakin file aman, buka dan periksa isinya manual (Notepad), atau hapus keyword berbahaya, lalu jalankan manual."
    Write-Host ""
    Log "Aksi: eksekusi DIBATALKAN karena pola berisiko."
    Read-Host "Tekan ENTER untuk keluar..." > $null
    exit 2
}

# Jika aman -> jalankan di jendela CMD baru dengan /K supaya terlihat output dan tidak menutup langsung
Log "✅ Tidak ditemukan pola berbahaya. Menjalankan file di jendela baru (cmd.exe /K)."
try {
    Start-Process -FilePath "cmd.exe" -ArgumentList "/K `"$FilePath`"" -WindowStyle Normal
    Log "Proses cmd.exe diluncurkan."
} catch {
    Log "❌ Gagal jalankan cmd.exe: $($_.Exception.Message)"
    Read-Host "Tekan ENTER untuk keluar..." > $null
    exit 3
}

# Tanyakan apakah ingin menghapus file setelah run
Write-Host ""
$ans = Read-Host "Hapus file $FilePath dari TEMP? (y/N)"
if ($ans.Trim().ToLower() -eq 'y') {
    try {
        Remove-Item -LiteralPath $FilePath -Force -ErrorAction Stop
        Log "File dihapus: $FilePath"
    } catch {
        Log "⚠️ Gagal hapus file: $($_.Exception.Message)"
    }
} else {
    Log "File dibiarkan di: $FilePath"
}

Log "Selesai."
Read-Host "Tekan ENTER untuk keluar..." > $null
