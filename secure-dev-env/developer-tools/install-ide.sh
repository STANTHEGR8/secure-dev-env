#!/bin/bash
# IDE and Editor Installation

set -e

echo "Installing development IDEs and editors..."

# ===== VISUAL STUDIO CODE =====
echo "Installing Visual Studio Code..."

# Add Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg

# Add VS Code repository
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
    sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

# Install VS Code
sudo apt update
sudo apt install -y code

# ===== VIM =====
echo "Installing Vim..."
sudo apt install -y vim vim-runtime vim-doc

# Configure basic vimrc
cat > ~/.vimrc << 'EOF'
" Basic Vim Configuration
syntax on
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set autoindent
set mouse=a
set clipboard=unnamedplus
set hlsearch
set incsearch
set ignorecase
set smartcase
colorscheme desert
EOF

# ===== NEOVIM (optional) =====
echo "Installing Neovim (optional)..."
sudo apt install -y neovim

echo ""
echo "IDEs and editors installed!"
echo ""
echo "Launch VS Code: code"
echo "Launch Vim: vim"
echo "Launch Neovim: nvim"