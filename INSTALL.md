# Installation guide

Prefer a visual version? Open the web guide at https://store-art-studio.vercel.app. It looks like App Store Connect, has an iOS and Android switch, copy buttons, tick-off steps and example screenshots in English, Turkish, Japanese and Arabic.

How to install the `store-art-studio` skill, connect what it needs, and run it for the first time.
About 20 minutes the first time on iOS, most of it waiting for Xcode, and about 30 minutes to a
first sample render on Android.

Setting up Android? Read [docs/android-end-to-end.md](docs/android-end-to-end.md). It walks one
Play Store set end to end: connecting the tools, every gate with its prompt, the Play submission
checklist (Wear OS, the AI declaration), troubleshooting, costs.

## 1. Connect everything

Tick each row for your platform before the first session. "Both" rows apply to iOS and Android.

| Need | For | Why | Check |
|---|---|---|---|
| Claude Code | Both | The skill runs inside it | `claude --version` |
| The skill | Both | The method and templates | `ls ~/.claude/skills/store-art-studio/SKILL.md` (step 2) |
| Higgsfield MCP, authenticated, with credits | Both | Generates the 3D art | `claude mcp list`, then ask for your `balance` (step 3) |
| A credit budget | Both | The skill asks before it spends more | You name a number in the first prompt |
| macOS with `swift` and `sips` | Both | The helper scripts and `verify-export.sh` | `swift --version` (`xcode-select --install`) |
| ImageMagick | Both | Keys and composites generated art | `magick -version` (`brew install imagemagick`) |
| fastlane | Both | Uploads | `fastlane --version`. A `Gemfile` in the repo means `bundle exec fastlane` |
| Xcode and an iOS simulator runtime | iOS | The renderer is an Xcode test target | `xcodebuild -version` |
| Apple's product bezels | iOS | The phone frames | Step 5 |
| App Store Connect API key | iOS | Uploads and Product Page Optimization | Key id, issuer id and the `.p8` file (step 4) |
| An Android build that works, with AGP, Gradle and JDK that Paparazzi supports | Android | The renderer is a JVM test module | `./gradlew --version`, then the Paparazzi release notes |
| Google Chrome | Android | Renders the HTML page layer headless | Default macOS path, or set `CHROME` |
| A Google Play service account JSON | Android | fastlane signs in to Play | `fastlane run validate_play_store_json_key json_key:<path>` (step 4) |
| An emulator with no account (optional) | Android | Only to capture a reference status bar | `emulator -list-avds` |
| `gh` (optional) | Both | Only to send fixes back to the skill | `gh auth status` |

On Linux, the Android render and upload work, but the `.swift` scripts and `verify-export.sh` need
macOS. The Android guide says what to do instead.

## 2. Install the skill

Clone the repo where Claude Code looks for skills.

```bash
# For every project on this machine:
git clone https://github.com/halilyuce/store-art-studio.git ~/.claude/skills/store-art-studio

# Or for one project only, from that project's root:
git clone https://github.com/halilyuce/store-art-studio.git .claude/skills/store-art-studio

# Update later:
git -C ~/.claude/skills/store-art-studio pull
```

No git? Download the zip from GitHub (Code, Download ZIP), unzip it, and rename the folder to
`store-art-studio` inside `~/.claude/skills/`.

Restart Claude Code. Start a session and ask:

> Which skills do you have? Is store-art-studio there?

It should answer with the skill and its description. If it does not, check that the folder is
`~/.claude/skills/store-art-studio/SKILL.md` and not nested one level deeper.

## 3. Connect Higgsfield

```bash
claude mcp add --transport http --scope user higgsfield https://mcp.higgsfield.ai/mcp
claude mcp list
```

Start a fresh Claude Code session in your terminal, run `/mcp`, pick `higgsfield` and sign in. Then
ask Claude to check your balance. A session that was already open, or a background or child
session, may not load a server added later. If the tools still do not load, the Android guide shows
a small headless bridge (`claude -p` with only the Higgsfield tools allowed).

The skill will not spend credits without a plan and a cost estimate, and it asks before any single
step costs more than your budget (default 40 credits).

## 4. Store credentials

Keep every key out of git.

- **iOS:** an App Store Connect API key (key id, issuer id, the `.p8` file) in `fastlane/.env`,
  gitignored. Never an Apple ID password.
- **Android:** a Google Play service account with a JSON key. Enable the Google Play Android
  Developer API in a Google Cloud project, create the service account and its key, invite its
  email in Play Console (Users and permissions) with permission to manage the store listing, and
  keep the JSON outside the repo. Check it with
  `fastlane run validate_play_store_json_key json_key:<path>`. Step by step:
  [docs/android-end-to-end.md](docs/android-end-to-end.md), "A Google Play service account".

## 5. Get the bezels (iOS)

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

## 6. Add the iOS render target to your app

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

## 7. Run the iOS sample

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

## 8. Android

Follow [docs/android-end-to-end.md](docs/android-end-to-end.md). In short:

1. Copy the template: `templates/android/START-HERE.md`, "The first 30 minutes". It has a
   Paparazzi render module (`storeart/`), an HTML page kit (`page/`) and `storeart.config.json`,
   the one file that lists your markets.
2. Render the sample surfaces and the sample page to prove the pipeline.
3. Paste the Gate 0 prompt from `START-HERE.md`. Claude reads your build, wires your real
   composables and builds the frozen world for your default market.

The traps and their fixes are in `references/android-compose.md`.

## 9. Your first real job

Give Claude a brief. Copy `templates/brief-template.md` into `docs/screenshots/`, fill what you know
and start a session:

> Use the store-art-studio skill. Read docs/screenshots/brief.md and start at Gate 0.

If you have a set you want to match, put it in `docs/screenshots/references/` and say so:

> Match this set: docs/screenshots/references/board.jpg. Take its layout and type, keep our colours.

The skill stops at every gate and waits for your approval.

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

More traps, with causes and fixes, are in `references/ios-swiftui-renderer.md`, and for Android in
`references/android-compose.md` and the troubleshooting table of `docs/android-end-to-end.md`.

## Updating

Replace the folder with a newer copy. If you added lessons to `references/android-compose.md` or the
iOS reference, keep your version of those files and merge by hand.
