# CleanYourTV Theme

Reuse this setup on another Android TV. It includes seven wallpapers that shuffle every six hours, plus the launcher source changes for the slim app rail, wallpaper-matched colors, RAM, disk and network widgets, and the digital-rain clock.

## Preview

**Home** with the icon rail and compact system widgets.

![CleanYourTV Home with the left app rail, RAM, disk, network, and weather widgets](images/home.jpg)

**Wallpaper picker** with previews from the theme folder.

![Wallpaper picker with a grid of thumbnails and the Theme default option](images/wallpaper-picker.jpg)

**Clock screensaver** with translucent digital rain over a softened wallpaper.

![Centered clock and date over a custom wallpaper with faint green character trails](images/screensaver.jpg)

## Choose your setup

| What you want | What you need |
| --- | --- |
| The seven wallpapers and six-hour shuffle | CleanYourTV already installed and set as Home |
| The full custom layout | Android TV 8 or later, a clean CleanYourTV checkout, JDK 17, and Android SDK platform and build tools 34 |

## Quick start for an existing CleanYourTV install

Enable and authorize ADB on the target TV using the setup steps in the CleanYourTV checkout's `PROMPT.md`. Back up the existing theme before applying this one. The theme tool can reset per-TV layout and motion overrides.

Run these commands from the **CleanYourTV checkout root**. Replace the example folder path and TV address with yours.

```bash
theme_bundle="/path/to/TV_Theme"
python3 -m venv tools/venv
tools/venv/bin/pip install -r tools/requirements.txt
TV_HOST=192.168.1.50 tools/theme.sh "$theme_bundle/theme"
```

On Windows PowerShell, use `tools/theme.ps1` with the same theme folder and set `$env:TV_HOST` before running it.

## Install the full custom layout

Use a separate, clean CleanYourTV checkout. In that checkout, run the following with `theme_bundle` set as above.

```bash
git switch --detach "$(cat "$theme_bundle/base-commit.txt")"
git apply --check "$theme_bundle/launcher.patch"
git apply "$theme_bundle/launcher.patch"
(cd launcher && ./gradlew --no-daemon testReleaseUnitTest lintRelease assembleRelease)
```

Install the built launcher using the checkout's documented launcher setup. If CleanYourTV is already installed, the new APK must have the same signing certificate to update it in place and keep its data. Confirm the new launcher opens as Home, then apply the theme using the quick-start commands above.

## Customize and verify

- **Wallpapers:** Put supported images under `theme/wallpapers/`. Each file must be 10 MiB or smaller. To change how often the pictures switch, edit `wallpaper_rotation_minutes` in `theme/config.json`. Hold OK on the Home settings gear and select **Wallpaper** to pick an image. **Theme default** resumes the shuffle.
- **Apps:** Edit `dock_apps` in `theme/config.json` to set preferred apps. CleanYourTV discovers apps available on the target TV. An existing saved app order can take precedence.
- **Clock:** The patched launcher starts the digital-rain clock after 10 minutes of idle time on Home. To avoid interruptions during playback, disable the TV's separate system-wide screensaver in Android Settings.
- **Weather:** The card needs an OpenWeather snapshot. Run `python3 tools/weather.py --help` from the patched checkout to see the updater options. Keep the API key on the updater computer.
- **After setup:** Confirm Home, D-pad navigation, and your inputs work, then close ADB as described in `PROMPT.md`.

## What’s in this folder

- `theme/config.json` and `theme/wallpapers/` are the reusable theme.
- `base-commit.txt` pins the CleanYourTV revision for `launcher.patch`.
- `launcher.patch` adds the full layout and local weather updater to the clean checkout.

The package contains source and images. It carries no APK, signing key, API key, app data, or changes to which apps are installed on the target TV.
