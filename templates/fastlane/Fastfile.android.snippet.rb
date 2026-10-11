# Google Play store art lane. Paste into fastlane/Fastfile inside `platform :android do ... end`.
# It reads the developer's storeart.config.json (templates/android/storeart.config.json): the
# allow list is every market with "upload": true. Nothing here names a locale.
#
#   store/page/tools/render-all.sh all && store/page/tools/stage-play.sh [--variant <name>]
#   fastlane upload_art locales:en-US validate_only:true      dry run: Play checks the edit, nothing changes
#   fastlane upload_art locales:en-US                         the real upload (the developer runs this)
#
# Facts that shape it:
# - Play has no draft for listing art. Images go live when the edit commits; validate_only first.
# - The language must already exist on the store listing (add it in Play Console), or the edit fails.
# - supply replaces that locale's images of each uploaded type (all phone screenshots, all Wear OS
#   screenshots when wearScreenshots/ is staged, the feature graphic). It does not merge.
# - Play Console asks whether listing assets were made or edited with AI. That declaration is made
#   in Play Console, not here: docs/android-end-to-end.md, "Store submission checklist".
# - fastlane may be a Homebrew install with no Gemfile: run `fastlane`, not `bundle exec fastlane`.
# - After an upload, pull the listing back (Play Console, or `fastlane supply init` into a scratch
#   folder) and compare it with out/play. A success line is not proof.
require "json"
require "tmpdir"
require "fileutils"

STOREART_ROOT = File.expand_path("..", __dir__)
STOREART_CONFIG = File.join(STOREART_ROOT, "store", "storeart.config.json")
STOREART_STAGED = File.join(STOREART_ROOT, "store", "page", "out", "play")

desc "Upload store art (images only): fastlane upload_art locales:<a,b> [validate_only:true]"
lane :upload_art do |options|
  config = JSON.parse(File.read(STOREART_CONFIG))
  allowed = config.fetch("markets").select { |m| m["upload"] == true }.map { |m| m.fetch("storeLocale") }
  known = config.fetch("markets").map { |m| m.fetch("storeLocale") }

  locales = (options[:locales] || "").split(",").map(&:strip).reject(&:empty?).uniq
  UI.user_error!("locales: is required (comma list of storeLocale values)") if locales.empty?
  unknown = locales - known
  UI.user_error!("Not in storeart.config.json: #{unknown.join(', ')}") unless unknown.empty?
  blocked = locales - allowed
  UI.user_error!("Not approved for upload (set \"upload\": true in the config): #{blocked.join(', ')}") unless blocked.empty?
  UI.user_error!("Nothing staged: run store/page/tools/stage-play.sh") unless Dir.exist?(STOREART_STAGED)
  missing = locales.reject { |l| Dir.exist?(File.join(STOREART_STAGED, l, "images", "phoneScreenshots")) }
  UI.user_error!("Not staged: #{missing.join(', ')}") unless missing.empty?

  # Upload from a temp tree that holds only the requested locales, so no other locale is touched.
  Dir.mktmpdir do |tmp|
    locales.each { |l| FileUtils.cp_r(File.join(STOREART_STAGED, l), File.join(tmp, l)) }
    upload_to_play_store(
      metadata_path: tmp,
      skip_upload_apk: true,
      skip_upload_aab: true,
      skip_upload_metadata: true,
      skip_upload_changelogs: true,
      skip_upload_images: false,
      skip_upload_screenshots: false,
      sync_image_upload: true,
      validate_only: options[:validate_only] == true || options[:validate_only].to_s == "true"
    )
  end
end
