@echo off
REM IDM Helper - Bahasa Indonesia (Ringan & Aman)
REM Fungsional: Elevate ke admin, cek PowerShell, cek/terminate idman.exe,
REM             toggle Windows Firewall, buka halaman download resmi IDM.

:: --- Elevasi (jika belum admin) ---
:: Jika tidak berjalan sebagai admin, relaunch menggunakan PowerShell Start-Process -Verb RunAs
openAsAdmin=0
whoami /groups | find "S-1-5-32-544" >nul 2>&1
if not %errorlevel%==0 (
  powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

:: --- Set environment ---
setlocal enabledelayedexpansion
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

:: --- Fungsi bantu ---
:cek_powershell
if exist "%PS%" (
  echo PowerShell ditemukan.
) else (
  echo PowerShell TIDAK ditemukan. Beberapa fitur mungkin tidak berfungsi.
)
goto :eof

:cek_idm_terpasang
REM Cek lokasi instalasi umum (x64/x86)
set "IDM_PATH="
if exist "%ProgramFiles%\Internet Download Manager\IDMan.exe" set "IDM_PATH=%ProgramFiles%\Internet Download Manager\IDMan.exe"
if exist "%ProgramFiles(x86)%\Internet Download Manager\IDMan.exe" set "IDM_PATH=%ProgramFiles(x86)%\Internet Download Manager\IDMan.exe"

if defined IDM_PATH (
  echo IDM terpasang di: %IDM_PATH%
) else (
  echo IDM tidak ditemukan di lokasi standar.
  echo Untuk mengunduh IDM resmi, pilih opsi [4].
)
goto :eof

:stop_idm
echo Memeriksa proses idman.exe...
tasklist /fi "imagename eq idman.exe" | findstr /i "idman.exe" >nul 2>&1
if %errorlevel%==0 (
  echo Proses idman.exe sedang berjalan. Mencoba hentikan...
  taskkill /f /im idman.exe >nul 2>&1
  if %errorlevel%==0 (echo idman.exe berhasil dihentikan.) else (echo Gagal menghentikan idman.exe.)
) else (
  echo idman.exe tidak berjalan.
)
goto :eof

:toggle_firewall
REM Toggle Firewall: baca status lalu ubah
for /f "tokens=2 delims=:" %%A in ('netsh advfirewall show allprofiles state ^| findstr /i "State"') do set FWSTATE=%%A
set FWSTATE=%FWSTATE: =%
if /i "%FWSTATE%"=="ON" (
  echo Menonaktifkan semua profil Windows Firewall...
  netsh advfirewall set allprofiles state off
  echo Firewall dimatikan.
) else (
  echo Mengaktifkan semua profil Windows Firewall...
  netsh advfirewall set allprofiles state on
  echo Firewall diaktifkan.
)
goto :eof

:open_idm_site
echo Membuka halaman download IDM resmi...
start "" "https://www.internetdownloadmanager.com/download.html"
goto :eof

:readme
echo.
echo ====== Informasi (Ringkas) ======
echo - Skrip ini TIDAK melakukan aktivasi atau bypass.
echo - Gunakan installer resmi IDM untuk pemasangan/aktivasi.
echo - Jika antivirus memblokir, nonaktifkan sementara proteksi setelah memastikan file aman.
echo ==================================
echo.
pause
goto :eof

:: ----- MENU UTAMA -----
:menu
cls
echo ==========================================
echo      IDM Helper - Sincan2
echo ==========================================
echo 1. Cek apakah PowerShell tersedia
echo 2. Cek apakah IDM terpasang
echo 3. Hentikan proses IDM (idman.exe) jika berjalan
echo 4. Buka halaman download IDM resmi
echo 5. Toggle Windows Firewall (ON/OFF)
echo 6. Readme singkat
echo 7. Keluar
echo ==========================================
set /p choice="Pilih opsi [1-7] > "
if "%choice%"=="1" call :cek_powershell & pause & goto menu
if "%choice%"=="2" call :cek_idm_terpasang & pause & goto menu
if "%choice%"=="3" call :stop_idm & pause & goto menu
if "%choice%"=="4" call :open_idm_site & goto menu
if "%choice%"=="5" call :toggle_firewall & pause & goto menu
if "%choice%"=="6" call :readme & goto menu
if "%choice%"=="7" exit /b
goto menu
