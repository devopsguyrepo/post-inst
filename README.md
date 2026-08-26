# Linux Post-Installation Automation

Automated post-installation bootstrapper for **Linux Mint** and **Debian/Ubuntu-derived** distributions. It handles APT repository registration, package installation, Flatpaks, dotfiles restoration via GNU Stow, network provisioning, and system privacy hardening.

---

## 🗂️ Repository Structure

```text
.
├── post-inst.sh            # Main orchestration script
├── apt_apps.txt            # Native APT packages list
├── flatpaks.txt            # Flathub package IDs list
├── .credentials.example    # Template for sensitive variables
├── README.md               # Project documentation
├── dotfiles/               # Local configuration directories for Stow
│   ├── bash/               # Target: ~/.bashrc, etc.
│   ├── git/                # Target: ~/.gitconfig
│   ├── ssh/                # Target: ~/.ssh/
│   └── vscodium/           # Target: ~/.config/VSCodium/
└── modules/                # Automation & repository modules
    ├── repo-docker.sh
    ├── repo-hashicorp.sh
    ├── repo-mozillateam.sh
    ├── repo-nextdns.sh
    ├── repo-steam.sh
    ├── repo-tailscale.sh
    ├── repo-virtualbox.sh
    ├── repo-vscodium.sh
    ├── dotfiles.sh         # Symlinks files inside dotfiles/ using Stow
    └── net-provision.sh    # Provisions NextDNS and Tailscale
```

## 📋 Prerequisites & Setup

### 1. Ensure Git is Installed
On some base Debian/Ubuntu installations, `git` may not be present by default. Install or verify it first:

```bash
sudo apt update && sudo apt install -y 
```

### 2. Clone the Repository

Clone this repository to your newly installed Linux system:

```bash
git clone https://github.com/your-username/post-inst.git ~/post-inst
cd ~/post-inst
```

### 3. Populate Credentials

Copy the `.credentials.example` file to create your local `.credentials` file, which should be ignored by Git:

```bash
cp .credentials.example .credentials
```

Edit `.credentials` and set your configuration variables:

```bash
# NextDNS Configuration Profile ID
NEXTDNS_PROFILE_ID="your_profile_id_here"
```

### 4. Populate Local Dotfiles & Keys

Before executing the script, place your backed-up configuration files into their respective subdirectories within `dotfiles/`:

* **`dotfiles/ssh/`** — Place your SSH keys (`id_ed25519`, `config`, `known_hosts`).
* **`dotfiles/bash/`** — Place your customized `.bashrc` or `.bash_aliases`.
* **`dotfiles/git/`** — Place your `.gitconfig`.
* **`dotfiles/vscodium/`** — Place your VSCodium `settings.json` and keybindings.

> **Security:** Never commit private SSH keys, credentials, API tokens, or other sensitive information to Git. Ensure sensitive files are properly excluded through `.gitignore`.

## 🚀 Usage

Make the script executable and run it as a standard user. **Do not run it directly with `sudo`** — it will prompt for elevation when needed.

```bash
chmod +x post-inst.sh
./post-inst.sh
```

## 🔄 Execution Breakdown

1. **System Prep & Keyrings**
   Prepares `/etc/apt/keyrings` and `/usr/share/keyrings`.

2. **Custom Repositories**
   Executes `modules/repo-*.sh` to register third-party GPG keys and APT sources for services such as Docker, VSCodium, HashiCorp, Tailscale, NextDNS, and others.

3. **APT & Flatpak Restoration**
   Updates package lists and installs packages listed in `apt_apps.txt` and `flatpaks.txt`.

4. **Dotfiles Restoration (`dotfiles.sh`)**
   Uses GNU Stow to symlink configuration files from `dotfiles/` into `$HOME`.

5. **Network Provisioning (`net-provision.sh`)**
   Installs and activates the NextDNS daemon using your configured Profile ID and enables `tailscaled`.

6. **System Hardening & Tweaks**
   Configures NetworkManager MAC address randomization, enables TLP power management, and adds the current user to the `docker` group.

## 🔑 Post-Installation Manual Steps

Once the script completes and you restart your machine, perform the following manual authentication and verification steps.

### 1. Authenticate Tailscale

Authenticate your node with your Tailscale network:

```bash
sudo tailscale up
```

Follow the authentication URL provided by Tailscale.

### 2. Verify NextDNS

Check the status of the NextDNS daemon:

```bash
nextdns status
```

### 3. Verify Docker Access

If the script added your user to the `docker` group, log out and back in for the group membership change to take effect.

Then verify Docker access:

```bash
docker run hello-world
```

### 4. Verify Tailscale

Confirm that the node is connected:

```bash
tailscale status
```

### 5. Verify Network Configuration

Confirm that NextDNS is active and resolving DNS requests correctly:

```bash
nextdns status
resolvectl status
```

## 🔐 Security Considerations

* Keep `.credentials` local and ensure it is listed in `.gitignore`.
* Never commit private SSH keys to the repository.
* Review third-party repository scripts before executing them on a new system.
* Prefer official package repositories and signed GPG keys whenever possible.
* Review the contents of `apt_apps.txt` and `flatpaks.txt` before running the bootstrapper.
* Treat this repository as trusted automation: running `post-inst.sh` may make system-wide configuration changes.

## 🛠️ Customization

### Adding APT Packages

Add package names, one per line, to:

```text
apt_apps.txt
```

### Adding Flatpaks

Add Flathub application IDs, one per line, to:

```text
flatpaks.txt
```

### Adding a New Repository

Create a new module under:

```text
modules/repo-<name>.sh
```

Make it executable:

```bash
chmod +x modules/repo-<name>.sh
```

The main `post-inst.sh` script can then invoke the module as part of the repository provisioning stage.

### Managing Dotfiles

Organize configuration files under the appropriate directory in `dotfiles/` and let GNU Stow create the required symbolic links.

For example:

```text
dotfiles/
└── git/
    └── .gitconfig
```

This can be stowed into the user's home directory as:

```text
~/.gitconfig -> ~/post-inst/dotfiles/git/.gitconfig
```

## 🧪 Testing

It is recommended to test the bootstrapper in a fresh virtual machine or disposable installation before using it on a primary system.

After making changes to a module, verify that:

* The script exits successfully.
* APT repositories are configured correctly.
* Packages install without errors.
* Flatpak applications are available.
* Dotfiles are linked correctly.
* Network services start successfully.
* No credentials or private keys are exposed in Git.

## 📄 License

Add your preferred license here, for example:

```text
MIT License
```

If this repository is intended for personal use only, you may instead state:

> This project is provided for personal use. No warranty is expressed or implied.
