# Lanes for the store art pipeline. Paste into fastlane/Fastfile inside `platform :ios do ... end`
# and adapt the constants. They assume screenshots.yml from this folder.
require "yaml"

ROOT = File.expand_path("..", __dir__)
MANIFEST = YAML.load_file(File.join(ROOT, "screenshots.yml"))

def selected_locales(options, allowed)
  list = options[:locales] ? options[:locales].split(",").map(&:strip) : allowed
  list.empty? ? UI.user_error!("No locales selected") : list
end

desc "Render store art on the dedicated simulator. Options: slot:Slot03Markets locales:en-US,tr"
lane :render do |options|
  slot = options[:slot] || UI.user_error!("Pass slot:<TestName> (runs test<TestName>)")
  env = options[:locales] ? "TEST_RUNNER_STOREART_MARKET=#{options[:locales]} " : ""
  sh("cd #{ROOT} && #{env}scripts/screenshots/render.sh #{slot}")
end

desc "Fail on any wrong size or alpha channel before anything is staged"
lane :verify do
  sizes = MANIFEST.dig("render", "canvas").join("x")
  sh("#{ROOT}/scripts/screenshots/tools/verify-export.sh #{ROOT}/#{MANIFEST.dig('render', 'output_dir')} #{sizes}")
end

desc "Copy approved renders into fastlane/screenshots/<locale>/<NN>_iphone.png"
lane :stage do |options|
  allowed = MANIFEST.dig("upload", "locales")
  locales = selected_locales(options, allowed)
  blocked = locales - allowed
  UI.user_error!("Not approved for upload (add to upload.locales): #{blocked.join(', ')}") unless blocked.empty?

  out = File.join(ROOT, MANIFEST.dig("render", "output_dir"))
  staged = File.join(ROOT, "fastlane/.upload_staging")
  FileUtils.rm_rf(staged)
  locales.each do |locale|
    files = Dir.glob(File.join(out, "default_#{locale}_iphone_*.png")).sort
    UI.user_error!("No renders for #{locale}. Run render first.") if files.empty?
    FileUtils.mkdir_p(File.join(staged, locale))
    files.each { |f| FileUtils.cp(f, File.join(staged, locale, File.basename(f).sub("default_#{locale}_iphone_", "").sub(".png", "_iphone.png"))) }
  end
  UI.success("Staged #{locales.join(', ')} in #{staged}")
end

desc "Upload staged screenshots. Shows the HTML preview and asks first; never submits for review"
lane :upload do |options|
  verify
  stage(options)
  deliver(
    app_identifier: MANIFEST.dig("app", "bundle_id"),
    app_version: options[:version] || MANIFEST.dig("app", "upload_version"),
    screenshots_path: File.join(ROOT, "fastlane/.upload_staging"),
    overwrite_screenshots: true,
    skip_binary_upload: true,
    skip_metadata: true,
    skip_app_version_update: true,
    submit_for_review: false,
    automatic_release: false,
    run_precheck_before_submit: false,
    force: options[:force].to_s == "true" # false shows the preview and asks before uploading
  )
  FileUtils.rm_rf(File.join(ROOT, "fastlane/.upload_staging"))
end
