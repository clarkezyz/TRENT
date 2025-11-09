#!/data/data/com.termux/files/usr/bin/bash
# TRENT Setup Script
# Configures Termux for bidirectional SSH access with home computer

set -e  # Exit on error

echo "==================================="
echo "  TRENT Setup for Termux"
echo "==================================="
echo ""
echo "This script will:"
echo "  - Install required packages"
echo "  - Generate SSH keys"
echo "  - Configure SSH server"
echo "  - Set up shell aliases"
echo "  - Add TRENT helper commands"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled"
    exit 1
fi

# Collect user information
echo ""
echo "==================================="
echo "  Home Computer Configuration"
echo "==================================="
echo ""
echo "Enter your home computer details:"
echo ""
read -p "Username (e.g., john): " HOME_USER
read -p "Domain or IP (e.g., home.example.com): " HOME_DOMAIN
echo ""
echo "Configuration:"
echo "  User: $HOME_USER"
echo "  Domain: $HOME_DOMAIN"
echo ""
read -p "Is this correct? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled. Run script again to re-enter details."
    exit 1
fi

# Update packages
echo ""
echo "[1/7] Updating package repositories..."
pkg update -y

echo "[2/7] Installing required packages..."
pkg install -y openssh python git curl zsh termux-api

# Generate SSH key if it doesn't exist
echo "[3/7] Setting up SSH keys..."
if [ ! -f ~/.ssh/id_ed25519 ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
    echo "✓ SSH key generated"
else
    echo "✓ SSH key already exists"
fi

# Create authorized_keys file
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Setup SSH server
echo "[4/7] Configuring SSH server..."
if [ ! -f $PREFIX/etc/ssh/sshd_config ]; then
    ssh-keygen -A
fi

# Start SSH server
echo "[5/7] Starting SSH server on port 8022..."
pkill sshd 2>/dev/null || true
sshd
echo "✓ SSH server running"

# Install Oh My Zsh
echo "[6/7] Installing Oh My Zsh..."
if [ ! -d ~/.oh-my-zsh ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    chsh -s zsh
    echo "✓ Oh My Zsh installed"
else
    echo "✓ Oh My Zsh already installed"
fi

# Setup TRENT aliases and helper functions
echo "[7/7] Setting up TRENT commands..."

# Add TRENT aliases to .zshrc (with variable expansion)
cat >> ~/.zshrc << EOF

# ============================================
# TRENT System - Bidirectional SSH
# ============================================

# Aliases configured during setup
alias home="ssh $HOME_USER@$HOME_DOMAIN"
alias tunnel="ssh -R 8022:localhost:8022 $HOME_USER@$HOME_DOMAIN"
alias home-tunnel="ssh -Y -R 8022:localhost:8022 $HOME_USER@$HOME_DOMAIN"
EOF

# Add TRENT helper functions (no variable expansion needed)
cat >> ~/.zshrc << 'EOF'

# TRENT Helper Commands
trent() {
    case "$1" in
        status)
            echo "TRENT Status:"
            echo "============="
            echo ""
            echo "SSH Server:"
            if pgrep -x sshd > /dev/null; then
                echo "  ✓ Running (port 8022)"
            else
                echo "  ✗ Not running"
                echo "  Start with: trent start"
            fi
            echo ""
            echo "Tunnel Connection:"
            echo "  Run 'tunnel' to establish reverse tunnel"
            echo ""
            echo "Your Info:"
            echo "  Username: $(whoami)"
            echo "  IP: $(ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "Not connected to WiFi")"
            ;;
        start)
            echo "Starting SSH server..."
            sshd
            echo "✓ SSH server started on port 8022"
            ;;
        stop)
            echo "Stopping SSH server..."
            pkill sshd
            echo "✓ SSH server stopped"
            ;;
        restart)
            echo "Restarting SSH server..."
            pkill sshd 2>/dev/null || true
            sshd
            echo "✓ SSH server restarted"
            ;;
        user)
            echo "Termux username: $(whoami)"
            ;;
        ip)
            echo "Phone IP address:"
            ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "Not connected to WiFi"
            ;;
        key)
            echo "Your public SSH key (share this with computers):"
            echo ""
            cat ~/.ssh/id_ed25519.pub
            ;;
        help|*)
            echo "TRENT - Bidirectional SSH System"
            echo "================================="
            echo ""
            echo "Usage: trent <command>"
            echo ""
            echo "Commands:"
            echo "  status    - Show TRENT connection status"
            echo "  start     - Start SSH server on phone"
            echo "  stop      - Stop SSH server"
            echo "  restart   - Restart SSH server"
            echo "  user      - Show your Termux username"
            echo "  ip        - Show phone's current IP address"
            echo "  key       - Display your public SSH key"
            echo "  help      - Show this help message"
            echo ""
            echo "Connection Aliases:"
            echo "  home         - SSH to your home computer"
            echo "  tunnel       - SSH with reverse tunnel (allows computer to SSH back)"
            echo "  home-tunnel  - SSH with X11 forwarding + reverse tunnel"
            echo ""
            echo "Examples:"
            echo "  trent status          # Check if everything is running"
            echo "  home                  # Connect to home computer"
            echo "  tunnel                # Connect with reverse tunnel"
            echo "  trent key             # Show your public key to add to computer"
            echo ""
            echo "From your computer (when tunnel is active):"
            echo "  ssh -p 8022 $(whoami)@localhost"
            echo ""
            ;;
    esac
}

# Auto-start SSH server on shell launch
if ! pgrep -x sshd > /dev/null; then
    sshd 2>/dev/null
fi

EOF

echo ""
echo "==================================="
echo "  Setup Complete!"
echo "==================================="
echo ""
echo "Your Termux username: $(whoami)"
echo "SSH server running on port 8022"
echo ""
echo "Configured aliases:"
echo "  home         → ssh $HOME_USER@$HOME_DOMAIN"
echo "  tunnel       → ssh -R 8022:localhost:8022 $HOME_USER@$HOME_DOMAIN"
echo "  home-tunnel  → ssh -Y -R 8022:localhost:8022 $HOME_USER@$HOME_DOMAIN"
echo ""
echo "Your public key (add this to your computer's authorized_keys):"
echo ""
cat ~/.ssh/id_ed25519.pub
echo ""
echo "Next steps:"
echo "  1. Add the public key above to your computer's ~/.ssh/authorized_keys"
echo "  2. Add your computer's public key to ~/.ssh/authorized_keys on this phone"
echo "  3. Restart shell: exec zsh"
echo "  4. Test connection: home"
echo ""
echo "Run 'trent help' anytime for usage info"
echo ""
