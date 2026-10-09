# Installation guide

Prefer a visual version? Open the web guide: https://store-art-studio.vercel.app It looks like App Store Connect, has an iOS and Android switch, copy buttons, tick-off steps and example screenshots in English, Turkish, Japanese and Arabic.

How to install the `store-art-studio` skill and run it for the first time. About 20 minutes the
first time, most of it waiting for Xcode.

## 1. Prerequisites

| Need | Why | Check |
|---|---|---|
| macOS with Xcode and an iOS simulator runtime | The renderer is an Xcode test target | `xcodebuild -version` |
| Claude Code | The skill runs inside it | `claude --version` |
| `swift` on the command line | Runs the helper scripts | `swift --version` |
| ImageMagick | Keys and composites generated art | `magick -version` (`brew install imagemagick`) |
| fastlane | Uploads to App Store Connect | `fastlane --version` (`brew install fastlane` or a Gemfile) |
| Higgsfield MCP, authenticated, with credits | Generates the 3D art | In Claude Code, run `/mcp` and check it shows connected |
| App Store Connect API key | Uploads and Product Page Optimization | Key id, issuer id and the `.p8` file |
| Apple's product bezels | The phone frames | See step 4 |

Android work also needs a JDK and Gradle for your project, and Paparazzi or Roborazzi. See step 7.

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

Add the Higgsfield MCP server the way Higgsfield documents it, then in Claude Code run `/mcp` and
authenticate. Ask Claude to check your balance. The skill will not spend credits without a plan and
a cost estimate, and it asks before any single step costs more than your budget (default 40 credits).

## 4. Get the bezels

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

## 5. Add the iOS render target to your app

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

## 6. Run the sample

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

## 7. Android

Follow `templates/android/START-HERE.md`. It contains a prompt that makes Claude build the Android
render target in your own project, using the iOS template as the reference.

## 8. Your first real job

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

More traps, with causes and fixes, are in `references/ios-swiftui-renderer.md`.

## Updating

Replace the folder with a newer copy. If you added lessons to `references/android-compose.md` or the
iOS reference, keep your version of those files and merge by hand.
