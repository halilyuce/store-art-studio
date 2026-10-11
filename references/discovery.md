# Discovery, questions and the brief

Phases 1 to 3 of the workflow. The skill reads the developer's project first, asks only what the
project cannot answer, and writes the answers into one brief the rest of the job reads. Nothing is
rendered and no credit is spent before the developer approves that brief.

The examples below span app types on purpose (a fitness tracker, a budgeting app, a trip planner,
a notes app, a puzzle game). None of them is a default. Use what the project in front of you shows.

## Phase 1: Discover

Read, do not run. Never build and launch the app, never sign in to anything, never touch a device
or simulator that has the app installed. `git status` first: note uncommitted work you must not
touch (`references/architecture.md`, "Separating your work in a dirty tree").

### What to find

| Topic | What it tells you |
|---|---|
| Platforms | iOS, Android, both, and which targets (phone, tablet, watch, extensions) |
| App type and domain | What the app is for, in the user's words, from the store listing, README and string files |
| Main features | The screens a user opens most, from navigation, routes and tabs |
| Surfaces | Widgets, live notifications or Live Activities, watch apps or tiles, Lock Screen, Siri or App Intents, tablet layouts |
| Locales | Which languages the app already ships, and how complete each one is |
| Brand | Icon, colours, fonts, existing marketing art |
| Store listing | Existing screenshots, descriptions, feature graphics, fastlane metadata |
| Data | Preview or sample data, test data, mock repositories: the raw material for the frozen world |
| Render readiness | Which screens build from plain state, and which need a ViewModel, the network, the clock or an account |

### Where it lives on iOS

| Look for | Where |
|---|---|
| Targets and extensions | `*.xcodeproj/project.pbxproj` (`PBXNativeTarget`, `productType`), `Package.swift` |
| Navigation and screens | `TabView`, `NavigationStack`, `NavigationLink`, `.sheet`, coordinators, `*View.swift`, `*Screen.swift` |
| State | `*ViewModel.swift`, `@Observable`, `ObservableObject`, stores |
| Widgets | `WidgetBundle`, `Widget`, `TimelineProvider`, `supportedFamilies` |
| Live Activities | `ActivityConfiguration`, `ActivityAttributes`, `DynamicIsland` |
| Watch | a `watchOS` target, `WKApplication`, complications (`WidgetKit` with accessory families) |
| Siri, Shortcuts | `AppIntent`, `AppShortcutsProvider` |
| Locales | `*.lproj/`, `Localizable.xcstrings` (its `"localizations"` keys), `knownRegions` in the project |
| Brand | `Assets.xcassets/AppIcon.appiconset`, `AccentColor.colorset`, named colours, bundled fonts in `Info.plist` (`UIAppFonts`) |
| Store listing | `fastlane/metadata/`, `fastlane/screenshots/`, `fastlane/Deliverfile` |
| Sample data | `#Preview`, `PreviewProvider`, `*Mock*`, `*Sample*`, `*.json` test data |

```bash
grep -rn "productType = " *.xcodeproj/project.pbxproj | sort | uniq -c
grep -rlE "WidgetBundle|ActivityConfiguration|AppShortcutsProvider" --include=*.swift .
grep -rlE "TabView|NavigationStack" --include=*.swift . | head -20
ls -d **/*.lproj 2>/dev/null; find . -name "*.xcstrings" -not -path "*/build/*"
ls fastlane/metadata fastlane/screenshots 2>/dev/null
```

### Where it lives on Android

| Look for | Where |
|---|---|
| Modules | `settings.gradle(.kts)` (`include`), `gradle/libs.versions.toml`, `build-logic/` convention plugins |
| Navigation and screens | `NavHost`, `composable("...")` or typed routes, `navigation/` graphs, bottom bar items, `*Screen.kt` |
| State | `*ViewModel.kt`, `UiState` classes, `StateFlow` |
| Manifest | `AndroidManifest.xml`: activities, `<receiver>` with `APPWIDGET_UPDATE` (widgets), services, deep links |
| Widgets | `GlanceAppWidget`, `GlanceAppWidgetReceiver`, `AppWidgetProvider`, `res/xml/*widget*info*.xml` |
| Notifications | `NotificationCompat.Builder`, `RemoteViews(`, `setCustomContentView`, foreground services, Live Update (`setRequestPromotedOngoing`) |
| Wear OS | a module with `com.google.android.wearable` or `uses-feature android.hardware.type.watch`, `TileService`, `androidx.wear.compose` |
| Tablet | `WindowSizeClass`, `res/layout-sw600dp`, adaptive navigation |
| Locales | `res/values-*/strings.xml` per module, `locales_config.xml`, `resourceConfigurations` / `localeFilters` |
| Brand | `ic_launcher*`, `res/values/colors.xml`, the Compose `ColorScheme`, `res/font/`, a theme module |
| Store listing | `fastlane/metadata/android/<locale>/`, existing `images/phoneScreenshots/` |
| Sample data | `@Preview` functions, `PreviewParameterProvider`, fakes in `testFixtures` or `debug` |
| Screenshot tooling | Paparazzi or Roborazzi already in the build |

```bash
grep -nE "include" settings.gradle* | head -40
grep -rlE "GlanceAppWidget|AppWidgetProvider" --include=*.kt . | head
grep -rlE "RemoteViews\(|setCustomContentView|setRequestPromotedOngoing" --include=*.kt . | head
grep -rlE "TileService|androidx.wear" --include=*.kt --include=*.kts --include=*.toml . | head
grep -rhoE "composable(<[A-Za-z.]+>|\(\"[^\"]+\")" --include=*.kt . | sort -u | head -40
find . -path "*/res/values-*" -name strings.xml -not -path "*/build/*" | sed -E 's#.*/values-([^/]+)/.*#\1#' | sort | uniq -c
grep -rln "@Preview" --include=*.kt . | wc -l
```

Other frameworks (Flutter, React Native, Kotlin or Compose Multiplatform): the renderer in this skill
is SwiftUI or Compose. Say what you found, and ask whether to render the platform views the app
really shows (widgets and watch apps are usually native even in a cross-platform app) or to treat
the main screens as captures from a screenshot mode (`references/architecture.md`, "Render, or
capture?").

### Counting what really ships

- A screen, widget or watch target only counts when it ships: it is in `settings.gradle` or the
  scheme, reachable from navigation, and not behind a dead flag. Old modules that are no longer
  built are not features.
- A locale counts when the strings file is substantially complete. Report the share of keys it
  covers (`grep -c "<string "` per folder) rather than a yes or no.
- Note which screens render from plain state and which need a seam (a ViewModel, a repository, the
  clock, an account). That decides how much of Gate 0 is wiring.

### Presenting the findings

One short block, in this order, before any question. Facts with their source, then gaps.

```text
What I found (read only, nothing built or run):

App:       a budgeting app for households, iOS and Android (README, store description)
Features:  1 Overview (balance, month) 2 Transactions 3 Budgets per category 4 Savings plans 5 Shared
           household 6 Reports   (Android NavHost: 9 routes; iOS TabView: 5 tabs)
Surfaces:  home screen widgets (Glance, 2 sizes; WidgetKit, 3 families), a Lock Screen widget.
           No watch app, no live notification, no tablet layout.
Locales:   app ships en (100%), de (98%), es (61%), pt-BR (12%)
Brand:     icon, accent #2F6BFF, Inter in res/font, light and dark themes
Listing:   fastlane/metadata for en-US and de-DE, 5 device screenshots from 2024
Data:      @Preview fakes for Overview and Transactions; Budgets reads a repository directly
Gaps:      design direction, markets and order, your copy rules, art budget, who uploads
```

## Phase 2: Ask

### How to ask

- **Only what the repo cannot answer.** Never ask which platforms or widgets exist when you just
  read them. Ask to confirm only when the evidence was ambiguous.
- **Batch.** Group questions by topic. With Claude Code's `AskUserQuestion` tool, one call holds up
  to 4 questions, each with 2 to 4 options and a short header; set `multiSelect` where several
  answers fit. The tool adds a free-text "Other" on its own, so never spend an option on it.
- **Recommended first.** Put your recommendation first and label it "(Recommended)", with a
  one-line reason from what you found.
- **State defaults.** End each batch with what you will assume if the developer skips a question.
- **Two rounds at most** before the brief. Anything still open becomes a marked assumption in the
  brief, where the developer can change it.

### Question bank

Pick the questions that matter for this project; skip any that discovery answered. The options are
starting points: fill them with what you found.

**Features and order** (header "Features")

1. Which features should the set show? *multiSelect.* Options: the 3 or 4 features you would
   lead with, from the discovered list. Default: the most used screens, the strongest
   differentiator first.
2. What leads in slot 1? Options: the core promise (what the app is), the differentiator, the most
   visual screen. Recommended: the core promise, unless the app's category is crowded, then the
   differentiator. Search shows about three slots, so slots 1 to 3 must tell the whole story.
3. How many slots? Options: 5 (Recommended for one surface), 7 to 8 (several surfaces), 3 to 4 (a
   small utility). Play takes 2 to 8 phone screenshots; the App Store up to 10.

Examples of a lead promise: a fitness tracker leads with today's training load, a trip planner
with the whole itinerary on one screen, a notes app with search across everything, a puzzle game
with the board itself.

**Surfaces** (header "Surfaces")

4. Which surfaces should appear? *multiSelect.* Options: only those discovery found (widgets, live
   notification or Live Activity, watch, tablet, Lock Screen, Siri). Default: phone screens, plus
   each found surface that has its own slot's worth of story. Every surface beyond the screens is
   optional; leaving one out is a valid answer.

**Design direction** (header "Design")

5. Which direction? Options, each with one line: Pastel with a straight phone (calm, the house
   default), Saturated brand hero then pastel (Recommended when the brand has a strong colour),
   Bento of surfaces (apps with widgets or several surfaces), Scene or photo-led (lifestyle,
   travel, fitness). Archetypes in `references/style-and-copy.md`.
6. A reference set to match? Options: no, build a style tile (Recommended when none exists), yes,
   I will add images to `docs/screenshots/references/`, match our current listing. With a
   reference, read `references/reference-matching.md` before anything else.
7. Device frames? Options: a plain drawn frame (Recommended), no frame (full-bleed screens), the
   official bezel (iOS only, licensed, gitignored).
8. Light or dark? Options: what the app defaults to (Recommended), light, dark, mixed by slot.

Colours, type and tone are usually readable from the brand. Ask only if they are missing:
"Brand colours: use the accent from the app (#2F6BFF) and a pastel page (Recommended), or give
me hex values." Default type: Inter Tight and Inter (OFL).

**Markets and language** (header "Markets")

9. First market and language? Options: the app's base language and its biggest market
   (Recommended), the market with the most installs (if the developer knows), another. One market
   renders first and alone until approved.
10. Which markets later, in order? Free text or a multiSelect of the locales the app already
    ships. Never propose a language the app does not ship without saying so.
11. Which of these languages do you or the people working with you read natively? *multiSelect.* The others are
    marked "not native-reviewed".

**Your rules** (header "Rules")

12. Do you have copy rules? Options: yes, in the repo (point me to them) (Recommended when a
    translation guide, glossary or style guide exists; name the file you found), yes, I will
    paste them, no, use the skill's defaults.
13. Register per language? Only for languages with a choice (formal or informal "you"). Options:
    informal, formal, follow the app's own strings (Recommended: read the app's strings and say
    what they use).
14. Words to avoid or require? Free text. Defaults: the skill's banned list
    (`references/style-and-copy.md`), plus the app's own names for its things.
15. Claims you can back? Options: none (Recommended), a rating, a user count, an award, a press
    quote. Each needs a source the developer names. The templates carry no claim.

**Art** (header "Art")

16. What kind of generated art? *multiSelect.* Options: 3D objects and glyphs for pills
    (Recommended), a hero scene or figure, illustrated characters (never photoreal, never
    presented as real users), none (type, colour and real UI only).
17. Credit budget? Options: none, no generated art; about 30 (a few objects); about 60
    (Recommended for one market with a hero); a number you name. The skill asks before any gate
    costs more than its share (default: ask above 40 credits per gate).

**Delivery** (header "Ship")

18. Which stores? Options: what discovery found (App Store, Google Play, both).
19. Who uploads? Options: you run the upload, I stage and dry run (Recommended, and the only option
    for Google Play listing art, which has no draft), I upload to a preview or a Product Page
    Optimization treatment (App Store only), files only, no fastlane.

### A batch, as asked

```text
Header "Features": Which features should the set show? (multiSelect)
  - Overview and balance (Recommended: the screen users open most)
  - Budgets per category
  - Shared household
  - Reports
Header "Design": Which direction?
  - Saturated brand hero, then pastel (Recommended: your accent is strong)
  - Pastel with a straight phone
  - Bento of surfaces
  - Scene or photo-led
Header "Markets": First market?
  - en-US (Recommended: base language, biggest market in your metadata)
  - de-DE
Header "Art": Credit budget?
  - About 60 credits (Recommended)
  - About 30 credits
  - None, no generated art

If you skip one: the first option.
```

## Phase 3: Brief

Write the answers into the developer's repo, then stop and ask the developer to read and approve
the brief. Every later phase reads it; when the developer edits it, the next phase follows the edit.

| File | Holds | Template |
|---|---|---|
| `docs/screenshots/brief.md` | Features and order, surfaces, design direction, the world, the developer's rules, art budget and kind, store targets, the approvals and decisions log | `templates/brief-template.md` |
| `store/storeart.config.json` (Android) | Markets, surfaces, the frozen moment, the upload allow list. Machine-read by the renderer, the page and the upload lane | `templates/android/storeart.config.json` |
| `screenshots.yml` (iOS) | Markets, slots, upload allow list | `templates/fastlane/screenshots.yml` |

- The brief is prose and tables a person edits. The config is what code reads. Never keep a market
  list in two places: the brief points to the config for markets.
- Mark every answer the developer did not give as an assumption ("assumed: light, the app's
  default"), so they see what to check.
- The developer's rules go in verbatim, with their source (a file path or "pasted on <date>"). If
  the repo has a translation guide or glossary, link it and copy only the terms the copy will use.
- Write the storyboard as a table: slot, feature, surface, the one promise, what renders, what is
  generated. Slots 1 to 3 carry the story.
- Log the brief's approval as the first row of the decisions log.

### From answers to files

| Answer | Goes to |
|---|---|
| Features and order | Brief, "Features to show" and "Storyboard" |
| Surfaces | Brief, "Surfaces"; Android config `surfaces` (`"screens"` always, the rest only if chosen) |
| Design direction, reference, frames, light or dark | Brief, "Design direction"; a reference set in `docs/screenshots/references/` |
| First market, later markets | Config (Android) or `screenshots.yml` (iOS), first market as `default`, every market `upload: false`; the brief lists the order only |
| Native readers | Brief, "Markets", per locale |
| Copy rules, register, banned words, glossary | Brief, "Your rules" |
| Claims | Brief, "Claims allowed", each with its source; none by default |
| Art kind and budget | Brief, "Art" |
| Stores, who uploads | Brief, "Store targets and upload" |
