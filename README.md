# ⚓ PortWatch

A lightweight macOS menu bar utility for developers to monitor and manage TCP listening processes. See which dev servers are running, their resource usage, and terminate them with one click.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Process Discovery** - Scans all TCP listening processes on your machine
- **Framework Detection** - Identifies Vite, Next.js, FastAPI, Django, Docker, PostgreSQL, Redis, and more
- **Project Grouping** - Groups processes by working directory
- **Resource Monitoring** - Shows CPU and memory usage with color-coded indicators
- **One-Click Kill** - Terminate individual processes or kill all at once
- **Auto-Refresh** - Configurable refresh interval (2-60 seconds)
- **Customizable** - Choose your header emoji, set resource thresholds

## Install

Install via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/EndlessHoper/portwatch/main/scripts/install.sh | bash
```

Or download the latest release from GitHub Releases, or build from source:

```bash
git clone https://github.com/EndlessHoper/portwatch.git
cd portwatch
swift build -c release
open .build/release/PortWatch
```

## Usage

PortWatch lives in your menu bar. Click the icon to see all listening processes grouped by project directory.

**Color indicators:**
- 🟢 Green - Low resource usage
- 🟡 Yellow - Medium usage (>10% CPU or >100MB RAM by default)
- 🔴 Red - High usage (>50% CPU or >500MB RAM by default)

**Actions:**
- Click **Kill** to terminate a specific process
- Click **Kill All** to terminate all visible processes
- Click ⚙️ to open preferences

## Framework Detection

PortWatch shows **all** TCP listening processes. It also auto-detects common frameworks and labels them:

| Pattern | Label |
|---------|-------|
| `vite` | Vite |
| `next` | Next.js |
| `astro` | Astro |
| `webpack` | Webpack |
| `uvicorn`, `fastapi` | FastAPI |
| `flask` | Flask |
| `django` | Django |
| `rails` | Ruby on Rails |
| `llama-server` | llama.cpp |
| `docker-proxy` | Docker |
| `postgres` | PostgreSQL |
| `redis-server` | Redis |
| `mongod` | MongoDB |

Unrecognized processes still appear - they just won't have a framework label.

## Requirements

- macOS 14.0+ (Sonoma)
- Apple Silicon (arm64)

## Uninstall

```bash
rm -rf ~/Applications/PortWatch.app
```

## Troubleshooting

If macOS says the app is damaged after downloading the zip, remove the quarantine flag and try again:

```bash
xattr -cr "/path/to/PortWatch.app"
```

## License

MIT
