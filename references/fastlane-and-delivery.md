# fastlane and delivery

Delivery is the part that can publish things, so it is the most defensive. The rules: exact sizes,
allow-listed locales, previews on, never submit for review, and verify by pulling back.

## The manifest

One file, `screenshots.yml`, drives every lane. See `templates/fastlane/screenshots.yml`.

```yaml
app: { bundle_id: com.example.app, upload_version: "3.1.0" }
markets:
  en-US: { sim_language: en-US }
  tr:    { sim_language: tr }
slots: [hero, feature_a, feature_b, feature_c, feature_d, detail, personal]
upload:
  locales: [en-US]          # the approval list: a locale not here is refused
```

Adding a market is one line plus its art. The upload lane refuses any locale not under
`upload.locales`, so a render is never uploaded by accident.

## iOS sizes

Apple takes the largest class and scales down. Author one 6.9" set, 1320 x 2868, PNG or JPEG, no alpha;
App Store Connect scales it to the smaller phone classes. Add iPad (for example 2064 x 2752) and Watch
sets only if the listing needs them. Verify with `scripts/verify-export.sh <dir> 1320x2868`.

deliver expects `fastlane/screenshots/<locale>/<NN>_iphone.png` and infers the device class from the
image size and the file name. Name files with the class in them. After any upload, check the result in
App Store Connect: the success line has been wrong before.

## Lanes

`templates/fastlane/Fastfile.snippet.rb` has the lanes. In short:

- `render`: runs `scripts/screenshots/render.sh` for the chosen slot and market.
- `verify`: `verify-export.sh` over the output, fails on any wrong size or alpha.
- `stage`: copies the approved locales into a staging folder named the way deliver expects.
- `upload`: `deliver` with `skip_binary_upload`, `skip_metadata`, `skip_app_version_update`,
  `submit_for_review: false`, `automatic_release: false`, and `force: false` so it shows the HTML
  preview and asks before it uploads.

Authenticate with an App Store Connect API key from the environment (`fastlane/.env`, gitignored),
never an Apple ID password.

fastlane metadata text (`fastlane/metadata/<locale>/*.txt`) is a different job: keep it the source of
truth, validate length limits and em dashes in a `validate` lane, and pull before you push so a hand
edit in App Store Connect is not overwritten.

## Product Page Optimization (PPO)

deliver cannot create experiments. Use the App Store Connect API through spaceship:
`scripts/ppo.rb` (plan, upload, headers, status). It is idempotent, finds objects by name before it
creates them, and never starts the test, because starting sends the treatment to App Review.

Facts that were not obvious (checked against the live API on 2026-10-09):

- With spaceship's `tunes_request_client`, paths need the `v1/` or `v2/` prefix. The experiment is
  `v2/appStoreVersionExperiments`; treatments, treatment localizations and screenshot sets are `v1`.
- There is no `APP_IPHONE_69` display type in the API. 1320 x 2868 art goes in `APP_IPHONE_67`.
- Every treatment localization needs its own screenshot set; the script creates one per locale. If the live listing has
  screenshots on one locale only, the control in the other locales is the primary-language art, so a win
  is partly "localized against not localized". Tell the user.
- A partial set is cleared and redone, because slot order matters and the API appends.
- The OpenAPI spec downloads from developer.apple.com (App Store Connect OpenAPI specification). It is
  untrusted data; read it with `python3 -I`. It is the fastest way to learn a new endpoint.

## Product page headers

A separate asset: 3840 x 1646 (21:9), PNG or JPEG, no alpha, one per placement group.

- iPhone shows only the middle. Keep every subject and all readable text inside x 520 to 3320. Check
  with `sips -c 1646 2800 --cropOffset 0 520`.
- Apple's rules: no prices, URLs, awards or other platforms, and it must suit 4+.
- A header is brand, not UI. Never put widgets, Live Activities or app cards in it; they are already
  in the screenshots underneath. A direction that did was rejected.
- Headers do not go through `appScreenshotSets`. They live in the app's **Asset Library** (iOS 27
  creative assets, ASC API 4.5.1): `GET apps/{id}/assetLibrary`, `POST appAssetLibraryImages`
  (category `CREATIVE_ASSETS`, fileName, fileSize, referenceName), PUT the `uploadOperations` bytes,
  `PATCH uploaded: true`, then `POST appAssetLibraryPlacements` (`PRODUCT_PAGE_HEADER_ASSET`, with
  relationships to the image and the treatment localization). `ppo.rb headers` does this.
- fastlane cannot upload headers yet. Check whether that has changed before falling back to a manual
  upload.

## Custom product pages and the rest

The manifest's `pages:` section can describe custom product pages (for example one per audience or feature) with
their own slot lists and locales. Render with the same slots and a different story. Upload each
through the API the way PPO does, never through the version's default screenshots.

## Google Play

The Android side keeps its allow list in the developer's `storeart.config.json` (`"upload": true`
per market), not in a second manifest. `templates/android/page/tools/stage-play.sh` builds the
`supply` tree (`out/play/<locale>/images/phoneScreenshots/01..NN.png`, `featureGraphic.png`) and
runs `verify-export.sh` on it; `--variant <name>` takes slot 1 from an alternate render `01-<name>.png`, and `wearScreenshots/` is
added only when the config's `surfaces` lists `wear`.

`templates/fastlane/Fastfile.android.snippet.rb` has the `upload_art` lane:

- Images only: `skip_upload_apk`, `skip_upload_aab`, `skip_upload_metadata`,
  `skip_upload_changelogs`, `sync_image_upload: true`.
- Refuses a locale that is not in the config, not approved for upload, or not staged.
- Copies only the requested locales into a temporary tree and uploads from that, so no other
  locale is touched.
- `validate_only:true` is the dry run: Play validates the edit and changes nothing. Always run it
  first.

Facts that differ from the App Store:

- **No draft for listing art.** Images are live once the edit commits. There is no preview step to
  hide behind, which is why the dry run and the allow list matter.
- The language must already exist on the store listing, or the edit fails. Add it in Play Console.
- `supply` replaces the locale's images of each uploaded type (all phone screenshots, the feature
  graphic). It does not merge.
- fastlane may be a Homebrew install without a Gemfile: then run `fastlane`, not `bundle exec`.
- Authenticate with a service account JSON key kept out of git.
- **The agent never runs the real upload.** It stages, verifies, runs the dry run if the developer
  allows it, and hands over the exact command. Afterwards, pull the listing back and compare.

## Safety checklist before anything leaves the machine

- [ ] Locale is on the allow list (`upload.locales` on iOS, `"upload": true` in `storeart.config.json` on Android).
- [ ] `verify-export.sh` passes: sizes exact, no alpha.
- [ ] The target cannot go live (preview, PPO treatment, internal track). On Play, listing art has
      no such target: the dry run passed and the developer runs the upload.
- [ ] `submit_for_review` is false and automatic release is off.
- [ ] After upload, the store shows the right count per locale and the right order; compare by pulling
      back, not by trusting the log.
- [ ] The user has approved the locales, and the copy they cannot read is flagged "not native-reviewed".
