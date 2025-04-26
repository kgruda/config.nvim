# Helper functions
function Write-Info($message) {
    Write-Host "[INFO] $message" -ForegroundColor Cyan
}
function Write-Ok($message) {
    Write-Host "[OK]   $message" -ForegroundColor Green
}
function Write-ErrorMsg($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}
function Install-Font($fontPath) {
    Write-Info "Installing font: $fontPath"
    $ShellApp = New-Object -ComObject Shell.Application
    $Folder = $ShellApp.Namespace(0x14)  # Windows Fonts special folder
    $Folder.CopyHere($fontPath)
}

# Variables
$customConfigRepo = "https://github.com/kgruda/config.nvim.git"
$nvimConfigPath = "$env:USERPROFILE\AppData\Local\nvim"
$nerdFontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraMono.zip"
$fontName = "FiraMonoNerdFont-Regular.otf"
$fontInstallPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\$fontName"

# Set Execution Policy
try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
    Write-Ok "Execution policy set to allow script execution."
} catch {
    Write-ErrorMsg "Failed to set execution policy."
    exit 1
}

# Step 1: Install Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Git..."
    winget install Git.Git --accept-package-agreements --accept-source-agreements
    Write-Ok "Git installed."
} else {
    Write-Ok "Git already installed."
}

# Step 2: Install Neovim
if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Neovim..."
    winget install Neovim.Neovim --accept-package-agreements --accept-source-agreements
    Write-Ok "Neovim installed."
} else {
    Write-Ok "Neovim already installed."
}

# Step 3: Install Ninja
if (-not (Get-Command ninja -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Ninja..."
    winget install Ninja-build.Ninja --accept-package-agreements --accept-source-agreements
    Write-Ok "Ninja installed."
} else {
    Write-Ok "Ninja already installed."
}

# Step 4: Install LLVM (clang)
if (-not (Get-Command clang -ErrorAction SilentlyContinue)) {
    Write-Info "Installing LLVM (Clang)..."
    winget install -i -e --id LLVM.LLVM --accept-package-agreements --accept-source-agreements
    Write-Ok "LLVM (Clang) installed."
} else {
    Write-Ok "LLVM (Clang) already installed."
}

# Step 5: Install Nerd Font (FiraMono)
if (-not (Test-Path $fontInstallPath)) {
    Write-Info "Downloading Nerd Font (FiraMono)..."
    $tempZip = "$env:TEMP\FiraMono.zip"
    Invoke-WebRequest -Uri $nerdFontUrl -OutFile $tempZip
    Expand-Archive -Path $tempZip -DestinationPath "$env:TEMP\FiraMonoFonts" -Force

    # Install all TTF and OTF fonts properly
    Get-ChildItem "$env:TEMP\FiraMonoFonts" -Include *.ttf, *.otf -Recurse | ForEach-Object {
        Install-Font $_.FullName
    }

    Write-Ok "FiraMono Nerd Font installed and registered."

    # Refresh font cache
    $response = Read-Host "Do you want to refresh font cache now? This will briefly restart Windows Explorer. (Y/N)"
    if ($response -match "^[Yy]$") {
        Write-Info "Refreshing font cache by restarting explorer.exe..."
        try {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Start-Process explorer.exe
            Write-Ok "Font cache refreshed successfully."
        } catch {
            Write-ErrorMsg "Failed to refresh font cache. You may need to restart manually."
        }
    } else {
        Write-Info "Skipping font cache refresh. You may need to restart manually."
    }
} else {
    Write-Ok "FiraMono Nerd Font already installed."
    # Nerd Font Self-Test
    Write-Host "`nVerifying Nerd Font Installation:"
    Write-Host "If your Nerd Font is working, you should see clean symbols below:"
    Write-Host ""
    Write-Host "      "
    Write-Host ""
    Write-Host "If you see squares or question marks instead, double-check your terminal font settings!" -ForegroundColor Yellow
}

# Step 6: Clone Custom NvChad Config
if (-not (Test-Path $nvimConfigPath)) {
    Write-Info "Cloning your custom NvChad config..."
    git clone $customConfigRepo $nvimConfigPath --depth 1
    Write-Ok "Custom config cloned."
} else {
    Write-Ok "Custom config already exists."
}

# Finish
Write-Host "`n`n"
Write-Ok "All done! Launch Neovim with: nvim"
Write-Info "Make sure your terminal is set to use the Nerd Font."
