# ScrollFlip

A tiny macOS menu bar app that toggles **Natural Scrolling** with one click.

If you switch between a trackpad and a mouse, you know the pain: macOS uses a *single* scroll-direction setting for both, so every switch means a trip to System Settings. ScrollFlip puts that switch in your menu bar.

## Features

- **One click to toggle.** The change applies instantly, with no logout.
- **The icon shows the current state:**
  - ✋ hand: Natural scrolling **on** (trackpad style)
  - 🖱 mouse: Natural scrolling **off** (classic mouse style)
- **Right-click menu** with a Natural Scrolling checkmark, Launch at Login, and Quit.
- **Stays in sync.** If you change the setting in System Settings, the icon updates.
- **Menu bar only.** No Dock icon and no windows.
- **No dependencies.** About 150 lines of Swift, built with the stock command-line tools.

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac
- Xcode Command Line Tools (full Xcode is **not** needed):

  ```sh
  xcode-select --install
  ```

## Install

```sh
git clone <this-repo-url> scrollflip
cd scrollflip
./build.sh --install
```

If you don't use git, download the ZIP, unzip it, open Terminal in that folder, and run `./build.sh --install`.

`--install` builds the app, copies it to `~/Applications/ScrollFlip.app`, and launches it. The icon then appears in your menu bar.

To only build it (the output goes to `build/ScrollFlip.app`):

```sh
./build.sh
open build/ScrollFlip.app
```

## Usage

| Action | What happens |
| --- | --- |
| **Click** the icon | Toggles natural scrolling on/off |
| **Right-click** (or ⌥-click / ⌃-click) | Opens the menu |
| Menu → **Launch at Login** | Starts ScrollFlip automatically when you log in |
| Menu → **Quit ScrollFlip** | Quits the app |

**Tip:** hold **⌘** and drag the icon to move it anywhere in the menu bar, for example right next to Bluetooth and Wi-Fi.

## How it works

macOS stores the setting in the global defaults key `com.apple.swipescrolldirection`. Writing that key alone (`defaults write …`) doesn't take effect until you log out.

To apply it instantly, ScrollFlip calls the same functions System Settings uses. They live in the private framework `PreferencePanesSupport.framework`:

- `swipeScrollDirection()` reads the current state
- `setSwipeScrollDirection(BOOL)` applies a new state immediately

These are loaded at runtime with `dlopen`/`dlsym`, so nothing private is linked at build time. If they can't be found (for example, on a future macOS), ScrollFlip falls back to writing the defaults key and shows **"Log out to apply changes"** in its menu.

After every change it posts the `SwipeScrollDirectionDidChangeNotification` distributed notification, so an open System Settings window updates too.

### Project layout

```
scrollflip/
├── build.sh                     # builds, signs (ad-hoc) and optionally installs the .app
├── Resources/Info.plist         # bundle info; LSUIElement hides the Dock icon
└── Sources/
    ├── main.swift               # app entry point
    ├── AppDelegate.swift        # menu bar icon, click handling, menu
    ├── ScrollDirection.swift    # read/write natural scrolling (private API + fallback)
    └── LoginItem.swift          # Launch at Login via SMAppService
```

## Troubleshooting

**"ScrollFlip can't be opened because it is from an unidentified developer"**
This happens if someone sends you a pre-built `.app`. The app is ad-hoc signed, not notarized. Build it yourself with `./build.sh` (recommended), or right-click the app → **Open**, or run:

```sh
xattr -dr com.apple.quarantine ~/Applications/ScrollFlip.app
```

**The menu says "Log out to apply changes"**
Your macOS version doesn't expose the private functions ScrollFlip uses. The toggle still saves your choice, but it only takes effect after you log out and back in. Please open an issue with your macOS version.

**I can't see the icon**
The menu bar may be full, or the icon may be hidden behind the notch. Quit some menu bar apps, or use a menu bar manager. Check that the app is running with `pgrep -lx ScrollFlip`.

**Launch at Login doesn't stick**
Run the app from `~/Applications` or `/Applications` (use `./build.sh --install`), not from the `build/` folder. You can also check **System Settings → General → Login Items**.

## Uninstall

1. Right-click the icon and turn off **Launch at Login**.
2. Click **Quit ScrollFlip**.
3. Delete the app:

   ```sh
   rm -rf ~/Applications/ScrollFlip.app
   ```

## Caveats

- ScrollFlip relies on undocumented Apple APIs. A future macOS update could rename or remove them. The fallback keeps it usable, but it may need an update.
- The app is ad-hoc signed and not notarized. It's meant to be built and run locally.

## Ideas / roadmap

- Global keyboard shortcut to toggle
- Auto mode: switch automatically when a mouse connects or disconnects

Contributions are welcome. Open an issue or a pull request.

## License

MIT. See [LICENSE](LICENSE).
