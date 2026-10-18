# Installation guide

Prefer a visual version? The web guide at https://store-art-studio.vercel.app has an iOS and Android
switch, copy buttons and tick-off steps.

Install the skill, connect what it needs, prove the renderer once, then start your first session.
About 20 minutes on iOS (most of it Xcode) and 30 minutes on Android to a first sample render.

## 1. Connect everything

Tick each row for your platform before the first session.

| Need | For | Check |
|---|---|---|
| Claude Code | Both | `claude --version` |
| The skill | Both | `ls ~/.claude/skills/store-art-studio/SKILL.md` (step 2) |
| Higgsfield MCP, signed in, with credits | Both, if you want generated art | ask Claude for your `balance` (step 3) |
| A credit budget | Both | a number you name; the skill asks above it (default 40 per gate) |
| macOS with `swift` and `sips` | Both | `swift --version` (`xcode-select --install`) |
| ImageMagick (recommended) | Both | `magick -version` (`brew install imagemagick`) |
| fastlane | Both | `fastlane --version`; a `Gemfile` in the repo means `bundle exec fastlane` |
| Xcode and an iOS simulator runtime | iOS | `xcodebuild -version` |
| Apple's product bezels | iOS | step 5 |
| App Store Connect API key | iOS | key id, issuer id and the `.p8` file (step 4) |
| An Android build that works, with AGP, Gradle and JDK that Paparazzi supports | Android | `./gradlew --version`, then the Paparazzi release notes |
| Google Chrome | Android | default macOS path, or set `CHROME` to the binary |
| A Google Play service account JSON | Android | `fastlane run validate_play_store_json_key json_key:<path>` (step 4) |
| An emulator with no account (optional) | Android | only to capture a reference status bar: `emulator -list-avds` |
| `gh` (optional) | Both | only to send fixes back to the skill: `gh auth status` |

**Linux:** the Android render, the page kit and the upload work. The `.swift` scripts and
`verify-export.sh` need macOS (CoreGraphics, `sips`); run them on a Mac, or check size and alpha
with `magick identify -format "%w %h %A\n" file.png`.

## 2. Install the skill

```bash
# For every project on this machine:
git clone https://github.com/halilyuce/store-art-studio.git ~/.claude/skills/store-art-studio

# Or for one project only, from that project's root:
git clone https://github.com/halilyuce/store-art-studio.git .claude/skills/store-art-studio

# Update later:
git -C ~/.claude/skills/store-art-studio pull
```

No git? Download the zip from GitHub (Code, Download ZIP), unzip it, and rename the folder to
`store-art-studio` inside `~/.claude/skills/`. Restart Claude Code and ask:

> Is the store-art-studio skill available? Show me its description.

If it is not, check that the path is `~/.claude/skills/store-art-studio/SKILL.md`, not one folder
deeper.

## 3. Connect Higgsfield

```bash
claude mcp add --transport http --scope user higgsfield https://mcp.higgsfield.ai/mcp
claude mcp list
```

Start a **fresh foreground** session, run `/mcp`, pick `higgsfield`, sign in, and ask Claude to
check your balance. A session that was already open, or a background or child session, may not load
a server added later. If the tools still do not load, `references/higgsfield-art.md` has a small
headless bridge (`claude -p` with only the Higgsfield tools allowed).

The skill never spends credits without a plan and an estimate, and asks before any single gate
costs more than your budget. No budget at all is a valid answer: the set then uses type, colour and
real UI only.

## 4. Store credentials

Keep every key out of git.

- **iOS:** an App Store Connect API key (key id, issuer id, the `.p8` file) in `fastlane/.env`,
  gitignored. Never an Apple ID password.
- **Android:** a Google Play service account with a JSON key:
  1. In Google Cloud Console, pick or create a project and enable the **Google Play Android
     Developer API**.
  2. Create a service account there and a JSON key for it (it downloads once).
  3. In Play Console, **Users and permissions**, invite the service account's email with access to
     your app and permission to manage the store listing. Nothing about releases or money.
  4. Keep the JSON outside the repo (for example `~/.config/play/<your-app>.json`) and point
     fastlane at it (`json_key_file` in `fastlane/Appfile`, or `SUPPLY_JSON_KEY`).
  5. `fastlane run validate_play_store_json_key json_key:<path>`.

  Play Console's menus move; if a name above changed, follow Play's own help page.

## 5. Prove the renderer: iOS

You can ask Claude to do this ("set up Gate 0 from the skill"), or do it by hand.

### Bezels

Download the product bezels from Apple Design Resources (developer.apple.com/design/resources). Put
the iPhone PNG you want in `StoreArt/Art/bezels/` of your project. Apple's licence does not allow
redistribution, so they are not in this repo, and they must be gitignored:

```
StoreArt/Art/bezels/
StoreArt/Output/
```

The template expects the iPhone 17 Pro Max, Deep Blue, portrait export (1470 x 3000, screen hole
1320 x 2868 at (75, 66), corner radius 190). For another file, edit `BezelSpec` in
`StoreArtChrome.swift`. Without a bezel the template draws a plain dark frame so layouts still work.

### The render target

You can ask Claude to do this ("set up Gate 0 from the skill"), or do it by hand.

1. Copy `templates/ios/*` into a new `StoreArt/` folder at your repo root. Copy `scripts/` to
   `scripts/screenshots/tools/` and `templates/ios/render.sh` to `scripts/screenshots/render.sh`.
2. In Xcode: File, New, Target, **Unit Testing Bundle**, named `StoreArt`. Set **Host Application**
   to **None**.
3. Add the `StoreArt/*.swift` files to that target. Add the Swift files of the views you want to
   render (your screens, widgets, activities) to its target membership. Do not add the app entry point.
4. Edit the scheme `StoreArt`, Test, Arguments, and add the environment variable `TZ` with the value
   `America/Chicago` (or change `StoreArt.timeZone` to the zone you prefer).
5. Edit the five variables at the top of `scripts/screenshots/render.sh` (project, scheme, test
   target, test class, simulator name).
6. Set the minimum deployment target of the test target to iOS 18 (the page background uses
   `MeshGradient`).

Adding Swift files to an Xcode project means editing `project.pbxproj`. If you or Claude do it by
hand, add a file reference, a group entry, a build file and a Sources entry per file, with fresh
24-character hex ids, and build after each edit. Do not use the `xcodeproj` gem: it re-sorts the file
and can drop entries.

### The sample render

```bash
scripts/screenshots/render.sh Sample
```

The first run creates a simulator called "StoreArt iPhone 17 Pro Max" and builds. It writes
`StoreArt/Output/default_en-US_iphone_01.png`. Verify it:

```bash
scripts/screenshots/tools/verify-export.sh StoreArt/Output 1320x2868
sips -g pixelWidth -g pixelHeight -g hasAlpha StoreArt/Output/default_en-US_iphone_01.png
```

You should see 1320 by 2868 and `hasAlpha: no`. Open the PNG: a pastel page, a two-line headline with
a pill, two lines of body copy and a phone with a placeholder screen. If you see that, the pipeline
works. Replace `SampleScreen` in `SampleSlot.swift` with one of your real views.

Use the dedicated simulator only. Never point `render.sh` at a simulator that has your app installed,
and never launch your real app to take a screenshot. That is the first rule of the skill.

## 6. Prove the renderer: Android

<p>
  <img src="assets/examples/android/standings/en-US/01.jpg" width="110" alt="Standings for Android, English, slot 1">
  <img src="assets/examples/android/standings/en-US/02.jpg" width="110" alt="Standings for Android, English, widgets and Wear OS">
  <img src="assets/examples/android/standings/tr-TR/04.jpg" width="110" alt="Standings for Android, Turkish, Wear OS">
  <img src="assets/examples/android/standings/ja-JP/03.jpg" width="110" alt="Standings for Android, Japanese, widgets">
  <img src="assets/examples/android/standings/ar/01.jpg" width="110" alt="Standings for Android, Arabic, right to left">
</p>

<sub>What a finished Android run looks like: Standings for Android.</sub>

Follow `templates/android/START-HERE.md`, "The first 30 minutes": copy the `storeart` render
module, the HTML page kit and `storeart.config.json` into your project, add the module to your
settings and catalog, and render the sample surfaces and the sample page. When
`store/tools/verify-export.sh store/page/out 1080x1920 1024x500` passes and the PNGs look right,
the pipeline works in your build. The traps and their fixes are in `references/android-compose.md`.

## 7. Your first session

You do not need to write a brief yourself. Start from your project's root:

> Use the store-art-studio skill. Discover this project, ask me what you cannot read from it, and
> write the brief. Platform: <iOS, Android or both>.

The skill reads the project, asks structured questions, writes `docs/screenshots/brief.md` (and,
on Android, `store/storeart.config.json`), and stops for your approval. Then it works gate by gate:
first draft in one market, rounds of feedback, localization, delivery. It stops at every gate.

Already have a brief? Copy `templates/brief-template.md` to `docs/screenshots/brief.md`, fill what
you know, and say "Read docs/screenshots/brief.md and start at Gate 0". Have a set you want to
match? Put it in `docs/screenshots/references/` and say so.

## Troubleshooting

| Problem | Fix |
|---|---|
| Strings print as raw keys in a render | Call `StoreArt.forwardMainBundle()` in `setUp` and add your Localizable.strings to the target |
| `Font ... did not register` | The PostScript name in `StoreArtFace` does not match the file. Check it with `UIFont(name:size:)` |
| `The process runs in ... but StoreArt.timeZone is ...` | Set `TZ` in the `StoreArt` scheme's test environment |
| Xcode says a module cache is stale after running `render.sh` | `render.sh` uses its own `build/StoreArtDerivedData`; do not point it at Xcode's DerivedData |
| The phone is a plain dark frame | The bezel PNG is missing or its name differs from `BezelSpec.name` |
| Higgsfield calls are not available | Run `/mcp`, authenticate, and restart the session |
| Upload refuses a locale | Add it to `upload.locales` in `screenshots.yml` after the user approved its render |
| Android: Higgsfield tools missing in a session | Start a fresh foreground session after `claude mcp add`, run `/mcp`, sign in |
| Android: `Could not locate Gemfile` | fastlane is a Homebrew install: run `fastlane`, not `bundle exec fastlane` |
| Android: upload refuses a locale | Set `"upload": true` for it in `storeart.config.json` after its renders are approved, stage it, and add the language on the Play listing |

More traps, with causes and fixes: `references/ios-swiftui-renderer.md` for iOS, and
`references/android-compose.md` ("What broke", "Tooling and delivery") for Android.

## Updating

Pull the skill folder, or replace it with a newer copy. If you added lessons to the references,
keep your version of those files and merge by hand.
