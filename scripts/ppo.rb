#!/usr/bin/env ruby
# Product Page Optimization: builds an experiment with one treatment and uploads
# the StoreArt renders into it, one screenshot set per locale. fastlane deliver
# cannot do this, so it talks to the App Store Connect API through spaceship.
#
#   ruby ppo.rb plan                 what would be created, nothing written
#   ruby ppo.rb upload [en-US,tr]    create (or reuse) and upload
#   ruby ppo.rb status               experiment state and screenshot counts
#   ruby ppo.rb headers [en-US,tr]   upload the product page headers into the treatment
#
# Configure with environment variables (or fastlane/.env, which is loaded):
#   PPO_BUNDLE_ID (required)   PPO_EXPERIMENT (default "Localized screenshots")   PPO_TREATMENT (default "Localized art")
#   PPO_TRAFFIC (default 50)   PPO_ART_DIR (default StoreArt/Output)              PPO_SLOTS (default 7)
#   PPO_DISPLAY_TYPE (default APP_IPHONE_67)
#   APP_STORE_CONNECT_API_KEY_KEY_ID, APP_STORE_CONNECT_API_KEY_ISSUER_ID, APP_STORE_CONNECT_API_KEY_KEY_FILEPATH
# Art files are named <PPO_ART_DIR>/default_<locale>_iphone_<NN>.png and <PPO_ART_DIR>/header/default_<locale>_header.png.
# Written for one app and verified against the live App Store Connect API on 2026-10-09; the endpoints
# and field names come from the API's OpenAPI spec, so re-check them against the current one.
#
# Safe to re-run: the experiment, treatment, localizations and sets are looked
# up by name before they are created, and a set that already holds every slot is
# skipped. This never starts the test. Starting it sends the treatment to App
# Review, which is done in App Store Connect (or with `start`) on purpose.
require "spaceship"
require "dotenv"
require "digest"
require "net/http"

ROOT = Dir.pwd # run it from the repository root
Dotenv.load(File.join(ROOT, "fastlane", ".env"))

BUNDLE_ID = ENV.fetch("PPO_BUNDLE_ID") { abort("Set PPO_BUNDLE_ID to the app's bundle id") }
EXPERIMENT_NAME = ENV.fetch("PPO_EXPERIMENT", "Localized screenshots")
TREATMENT_NAME = ENV.fetch("PPO_TREATMENT", "Localized art")
TRAFFIC = ENV.fetch("PPO_TRAFFIC", "50").to_i # percent of eligible visitors who see the treatment; the rest see today's page
DISPLAY_TYPE = ENV.fetch("PPO_DISPLAY_TYPE", "APP_IPHONE_67") # the API has no 6.9 value; 1320 x 2868 goes in the 6.7 slot
ART_DIR = File.expand_path(ENV.fetch("PPO_ART_DIR", File.join("StoreArt", "Output")), ROOT)
SLOTS = (1..ENV.fetch("PPO_SLOTS", "7").to_i).to_a
HEADER_DIR = File.join(ART_DIR, "header")
HEADER_PLACEMENT = "PRODUCT_PAGE_HEADER_ASSET" # 3840 x 1646 PNG, no alpha, one per localization

def login
  issuer = ENV["APP_STORE_CONNECT_API_KEY_ISSUER_ID"].to_s.strip
  Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
    key_id: ENV.fetch("APP_STORE_CONNECT_API_KEY_KEY_ID"),
    issuer_id: issuer.empty? ? nil : issuer,
    filepath: File.expand_path(ENV.fetch("APP_STORE_CONNECT_API_KEY_KEY_FILEPATH")),
    duration: 1200
  )
end

def client = Spaceship::ConnectAPI.client.tunes_request_client

def get(path, params = nil) = client.get(path, params).body
def post(path, body) = client.post(path, body).body
def patch(path, body) = client.patch(path, body).body

def files_for(locale)
  SLOTS.map { |n| File.join(ART_DIR, format("default_%s_iphone_%02d.png", locale, n)) }
end

def say(message) = puts("[#{Time.now.strftime('%H:%M:%S')}] #{message}")

def find_or_create_experiment(app_id)
  existing = get("v1/apps/#{app_id}/appStoreVersionExperimentsV2", { limit: 50 })["data"]
  found = existing.find { |e| e.dig("attributes", "name") == EXPERIMENT_NAME }
  return found if found

  say("Creating experiment #{EXPERIMENT_NAME.inspect}")
  post("v2/appStoreVersionExperiments", {
    data: {
      type: "appStoreVersionExperiments",
      attributes: { name: EXPERIMENT_NAME, platform: "IOS", trafficProportion: TRAFFIC },
      relationships: { app: { data: { type: "apps", id: app_id } } }
    }
  })["data"]
end

def find_or_create_treatment(experiment_id)
  existing = get("v2/appStoreVersionExperiments/#{experiment_id}/appStoreVersionExperimentTreatments", { limit: 10 })["data"]
  found = existing.find { |t| t.dig("attributes", "name") == TREATMENT_NAME }
  return found if found

  say("Creating treatment #{TREATMENT_NAME.inspect}")
  post("v1/appStoreVersionExperimentTreatments", {
    data: {
      type: "appStoreVersionExperimentTreatments",
      attributes: { name: TREATMENT_NAME },
      relationships: { appStoreVersionExperimentV2: { data: { type: "appStoreVersionExperiments", id: experiment_id } } }
    }
  })["data"]
end

def find_or_create_localization(treatment_id, locale)
  existing = get("v1/appStoreVersionExperimentTreatments/#{treatment_id}/appStoreVersionExperimentTreatmentLocalizations", { limit: 50 })["data"]
  found = existing.find { |l| l.dig("attributes", "locale") == locale }
  return found if found

  post("v1/appStoreVersionExperimentTreatmentLocalizations", {
    data: {
      type: "appStoreVersionExperimentTreatmentLocalizations",
      attributes: { locale: locale },
      relationships: { appStoreVersionExperimentTreatment: { data: { type: "appStoreVersionExperimentTreatments", id: treatment_id } } }
    }
  })["data"]
end

def find_or_create_set(localization_id)
  existing = get("v1/appStoreVersionExperimentTreatmentLocalizations/#{localization_id}/appScreenshotSets", { limit: 20 })["data"]
  found = existing.find { |s| s.dig("attributes", "screenshotDisplayType") == DISPLAY_TYPE }
  return found if found

  post("v1/appScreenshotSets", {
    data: {
      type: "appScreenshotSets",
      attributes: { screenshotDisplayType: DISPLAY_TYPE },
      relationships: { appStoreVersionExperimentTreatmentLocalization: { data: { type: "appStoreVersionExperimentTreatmentLocalizations", id: localization_id } } }
    }
  })["data"]
end

def shots_in(set_id)
  get("v1/appScreenshotSets/#{set_id}/appScreenshots", { limit: 20 })["data"]
end

def upload_locale(treatment_id, locale)
  files = files_for(locale)
  missing = files.reject { |f| File.exist?(f) }
  raise "#{locale}: missing #{missing.map { |f| File.basename(f) }.join(', ')}" unless missing.empty?

  localization = find_or_create_localization(treatment_id, locale)
  set = find_or_create_set(localization["id"])
  present = shots_in(set["id"])
  broken = present.select { |s| s.dig("attributes", "assetDeliveryState", "state") == "FAILED" }
  broken.each { |s| client.delete("v1/appScreenshots/#{s['id']}") }
  present -= broken

  # A partial set is cleared and redone: slot order matters and the API appends.
  if present.size == SLOTS.size
    say("#{locale}: already has #{SLOTS.size}, skipped")
    return
  end
  present.each { |s| client.delete("v1/appScreenshots/#{s['id']}") }

  files.each do |path|
    Spaceship::ConnectAPI::AppScreenshot.create(app_screenshot_set_id: set["id"], path: path, wait_for_processing: false)
  end
  say("#{locale}: uploaded #{files.size}")
end

def header_file(locale) = File.join(HEADER_DIR, "default_#{locale}_header.png")

# Headers do not go through appScreenshotSets: they live in the app's Asset Library as
# CREATIVE_ASSETS images, and a placement ties an image to the treatment localization.
def find_or_upload_header(library_id, locale)
  path = header_file(locale)
  raise "#{locale}: missing #{File.basename(path)}" unless File.exist?(path)

  reference = "header #{locale} (#{Digest::MD5.file(path).hexdigest[0, 8]})"
  found = get("v1/appAssetLibraries/#{library_id}/images", { "filter[referenceName]" => reference, limit: 5 })["data"]
            .find { |i| i.dig("attributes", "state") != "ARCHIVED" && i.dig("attributes", "state") != "FAILED" }
  return found if found

  bytes = File.binread(path)
  image = post("v1/appAssetLibraryImages", {
    data: {
      type: "appAssetLibraryImages",
      attributes: { category: "CREATIVE_ASSETS", fileName: File.basename(path), fileSize: bytes.bytesize, referenceName: reference },
      relationships: { assetLibrary: { data: { type: "appAssetLibraries", id: library_id } } }
    }
  })["data"]

  image.dig("attributes", "uploadOperations").each do |op|
    uri = URI(op["url"])
    request = Net::HTTP.const_get(op["method"].capitalize).new(uri)
    op["requestHeaders"].each { |h| request[h["name"]] = h["value"] }
    request.body = bytes.byteslice(op["offset"], op["length"])
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
    raise "#{locale}: upload part failed (#{response.code})" unless response.is_a?(Net::HTTPSuccess)
  end
  patch("v1/appAssetLibraryImages/#{image['id']}", { data: { type: "appAssetLibraryImages", id: image["id"], attributes: { uploaded: true } } })
  image
end

def upload_header(library_id, treatment_id, locale)
  localization = find_or_create_localization(treatment_id, locale)
  placed = get("v1/appStoreVersionExperimentTreatmentLocalizations/#{localization['id']}/placements", { limit: 20 })["data"]
  if placed.any? { |pl| pl.dig("attributes", "placementType") == HEADER_PLACEMENT }
    say("#{locale}: header already placed, skipped")
    return
  end

  image = find_or_upload_header(library_id, locale)
  # The image is processed asynchronously; a placement needs it past AWAITING_UPLOAD.
  state = image.dig("attributes", "state")
  20.times do
    break unless %w[AWAITING_UPLOAD UPLOAD_COMPLETE].include?(state)

    sleep 3
    state = get("v1/appAssetLibraryImages/#{image['id']}")["data"].dig("attributes", "state")
  end
  raise "#{locale}: header ended in #{state}" if state == "FAILED"

  post("v1/appAssetLibraryPlacements", {
    data: {
      type: "appAssetLibraryPlacements",
      attributes: { placementType: HEADER_PLACEMENT },
      relationships: {
        image: { data: { type: "appAssetLibraryImages", id: image["id"] } },
        appStoreVersionExperimentTreatmentLocalization: { data: { type: "appStoreVersionExperimentTreatmentLocalizations", id: localization["id"] } }
      }
    }
  })
  say("#{locale}: header placed (image #{state})")
end

def header_locales(arg)
  all = Dir.children(HEADER_DIR).filter_map { |f| f[/\Adefault_(.+)_header\.png\z/, 1] }.sort
  return all if arg.to_s.strip.empty?

  list = arg.split(",").map(&:strip)
  unknown = list - all
  abort("No header for: #{unknown.join(', ')}") unless unknown.empty?
  list
end

def selected_locales(arg)
  all = Dir.children(ART_DIR).filter_map { |f| f[/\Adefault_(.+)_iphone_01\.png\z/, 1] }.sort
  return all if arg.to_s.strip.empty?

  list = arg.split(",").map(&:strip)
  unknown = list - all
  abort("No art for: #{unknown.join(', ')}") unless unknown.empty?
  list
end

cmd = ARGV[0] || "plan"
locales = cmd == "headers" ? header_locales(ARGV[1]) : selected_locales(ARGV[1])

case cmd
when "plan"
  puts "Experiment #{EXPERIMENT_NAME.inspect}, #{TRAFFIC}% treatment, treatment #{TREATMENT_NAME.inspect}"
  puts "#{locales.size} locales x #{SLOTS.size} screenshots (#{DISPLAY_TYPE}): #{locales.join(' ')}"
  locales.each do |l|
    files_for(l).each { |f| puts "  missing #{f}" unless File.exist?(f) }
  end
when "upload"
  login
  app = Spaceship::ConnectAPI::App.find(BUNDLE_ID) || abort("#{BUNDLE_ID} not found")
  experiment = find_or_create_experiment(app.id)
  say("Experiment #{experiment['id']} (#{experiment.dig('attributes', 'state')})")
  treatment = find_or_create_treatment(experiment["id"])
  locales.each do |locale|
    upload_locale(treatment["id"], locale)
  rescue => e
    say("#{locale}: FAILED #{e.class} #{e.message[0, 1200]}")
  end
when "headers"
  login
  app = Spaceship::ConnectAPI::App.find(BUNDLE_ID) || abort("#{BUNDLE_ID} not found")
  experiment = find_or_create_experiment(app.id)
  treatment = find_or_create_treatment(experiment["id"])
  library_id = get("v1/apps/#{app.id}/assetLibrary")["data"]["id"]
  locales.each do |locale|
    upload_header(library_id, treatment["id"], locale)
  rescue => e
    say("#{locale}: FAILED #{e.class} #{e.message[0, 600]}")
  end
when "status"
  login
  app = Spaceship::ConnectAPI::App.find(BUNDLE_ID) || abort("#{BUNDLE_ID} not found")
  get("v1/apps/#{app.id}/appStoreVersionExperimentsV2", { limit: 50 })["data"].each do |e|
    a = e["attributes"]
    puts "#{a['name']}: #{a['state']}, #{a['trafficProportion']}% treatment, started #{a['startDate'] || '-'}"
    get("v2/appStoreVersionExperiments/#{e['id']}/appStoreVersionExperimentTreatments")["data"].each do |t|
      puts "  treatment #{t['attributes']['name']}"
      get("v1/appStoreVersionExperimentTreatments/#{t['id']}/appStoreVersionExperimentTreatmentLocalizations", { limit: 50 })["data"].sort_by { |l| l["attributes"]["locale"] }.each do |l|
        counts = get("v1/appStoreVersionExperimentTreatmentLocalizations/#{l['id']}/appScreenshotSets", { limit: 20 })["data"].map do |s|
          states = shots_in(s["id"]).map { |x| x.dig("attributes", "assetDeliveryState", "state") }.tally
          "#{s['attributes']['screenshotDisplayType']} #{states}"
        end
        headers = get("v1/appStoreVersionExperimentTreatmentLocalizations/#{l['id']}/placements", { limit: 20 })["data"]
                    .select { |pl| pl.dig("attributes", "placementType") == HEADER_PLACEMENT }
                    .map { |pl| "header #{pl.dig('attributes', 'state')}" }
        puts "    #{l['attributes']['locale']}: #{(counts + headers).join('; ')}"
      end
    end
  end
else
  abort("Usage: ppo.rb plan|upload|status [locale,locale]")
end
