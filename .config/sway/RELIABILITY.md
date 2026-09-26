# SwayFX login reliability

This is the launch contract for the managed SwayFX session. It is deliberately
small: a beautiful desktop is not useful if it can strand its user at the
display manager.

## Installed-version boundary

| Component | Relevant version | Consequence |
| --- | --- | --- |
| SwayFX | Void `swayfx-0.5.3_2` | Built for wlroots `>=0.19.0, <0.20.0`; it must use `wlroots0.19-0.19.3_1`. [SwayFX build definition](https://github.com/WillPower3309/swayfx/blob/0.5.3/meson.build#L49-L57), [Void package definition](https://github.com/void-linux/void-packages/blob/master/srcpkgs/swayfx/template#L1-L20) |
| upstream Sway | Void `sway-1.12` (optional alternative) | Built for wlroots `>=0.20.0, <0.21.0`, thus `wlroots0.20-0.20.2_1`; it is a separate compositor/package path, not an in-place SwayFX upgrade. [Sway 1.12 build definition](https://github.com/swaywm/sway/blob/1.12/meson.build#L41-L49), [Void package definition](https://github.com/void-linux/void-packages/blob/master/srcpkgs/sway/template#L1-L19) |
| SDDM | Void `sddm-0.21.0_2` | Void builds it with `NO_SYSTEMD` and `USE_ELOGIND`, so its correct seat/session integration is the elogind route. [Void SDDM build flags](https://github.com/void-linux/void-packages/blob/master/srcpkgs/sddm/template#L1-L19) |
| libseat / seatd / elogind | `0.9.3` / `0.9.3` / `252.39` | libseat can use either `seatd` or `(e)logind`; these are alternatives at the libseat boundary, not a required serial chain. [libseat 0.9.3 README](https://github.com/kennylevinsen/seatd/blob/0.9.3/README.md) |

Do not assume wlroots 0.20 fixes this particular problem. The documented
`WLR_DRM_DEVICES` syntax remains a colon-separated list in
[0.19.3](https://gitlab.freedesktop.org/wlroots/wlroots/-/blob/0.19.3/docs/env_vars.md#L22-30)
and [0.20.2](https://gitlab.freedesktop.org/wlroots/wlroots/-/blob/0.20.2/docs/env_vars.md#L22-30),
and both versions implement it with `strtok_r(..., ":", ...)`:
[0.19.3](https://gitlab.freedesktop.org/wlroots/wlroots/-/blob/0.19.3/backend/session/session.c#L414-443),
[0.20.2](https://gitlab.freedesktop.org/wlroots/wlroots/-/blob/0.20.2/backend/session/session.c#L414-443).

## What failed, and the permanent invariant

`WLR_DRM_DEVICES=/dev/dri/by-path/pci-0000:04:00.0-card` is invalid for
wlroots. It is read as three candidates: `/dev/dri/by-path/pci-0000`, `04`,
and `00.0-card`; none is the DRM card. That explains the fast exit before a
usable compositor appears.

The machine's current symlink resolves to `/dev/dri/card0`. A `cardN` path has
no colon and is a DRM primary node, so the managed launcher may export exactly
that resolved path **only after** it verifies `[ -c "$path" ]`. It must never
export a `/dev/dri/by-path/...` value directly, a `renderD*` node, an empty
string, or a path containing `:`.

If the by-path symlink is absent, changes target, or resolves to anything other
than a character device, the safe behaviour is to **unset** `WLR_DRM_DEVICES`
and let wlroots probe. wlroots documents that an explicit value disables
auto-probing; its DRM backend also skips its DRM monitor when the variable is
present. [Environment contract](https://gitlab.freedesktop.org/wlroots/wlroots/-/blob/0.19.3/docs/env_vars.md#L22-29),
[backend behaviour](https://gitlab.freedesktop.org/wlroots/wlroots/-/blob/0.19.3/backend/backend.c#L265-273).

This makes an explicit card a narrowly justified workaround for a known
multi-GPU routing problem, not a general startup setting. Do not add
`WLR_DRM_NO_ATOMIC`, `WLR_DRM_NO_MODIFIERS`, renderer overrides, or a hardcoded
GPU path to mask a login failure; wlroots documents those as driver/modeset
debug workarounds, not session setup. [wlroots DRM variables](https://gitlab.freedesktop.org/wlroots/wlroots/-/blob/0.19.3/docs/env_vars.md#L22-30)

## Ownership and start chain

```
SDDM + PAM/elogind session
  -> managed .desktop Exec: dbus-run-session -- start-sway
    -> checked WLR_DRM_DEVICES (or auto-probe)
      -> SwayFX / wlroots
        -> libseat: selected backend (logind OR seatd)
          -> DRM primary card and input devices
```

SDDM obtains the session command from the selected desktop entry and supplies
the XDG session/seat/VT variables before starting it. [SDDM 0.21 source](https://github.com/sddm/sddm/blob/v0.21.0/src/daemon/Display.cpp#L417-L460).
The managed desktop entry therefore has one job: make D-Bus session-scoped via
`dbus-run-session --`; `start-sway` owns compositor-specific validation and
logging. The wrapper must remain in the desktop entry, not in `/etc/profile`,
`.zprofile`, or a terminal shell startup file.

Void distinguishes the system D-Bus (the `dbus` service) from a per-login
session bus, and specifically recommends `dbus-run-session` for a program that
needs the latter. It also says that elogind needs system D-Bus and should be
enabled rather than left to D-Bus activation. [Void session-management handbook](https://docs.voidlinux.org/config/session-management.html#d-bus),
[Void elogind guidance](https://docs.voidlinux.org/config/session-management.html#elogind).
Launching `dbus-launch` from a global shell profile creates buses for unrelated
shells and is not a substitute for the one session bus owned by SDDM's session
command.

### Seat choice: make the automatic path deterministic

On this machine the user is in `_seatd`, and both `seatd` and `elogind` are
installed. libseat 0.9.3 tries compiled backends in order `seatd`, then
`logind`, then `builtin` when `LIBSEAT_BACKEND` is unset; it permits an explicit
selection with `LIBSEAT_BACKEND`. [libseat backend order](https://github.com/kennylevinsen/seatd/blob/0.9.3/libseat/libseat.c#L18-L77).

For an SDDM-managed desktop on this Void installation, the preferred invariant
is: **healthy `dbus` + healthy `elogind` + `LIBSEAT_BACKEND=logind` in the
managed launcher**. This keeps device access tied to the login session SDDM
created. It is supported by the installed libseat library (it links to
`libelogind`) and matches Void's description of elogind as providing necessary
features for desktop environments and Wayland compositors. [Void elogind](https://docs.voidlinux.org/config/session-management.html#elogind).

The supported fallback is an intentionally seatd-based machine: enable the
`seatd` service, keep the user in `_seatd`, and set
`LIBSEAT_BACKEND=seatd`. Void calls seatd an elogind alternative primarily for
wlroots compositors and notes that it only manages seats. [Void seatd](https://docs.voidlinux.org/config/session-management.html#seatd).
Do not silently depend on libseat's auto-detection while both are available;
the selected backend can otherwise change when a service is down or a package
is rebuilt.

For the immediate acceptance test, however, change only the DRM-path bug. The
captured failing login proves that libseat selected seatd and successfully
opened the seat before DRM enumeration failed. Switching to logind at the same
time would confound the result. Test an explicit logind selection separately,
after the corrected DRM launch has passed a real SDDM login.

## Preflight gate before changing the session

The managed launcher should hard-fail only on conditions that make the
compositor/session unusable: malformed DRM selection, missing session D-Bus or
runtime directory, and invalid Sway syntax. Optional desktop helpers belong to
the session supervisor and must not block compositor login merely because one
helper is absent or unhealthy.

Run these as the desktop user; they do not modify the machine. A proposed
change should not be selected as SDDM's default until every applicable check
passes.

```sh
# 1. The exact managed command is what SDDM will run.
desktop=/usr/share/wayland-sessions/sway-managed.desktop
test -r "$desktop" && grep -Fx 'Exec=dbus-run-session -- /home/eugene/.config/sway/start-sway' "$desktop"

# 2. The explicit DRM device is a real primary card and cannot contain ':'
#    after resolution. If either test fails, the launcher must unset the variable.
candidate=$(readlink -f /dev/dri/by-path/pci-0000:04:00.0-card 2>/dev/null) || exit 1
test -c "$candidate" && case "$candidate" in *:*) exit 1;; esac

# 3. Validate SwayFX syntax without replacing the current desktop.
sway -C -c "$HOME/.config/sway/config"

# 4. Check the D-Bus/elogind route selected for this managed session.
test -S /run/dbus/system_bus_socket
loginctl session-status "$XDG_SESSION_ID"
test "$(strings /usr/lib/libseat.so.1 | grep -xc logind)" -ge 1
```

Service state is root-owned on Void; an administrator-level preflight should
also confirm `dbus`, `elogind`, and `sddm` are supervised and running. If the
chosen backend is seatd, check `seatd` instead of treating it as an additional
required service. The correct test is `sv status <service>` as root; merely
having `/var/service/<service>` symlinked proves enablement, not readiness.

At the first SDDM login after a relevant upgrade, inspect the session log for:

```text
Seat opened with backend 'logind'
Opening fixed list of KMS devices from WLR_DRM_DEVICES: /dev/dri/cardN
```

The first line establishes the intended libseat backend; the second establishes
that wlroots received a colon-free primary node. Treat `Unable to open ... as
KMS device`, an empty device value, or a by-path PCI string as a hard stop:
return to the known-good SDDM session and use auto-probing until the GPU mapping
is understood.

## Safe recovery and limits of offline verification

Keep Plasma and the stock Sway SDDM entries installed and selectable. Do not
make the managed entry the only display-manager option. A bad managed login
should be recovered by selecting the known-good session at SDDM, then reading
`~/.local/state/sway/session.log`; do not repeatedly retry an unchanged
configuration.

`sway -C`, source inspection, service checks, and a nested Wayland compositor
can validate configuration and much of the software stack. They cannot prove
the real DRM/VT hand-off: only a fresh SDDM login on the physical seat proves
that PAM created the intended elogind session, libseat selected the expected
backend, the compositor acquired the actual card/input devices, and the
displays mode-set successfully. Re-run that one-login acceptance check after
kernel, Mesa/driver, libseat, wlroots, SDDM/PAM, or multi-GPU hardware changes.
