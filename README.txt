# Laxtic Studios

**A video editor you can talk to. On your machine, on your keys.**

Laxtic Studios is a desktop video studio: a real multi-track timeline, a job
engine that drives your own `ffmpeg`, and an AI assistant that can actually
perform the edit rather than describe it. It is one application you install —
its own window, its own menus, a tray icon and it does its work on your
computer. Your footage never leaves the machine. The only thing that goes out is
the conversation you choose to have with the model provider you connected, using
your own key.

That last part is the point of it. Most AI video tools are a website that holds
your media and rents you a model at a markup. This one is the studio, and you
bring the model seventeen providers, your own account, no markup or you run
Ollama locally and pay nobody.

**$35 a year · two machines · a year of updates.**
Buy a key at **<https://studio.laxtic.com>**.

> This repository holds the ready-to-run installers, one folder per operating
> system. There is no source code here each file is the whole product, runtime
> included.

---

## What it does

**A timeline that behaves like one.** Multi-track editing with ripple trim,
roll, slip and slide, a history panel you can step back through, and crash
recovery to the last state. Media relinks when files move rather than going
offline forever.

**An assistant that edits, not one that chats.** Ask for the cut and it runs the
operations against your timeline fifty-nine editing tools it can call. Every
edit it makes is a real edit: inspectable in the history, and undoable like
anything else you did by hand. You can watch it work and stop it mid-thought.

**Your provider, your key, your bill.** Seventeen AI providers, connected with
your own API key and billed to you at cost. Switch provider mid-session and keep
the transcript. Or point it at a local Ollama daemon and run the whole thing
offline, for free.

**Exports that hold up.** Twelve presets up to ProRes 422 HQ and 4K HEVC, plus
AV1 and VP9, with hardware acceleration and an automatic software fallback when
the hardware path is not available. Captions, transcripts and loudness
normalisation are part of the job engine, not an add-on.

**Built to stay yours.** Provider keys live in an encrypted vault behind a
device key or a passphrase never logged, never backed up off your machine. The
app ships a compiled-in network allowlist, so it can only reach the services it
tells you about. Projects, media references and settings sit in a folder in your
own user account.

**A loopback MCP server.** Another agent Claude Code, or anything that speaks
MCP can drive the timeline through sixteen tools on `127.0.0.1`. It is on by
default and bound to loopback, so nothing off your machine can reach it, and
letting an agent spend money on your provider account is a separate switch that
is off until you turn it on.

---

## Before you install

You need three things, and only one of them takes any effort.

**A licence key.** $35 a year from <https://studio.laxtic.com>; it arrives by
email and looks like `LX-XXXXX-XXXXX-XXXXX-XXXXX`.

**`ffmpeg` on your machine.** Laxtic Studios does every transcode, proxy,
thumbnail and export through `ffmpeg`, and it deliberately does not bundle one —
that would add a couple of hundred megabytes to the download and pin you to our
build instead of the one your system trusts and updates. Run the setup script in
this folder and it will sort this out for you:

```bash
./setup.sh          # macOS and Linux
```
```powershell
.\setup.ps1         # Windows
```

It checks what you already have, shows you the exact command it wants to run,
and runs it only if you agree. If `ffmpeg` is already there it changes nothing
and tells you so. Add `--check` (or `-Check`) to look without installing.

Prefer to do it yourself? `brew install ffmpeg` on macOS, `winget install
Gyan.FFmpeg` on Windows, `sudo apt install ffmpeg` or your distribution's
equivalent on Linux. Any `ffmpeg` on your `PATH` will do, or point the app
straight at one with the `FFMPEG_PATH` environment variable.

**An AI provider optional.** Your own key for one of the supported providers,
or a local Ollama daemon, which needs no key at all. The editor works without
either; the assistant is what needs it.

Everything else is already in the download. No Node.js, no package manager, and
no administrator rights.

---

## Download and install

Open the folder for your platform, pick the file that matches your machine, and
use **Download raw file**.

| Platform | Folder | File |
| --- | --- | --- |
| macOS, Apple Silicon and Intel | `macOs/` | `Laxtic-Studios-<version>-universal.dmg` |
| Windows 10/11, x64 and ARM64 | `Windows/` | `Laxtic-Studios-<version>-<arch>-setup.exe` |
| Linux, x86-64 | `Linux/` | `.AppImage`, `.deb` or `.rpm` |

Licence holders get the same builds from the download page at
<https://studio.laxtic.com>.

### macOS

Open the `.dmg` and drag **Laxtic Studios** into **Applications**.

These builds are **not yet notarised by Apple**, so the first launch needs one
extra step Gatekeeper will refuse a plain double-click. Either right-click the
app and choose **Open**, then confirm once (after which it opens normally
forever), or clear the quarantine flag yourself:

```bash
xattr -dr com.apple.quarantine "/Applications/Laxtic-Studios.app"
```

One universal build carries both Apple Silicon and Intel code, so the same
download runs on any Mac. The `.zip` beside the `.dmg` is the same app in a
plain archive, for when a `.dmg` is inconvenient.

### Windows

Run the `setup.exe`. It installs for your user account, lets you choose the
location, and needs no administrator rights. SmartScreen may say the publisher
is unrecognised, because these builds are not yet code-signed choose **More
info → Run anyway**. Take the `x64` installer on a normal PC, or `arm64` on an
ARM laptop.

### Linux

```bash
# AppImage no install, just make it executable
chmod +x ./Laxtic-Studios-<version>-x86_64.AppImage
./Laxtic-Studios-<version>-x86_64.AppImage

# Debian / Ubuntu
sudo apt install ./Laxtic-Studios-<version>-x86_64.deb

# Fedora / RHEL
sudo dnf install ./Laxtic-Studios-<version>-x86_64.rpm
```

The AppImage needs FUSE 2 to mount itself, and Ubuntu 24.04 and its derivatives
no longer ship it the symptom is the AppImage refusing to start with a message
about `libfuse.so.2`, which reads like a broken download but is not. `./setup.sh`
installs it alongside `ffmpeg`. The `.deb` and `.rpm` do not need it.

---

## First run

The app asks for your key, activates the machine, and opens. Activation needs a
network connection; everyday use after it does not.

Your licence then lives under **License** in the tray and application menus:
**Information** shows the plan, the expiry and the machines in use, read from the
local cache with no network; **Refresh** asks the service again now; **Deactivate
device** frees this machine's seat; **Change license key** swaps the key.

**Two machines at a time** a desktop and a laptop is the shape it is sized
for. Activating a third is refused until you free a seat, so deactivate before
you wipe or reimage a machine, otherwise the seat stays held until support
releases it.

**It works offline.** Activation stores a signed licence lease, and the app
verifies that signature locally with no network involved. It re-checks quietly
in the background when it can reach the service, and if it cannot, it keeps
honouring your last valid licence for **seven more days** and tells you when
that window closes. A flight, a train or a locked-down client site is not a
lockout: **a network failure is never treated as a rejection.** Only a real
refusal an expiry, a cancellation, a revocation stops it. Your AI provider
still needs a network, unless you are running Ollama.

---

## Everyday use

Add your provider's API key in settings, or point the app at a local Ollama
daemon. The key is stored in the app's encrypted vault; the model account stays
yours, and you pay the provider directly for what you use. Web search and web
fetch work the same way your own search-vendor key, your own quota.

Your work lives in your own user account, in a folder named **Laxtic Studios**:

| | |
| --- | --- |
| macOS | `~/Library/Application Support/Laxtic Studios` |
| Windows | `%APPDATA%\Laxtic Studios` |
| Linux | `~/.config/Laxtic Studios` |

Settings, provider keys, projects, the assistant's working state and the signed
licence lease all live there. Nothing is written into the folders your media is
in, and nothing is installed system-wide beyond the application itself.

**Updating** is just running the newer installer it replaces the app in place
and keeps your projects, settings, keys and licence. Every build released during
your licence term is included.

**Uninstalling:** drag **Laxtic Studios** from Applications to the Trash on
macOS; uninstall from **Settings → Apps** on Windows; `sudo apt remove
laxtic-studios`, `sudo dnf remove laxtic-studios`, or just delete the AppImage on
Linux. Deleting the app does not free your licence seat use **License →
Deactivate device** first. To remove your data too, delete the folder above.

---

## Privacy

This is an application you install, not a service you log into. There is no
account in someone else's cloud and no route by which your media or projects
leave your machine, except the conversation you start with the provider you
chose.

- **Media is processed locally.** Transcodes, proxies, thumbnails and exports
  run on your machine through your `ffmpeg`. Footage stays where it is.
- **Model traffic goes straight to the provider you picked**, with your key, as
  part of the work you asked for. With Ollama, even that stays local.
- **The licence check is separate from all of it.** It carries the key, a random
  device id generated on your machine, your hostname, the app version and your
  platform and nothing else. No media, no project names, no file paths, no
  prompts, no telemetry. The device id is random, not a hardware fingerprint.
- **Nothing runs elevated.** The app installs and runs as you; there is no
  system-wide service.
- **What you make is yours.** No interest is claimed in your projects, your
  footage or your output.

---

## What $35 a year buys

Two machines on one licence, and the whole product on each: the timeline, the
job engine, the assistant, bring-your-own keys for seventeen providers, web
search and fetch, the loopback MCP server, every export preset, and every build
released during your term on macOS, Windows and Linux, with email support.

What it does not buy is model usage or `ffmpeg`. Laxtic Studios is the studio,
not the model vendor: you hold the provider account and pay that vendor for the
tokens you use, or run Ollama and pay nothing. `ffmpeg` is free and comes from
your own machine.

---

## Help

Product, purchase and account: **<https://studio.laxtic.com>**
Support: **<info@laxtic.com>**

Tell us what happened, which platform you are on, and the app version from
**License → Information**. Include whether `ffmpeg -version` works in a
terminal a missing `ffmpeg` explains most job failures on its own, and
`./setup.sh --check` answers it in one line.

---

## Legal

Laxtic Studios is published and licensed by **Laxtic Software Services**. A
licence is a non-exclusive, non-transferable right to install and use the
software for your licence term, on up to two devices at a time, for personal
work, commercial work, and work you are paid for. Copying, hosting, reselling,
sublicensing, renting or redistributing it is not granted, and these builds
require a valid licence key to run. The terms published at
<https://studio.laxtic.com> are the authority.
