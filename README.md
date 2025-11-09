# TRENT

**Bidirectional SSH access between your Android phone and home computer**

TRENT creates a persistent SSH connection that works in both directions - your phone can SSH to your home computer, and your home computer can SSH back to your phone through a reverse tunnel. Works anywhere, on any network, despite carrier NAT.

Named after the Ted Lasso character: "He's here, he's there, he's every-fucking-where."

---

## What This Does

Traditional problem: You can SSH from your phone to your computer, but your computer can't SSH back to your phone because cellular carriers use Carrier-Grade NAT (CGNAT). No port forwarding, no direct access.

TRENT's solution: Phone initiates an outbound connection (which always works) and creates a reverse tunnel that allows the computer to connect back through that tunnel.

**Result:**
- SSH from phone to home computer from anywhere
- SSH from home computer to phone (through reverse tunnel)
- Full Linux environment on Android (Termux)
- Bidirectional file transfer
- Access phone sensors, bluetooth, camera, GPS from home terminal
- Passwordless key-based authentication

---

## Why This Matters

Once you have bidirectional access, your home computer can interact with your phone's entire sensor array:
- Camera and microphone
- GPS location data
- Bluetooth scanning
- Accelerometer, gyroscope
- Ambient light, proximity sensors
- Network information

All from your home terminal. Anywhere in the world. Without asking the carrier for permission.

This gap exists because carriers don't care about reverse SSH tunnels yet. They will once enough people notice.

---

## Prerequisites

**Phone side:**
- Android phone (any reasonably modern device)
- Termux app (install from F-Droid, NOT Google Play - the Play Store version is outdated)

**Computer side:**
- Linux/macOS computer with SSH server running
- External domain name or dynamic DNS (so phone can find your computer)
- Port 22 (SSH) accessible from internet (router port forwarding configured)

---

## Quick Start

### 1. Install Termux on Phone

Download from [F-Droid](https://f-droid.org/en/packages/com.termux/)

Open Termux and run:
```bash
curl -O https://raw.githubusercontent.com/yourusername/trent/main/trent.sh
bash trent.sh
```

This installs all dependencies, generates SSH keys, configures the shell, and sets up aliases.

### 2. Get Your Termux Username

```bash
whoami
```

You'll get something like `u0_a370` - this is your Termux user ID. You'll need this later.

### 3. Set a Password

```bash
passwd
```

Choose any password. You won't use this often (keys handle auth), but you need it set.

### 4. Start SSH Server

```bash
sshd
```

Your phone is now running an SSH server on port 8022.

### 5. Find Your Phone's Local IP (One-Time Setup)

Only needed for initial key exchange when phone is on same WiFi as computer:

```bash
ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1
```

Or check your router's connected devices list.

### 6. Exchange SSH Keys

**On your computer:**

Generate key if you don't have one:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
```

Copy your computer's public key:
```bash
cat ~/.ssh/id_ed25519.pub
```

**On your phone in Termux:**

Copy your phone's public key:
```bash
cat ~/.ssh/id_ed25519.pub
```

Add your computer's public key to phone's authorized_keys:
```bash
nano ~/.ssh/authorized_keys
# Paste computer's public key, save and exit (Ctrl+X, Y, Enter)
```

**Back on your computer:**

Add phone's public key to computer's authorized_keys:
```bash
echo "PHONE_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
```

### 7. Configure Phone Aliases

Edit `~/.zshrc` on phone (or `~/.bashrc` if using bash):

```bash
nano ~/.zshrc
```

Add these lines (replace with your actual domain/IP):

```bash
# TRENT aliases
alias home="ssh user@yourdomain.com"
alias tunnel="ssh -R 8022:localhost:8022 user@yourdomain.com"
alias home-tunnel="ssh -Y -R 8022:localhost:8022 user@yourdomain.com"
```

Reload shell:
```bash
source ~/.zshrc
```

### 8. Test Phone → Computer Connection

From Termux on phone:
```bash
home
```

You should connect to your home computer without password.

### 9. Test Computer → Phone Connection

**On phone in Termux:**
```bash
tunnel
```

This opens an SSH connection and leaves it open. Keep this session running.

**On your computer (in a new terminal):**
```bash
ssh -p 8022 u0_a370@localhost
```

Replace `u0_a370` with your actual Termux username from step 2.

You should now be connected to your phone from your computer.

---

## Daily Usage

### From Phone (Anywhere in World)

**Simple SSH to home:**
```bash
home
```

**SSH with reverse tunnel (allows computer to SSH back):**
```bash
tunnel
```

**SSH with X11 forwarding + reverse tunnel:**
```bash
home-tunnel
```

**Run single command on home computer:**
```bash
ssh user@yourdomain.com "ls -la"
```

**Transfer file from phone to computer:**
```bash
scp ~/file.txt user@yourdomain.com:~/
```

### From Computer (When Tunnel Active)

First, phone must have active tunnel connection (`tunnel` command running).

**SSH to phone:**
```bash
ssh -p 8022 u0_a370@localhost
```

**Run command on phone:**
```bash
ssh -p 8022 u0_a370@localhost "pwd"
```

**Transfer file to phone:**
```bash
scp -P 8022 file.txt u0_a370@localhost:~/
```

**Access phone's external storage:**
```bash
ssh -p 8022 u0_a370@localhost
cd ~/storage/shared
```

---

## What You Can Do With This

### 1. Home Terminal Controls Phone

Once you have bidirectional access, your home computer can:

**Take photos:**
```bash
ssh -p 8022 u0_a370@localhost "termux-camera-photo ~/photo.jpg"
scp -P 8022 u0_a370@localhost:~/photo.jpg ./
```

**Get GPS location:**
```bash
ssh -p 8022 u0_a370@localhost "termux-location"
```

**Read sensors:**
```bash
ssh -p 8022 u0_a370@localhost "termux-sensor -s accelerometer"
```

**Text-to-speech (make phone talk):**
```bash
ssh -p 8022 u0_a370@localhost "termux-tts-speak 'Hello from the home terminal'"
```

**Scan WiFi networks:**
```bash
ssh -p 8022 u0_a370@localhost "termux-wifi-scaninfo"
```

**Read battery status:**
```bash
ssh -p 8022 u0_a370@localhost "termux-battery-status"
```

### 2. Phone as Portable Admin Terminal

Your phone becomes a full Linux terminal for managing servers from anywhere:
- SSH to production servers
- Run deployment scripts
- Monitor systems
- Emergency access when laptop unavailable

### 3. Automated Backups

**Phone → Computer automatic sync:**
```bash
# On phone, add to cron or run manually
ssh user@yourdomain.com "cat > backup.tar.gz" < ~/data.tar.gz
```

**Computer → Phone sync:**
```bash
# On computer (while tunnel active)
scp -P 8022 important-file.txt u0_a370@localhost:~/storage/shared/
```

### 4. Distributed Computing

Run compute tasks on phone from home:
```bash
ssh -p 8022 u0_a370@localhost "python3 script.py"
```

### 5. IoT Gateway

Phone becomes IoT device with sensors:
- Home automation triggers based on phone location
- Environmental monitoring via phone sensors
- Bluetooth device scanning and interaction

---

## Understanding How This Works

### The Reverse Tunnel

Normal SSH: `Client → Server`

Reverse SSH tunnel: `Phone → Computer` opens a tunnel, then `Computer → Tunnel → Phone`

**When phone runs:**
```bash
ssh -R 8022:localhost:8022 user@computer.com
```

This means:
- `-R 8022:localhost:8022` = Create reverse tunnel
- Port 8022 on computer now forwards back to port 8022 on phone
- Computer can then `ssh -p 8022 username@localhost` to reach phone through tunnel

### Why Carrier NAT Doesn't Block This

Cellular carriers use Carrier-Grade NAT (CGNAT) which blocks incoming connections to phones. But:
- Outbound connections from phone always work
- Phone initiates the connection (outbound)
- Tunnel created by outbound connection allows data to flow back in
- Carrier sees normal outbound SSH traffic, doesn't care

### Network Flow Diagram

```
[Phone on Cellular]          [Internet]          [Home Computer]
   172.x.x.x        →         Various      →      yourdomain.com
(Carrier NAT IP)                                  (Public IP)

Phone initiates: ssh -R 8022:localhost:8022 user@yourdomain.com
    ↓
Creates tunnel: Computer:8022 ← Tunnel ← Phone:8022
    ↓
Computer connects back: ssh -p 8022 u0_a370@localhost
    ↓
Traffic flows: Computer → localhost:8022 → Tunnel → Phone:8022
```

---

## TRENT Helper Commands

After running `trent.sh`, these commands are available:

### `trent status`
Shows current TRENT connection status:
- Is SSH server running on phone?
- Is tunnel active?
- Current phone IP address
- Termux username

### `trent start`
Starts SSH server on phone:
```bash
sshd
```

### `trent stop`
Stops SSH server on phone:
```bash
pkill sshd
```

### `trent restart`
Restarts SSH server:
```bash
pkill sshd && sshd
```

### `trent user`
Shows your Termux username:
```bash
whoami
```

### `trent ip`
Shows phone's current IP address:
```bash
ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1
```

### `trent key`
Displays your phone's public SSH key (for sharing with computers):
```bash
cat ~/.ssh/id_ed25519.pub
```

### `trent help`
Shows all available TRENT commands and usage examples.

---

## Troubleshooting

### Can't SSH from phone to computer

**Check domain resolves:**
```bash
nslookup yourdomain.com
```

**Test direct SSH:**
```bash
ssh -vv user@yourdomain.com
```

The `-vv` flag shows verbose output for debugging.

**Verify computer's SSH server running:**
```bash
# On computer
sudo systemctl status ssh
```

### Can't SSH from computer to phone

**Check tunnel is active:**
```bash
# On computer
netstat -ln | grep 8022
```

You should see `127.0.0.1:8022` listening.

**Verify phone's SSH server running:**
```bash
# On phone
pgrep sshd
```

If nothing returns, SSH server isn't running. Start it:
```bash
sshd
```

**Test tunnel connection:**
```bash
# On computer
ssh -p 8022 localhost
```

### Permission Denied

**Check authorized_keys:**
```bash
# On phone
cat ~/.ssh/authorized_keys
```

Computer's public key should be listed.

**Check key permissions:**
```bash
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### Tunnel Disconnects

Reverse tunnels can drop on network changes (WiFi → Cellular switch, etc).

**Auto-reconnect solution:**

Create script on phone `~/reconnect.sh`:
```bash
#!/data/data/com.termux/files/usr/bin/bash
while true; do
    ssh -R 8022:localhost:8022 -o ServerAliveInterval=60 -o ServerAliveCountMax=3 user@yourdomain.com
    sleep 5
done
```

Make executable:
```bash
chmod +x ~/reconnect.sh
```

Run in background:
```bash
nohup ~/reconnect.sh &
```

### Termux API Commands Not Working

Install Termux:API app and package:

1. Install Termux:API app from F-Droid
2. In Termux:
```bash
pkg install termux-api
```

Test:
```bash
termux-battery-status
```

---

## Security Considerations

### What's Secure

- End-to-end encrypted SSH connections
- Ed25519 key authentication (modern, strong)
- No passwords transmitted over network
- No exposed services on phone (tunnel is outbound)
- All traffic encrypted

### What's Exposed

- Home computer IP via domain name
- SSH port (22) accessible from internet
- Persistent connection from phone

### Mitigations

**Use strong SSH keys:**
- Ed25519 (default in trent.sh) is secure
- RSA 4096-bit also acceptable
- Rotate keys periodically

**Firewall rules on home computer:**
```bash
# Only allow SSH from specific IPs (if possible)
sudo ufw allow from TRUSTED_IP to any port 22
```

**Fail2ban for brute-force protection:**
```bash
sudo apt install fail2ban
```

**Disable password auth on computer:**

Edit `/etc/ssh/sshd_config`:
```
PasswordAuthentication no
```

**Monitor connections:**
```bash
# On computer
sudo tail -f /var/log/auth.log
```

---

## Advanced Usage

### Multiple Phones

Each phone can connect with its own reverse tunnel port:

**Phone 1:**
```bash
ssh -R 8022:localhost:8022 user@yourdomain.com
```

**Phone 2:**
```bash
ssh -R 8023:localhost:8022 user@yourdomain.com
```

**On computer:**
```bash
# Connect to phone 1
ssh -p 8022 u0_a370@localhost

# Connect to phone 2
ssh -p 8023 u0_a443@localhost
```

### X11 Forwarding (Run GUI Apps from Phone)

**From phone:**
```bash
home-tunnel
```

**On computer:**

Install X server if needed. Phone can now run graphical apps that display on computer:
```bash
ssh -Y -p 8022 u0_a370@localhost
# In that session:
firefox  # Opens on computer display
```

### Dynamic DNS (If No Static IP)

If your home IP changes frequently, use dynamic DNS:

**Options:**
- DuckDNS (free, easy)
- NearlyFreeSpeech.NET (paid, flexible)
- NoIP (free tier available)
- Your registrar's DDNS service

**Update script example (DuckDNS):**
```bash
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=yourdomain&token=YOUR_TOKEN&ip=" | curl -k -o ~/duckdns.log -K -
```

Run via cron every 5 minutes on home computer.

### Port Knocking (Extra Security)

Require "knock" sequence before SSH port opens:

1. Install knockd on computer
2. Configure knock sequence
3. SSH port closed by default
4. Phone sends knock sequence, port opens briefly

Prevents SSH port scanning.

---

## Why This Will Become Illegal (Eventually)

Right now carriers don't care about reverse SSH tunnels because:
1. Not many people do this
2. Appears as normal SSH traffic
3. Doesn't bypass carrier billing
4. Not used for tethering/hotspot bypass

**What changes this:**

Once enough people use bidirectional phone access to:
- Control phone sensor arrays remotely
- Bypass carrier restrictions on tethering
- Create mesh networks
- Automate large-scale phone operations
- Build phone farms controlled via home servers

Carriers will classify this as "unauthorized network access" or "service abuse" and:
- Block reverse tunnels in SSH traffic
- Deep packet inspection for tunnel detection
- Terms of service updates prohibiting it
- Potentially illegal under CFAA-like laws

**The window:**

Right now it's a gap. Not prohibited, not restricted, not noticed. Being the person who documented how to do it while the window was open is the point.

Not because it's impressive technically. Because you saw the gap and documented it before it closed.

---

## Files in This Repository

- `README.md` - This file
- `trent.sh` - Automated setup script for Termux
- `LICENSE` - MIT License

---

## Installation

```bash
# On your phone in Termux
curl -O https://raw.githubusercontent.com/yourusername/trent/main/trent.sh
bash trent.sh
```

Follow the prompts. Script handles everything.

---

## Credits

Created by Clarke Zyz.

Named after Trent Crimm (Ted Lasso) - "Here, there, everywhere."

Built because cloud services are boring and self-reliance is satisfying.

---

## License

MIT License - Use freely, modify freely, don't blame me if your carrier gets mad.

---

**TRENT - Bidirectional SSH for people who think phones should be real computers.**
