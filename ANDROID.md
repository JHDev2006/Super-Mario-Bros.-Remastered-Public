# Android build + over-the-air updates

This branch adds an Android (arm64) export of Super Mario Bros. Remastered and an OTA update system
that runs entirely off GitHub Releases on **your fork**. Nothing here changes desktop behavior.

## One-time setup

1. Fork the repo (or push this branch to your own repo) and enable Actions.
2. Create a signing key. Keep it safe: every future APK update must be signed with the same one.

       keytool -genkeypair -v -keystore release.keystore -alias smb1r \
         -keyalg RSA -keysize 2048 -validity 10000
       base64 -w0 release.keystore      # paste into the secret below

   Use the **same password** for the keystore and the key.
3. In the fork: Settings > Secrets and variables > Actions, add:
   - `ANDROID_KEYSTORE_BASE64` (output of the base64 command)
   - `ANDROID_KEYSTORE_ALIAS` (`smb1r` above)
   - `ANDROID_KEYSTORE_PASSWORD`
4. Actions > "Android release (APK + OTA)" > Run workflow > `full`.
5. Download `SMB1R.apk` from the new release, copy it to the handheld, install it
   (allow installs from your file manager or browser when Android asks).

## Getting your ROM in

The game needs an original SMB1 NES ROM (it rips its assets from it on first run). On first launch it:

1. asks for storage access and scans `Roms/NES`, `Roms`, `Download`, `Documents` and `SMB1R` on shared storage for a valid ROM, then
2. otherwise shows the usual "select ROM" button, which opens Android's file picker.

The ROM is copied into the app's private storage once; asset generation runs on the device and takes a moment.

## Shipping updates

| You changed | Run workflow with | What players see |
|---|---|---|
| Scripts, scenes, art, audio, levels | `content` | `.pck` downloads silently on launch; applied on the next restart |
| Godot version, export/permission settings, native libs, `project.godot` | `full` | Prompt with a Download button for the new APK |

How it works (`Scripts/Classes/Singletons/OTAUpdater.gd`):

- On launch it reads `releases/latest/download/update.json` from your fork. That file holds the build number,
  the `.pck` URL and its SHA-256, and the minimum APK build the content needs (`apk_base`).
- Newer content and compatible APK: downloads `update.pck`, verifies the hash, stages it in app storage.
- Next launch mounts it before the game's own autoloads load, so it overrides the built-in scripts and scenes.
- Crash guard: if a launch with a new `.pck` doesn't survive 10 seconds, it is deleted and that build is skipped.
- The ROM-ripped assets live outside the `.pck`, so content updates never touch them. Saves and settings are untouched too.

Limits to know about:

- A `.pck` can't change `project.godot` (autoloads, project settings, orientation) or native libraries. Use `full` for those.
- The APK update opens the download link and Android's installer takes over; there is no silent install.
- Autoload scripts that are already running (including the updater itself) are only replaced on the launch after next.

## What was changed

- `export_presets.cfg`: `Android arm64` (APK) and `Android OTA PCK` presets. Both drop the desktop-only Discord addon.
- `project.godot`: landscape on handhelds, ETC2/ASTC import (Android requires it), `OTAUpdater` autoload.
- ROM flow: Android ROM discovery, content-URI-safe copy.
- Android guards: no window-mode changes, no Discord, `OS.move_to_trash` replaced by a recursive delete.
- `android_build.txt` / `android_apk_base.txt`: stamped by CI. `android_build.txt` ships inside the `.pck`, `android_apk_base.txt` deliberately does not.
