# fedorascripts

**fedorascripts** provides two Bash scripts to streamline your Fedora KDE setup hosted at [llmitalia/fedorascripts](https://github.com/llmitalia/fedorascripts):

1. **Debloat Script** (`debloat.sh`)
   - Safely removes non-essential packages from Fedora 42 KDE Plasma.
   - Calculates and reports reclaimed disk space before and after cleanup.

2. **Post-Install Configurator** (`install.sh`)
   - Automates installation of day-to-day tools (editors, media players, Flatpaks).
   - Offers optional NVIDIA drivers, NordVPN VPN, and JavaScript runtimes (Node, Deno, Bun).
   - Logs successes/errors and performs final cleanup (upgrades, cache, orphan removal).

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Script Details](#script-details)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Idempotent**: Checks if packages are already installed before proceeding.
- **Interactive**: Prompts for user choices (NVIDIA drivers, Flatpaks, VPN, JS runtime).
- **Logging**: Maintains an `install.log` with detailed success/error messages.
- **Safe Defaults**: Won’t run as root and excludes essential system packages.
- **Cleanup**: Automatic system upgrade, cache clean, and orphaned-package removal after execution.

## Requirements

- Fedora 42 KDE Plasma environment.
- `bash` (v4+), `dnf`, `rpm`.
- (Optional) `flatpak` for Flatpak app installation.
- `curl` or `wget` for external installers (NordVPN, Deno, Bun).

## Installation

Clone the repository:

```bash
git clone https://github.com/llmitalia/fedorascripts.git
cd fedorascripts
chmod +x debloat.sh install.sh
```

## Usage

### Debloat Script

```bash
./debloat.sh
```

- Review the list of packages to remove.
- Confirm removal, and optionally clean orphaned dependencies and old user cache.

### Post-Install Configurator

```bash
./install.sh
```

- Select desired options when prompted.
- Check `install.log` for detailed results.

## Script Details

### debloat.sh

- Core logic for identifying and safely removing non-essential packages.
- Computes and displays human-readable sizes with `numfmt`.

### install.sh

- Installs base utilities (`htop`, `tealdeer`, `fastfetch`, etc.).
- Optional Flatpak apps installation.
- Choice of JS runtime (Node.js, Deno, Bun).
- NVIDIA driver installer and NordVPN integration.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a branch for your feature:
   ```bash
   git checkout -b feature/my-update
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add awesome feature"
   ```
4. Push to your fork:
   ```bash
   git push origin feature/my-update
   ```
5. Open a Pull Request on the main repository.

## License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.
