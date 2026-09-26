# Dotfiles

![wallpaper](.wallpaper/wallpaper.png)

Personal Void Linux configuration. The maintained desktop is SwayFX; the
repository mirrors the configuration currently used in `~/.config`.

## Desktop stack

- SwayFX with a managed SDDM session
- Waybar with weather and dashboard integration
- SwayNotificationCenter
- Swaylock and SwayOSD
- Fuzzel and Swayr for launching and window navigation
- Kanshi display profiles
- Quickshell power menu
- XDG portal routing for Sway/wlroots

Automatic idle locking, display power-off, and suspend are disabled. Lock and
suspend are manual actions in the power menu.

## Configuration

The main entry point is `.config/sway/config`. Supporting services are started
by `.config/sway/scripts/session-services`; their matching configuration lives
beside it under `.config/waybar`, `.config/swaync`, `.config/kanshi`, and the
other directories tracked here.

The guarded Void/SDDM installation helpers live in `.config/sway`. Review them
before running because they intentionally modify system-owned files.
