cask "omlx" do
  # This cask installs oMLX from the prebuilt DMGs on GitHub without pinning a
  # version or checksum. HOMEBREW_OMLX_VERSION selects what to install (Homebrew
  # only forwards HOMEBREW_-prefixed variables to this file):
  #
  #   unset                      latest stable release (excludes dev/rc)  [default]
  #   HOMEBREW_OMLX_VERSION=rc    latest stable-or-rc release (excludes dev)
  #   HOMEBREW_OMLX_VERSION=pre   latest release including dev and rc prereleases
  #   HOMEBREW_OMLX_VERSION=X.Y.Z that exact release tag (e.g. 0.6.4 or 0.7.1.dev1)
  #
  # Because the version is resolved dynamically, checksums are not pinned and not
  # verified (sha256 :no_check) -- only install versions you trust.
  omlx_version = ENV.fetch("HOMEBREW_OMLX_VERSION", "").sub(/\Av/i, "")
  unless omlx_version.match?(/\A\d/) # not an explicit version -> resolve from the releases feed
    channel = omlx_version.downcase
    include_dev = %w[pre prerelease dev latest edge].include?(channel)
    include_rc = include_dev || channel == "rc"
    require "utils/curl"
    feed = ::Utils::Curl.curl_output(
      "--fail", "--silent", "--location",
      "https://github.com/jundot/omlx/releases.atom"
    ).stdout
    tags = feed.scan(%r{/releases/tag/v?([0-9][0-9A-Za-z.]*)}).flatten.uniq
    tags = tags.grep_v(/dev/i) unless include_dev
    tags = tags.grep_v(/rc/i) unless include_rc
    if tags.empty?
      raise "oMLX: could not resolve a release; set HOMEBREW_OMLX_VERSION to a specific version."
    end

    omlx_version = tags.max_by { |t| ::Gem::Version.new(t.gsub(/(?<=[0-9])(?=[a-z])/i, ".")) }
  end

  # oMLX ships a separate DMG per macOS generation, so the download URL is
  # selected by the host's macOS version below.
  on_sequoia :or_older do
    version omlx_version
    sha256 :no_check

    url "https://github.com/jundot/omlx/releases/download/v#{version}/oMLX-#{version}-macos15-sequoia.dmg"
  end
  on_tahoe :or_newer do
    version omlx_version
    sha256 :no_check

    url "https://github.com/jundot/omlx/releases/download/v#{version}/oMLX-#{version}-macos26-27.dmg"
  end

  name "oMLX"
  desc "Production-ready LLM server for Apple Silicon"
  homepage "https://github.com/jundot/omlx"

  livecheck do
    url "https://github.com/jundot/omlx/releases"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_releases
  end

  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "oMLX.app"
  # Link the bundled CLI as `omlx` on PATH. If the `omlx` formula
  # (`brew install omlx`) already owns that name, Homebrew keeps the formula's
  # link and skips this one with a warning -- the formula wins.
  # The bundled wrapper resolves $0 with realpath, so it works via this symlink.
  binary "#{appdir}/oMLX.app/Contents/MacOS/omlx-cli", target: "omlx"

  uninstall quit: "app.omlx"

  zap trash: [
    "~/.config/omlx",
    "~/.omlx",
    "~/Library/Caches/app.omlx",
    "~/Library/HTTPStorages/app.omlx",
    "~/Library/Preferences/app.omlx.plist",
    "~/Library/Saved Application State/app.omlx.savedState",
  ]

  caveats <<~EOS
    This cask installs the latest stable oMLX release and does not verify
    checksums. Select a different release with HOMEBREW_OMLX_VERSION:
      HOMEBREW_OMLX_VERSION=rc     brew install --cask omlx   # latest stable-or-rc
      HOMEBREW_OMLX_VERSION=pre    brew install --cask omlx   # latest dev/rc
      HOMEBREW_OMLX_VERSION=0.7.0  brew install --cask omlx   # exact version

    oMLX downloads models into the shared Hugging Face cache (~/.cache/huggingface),
    which is intentionally left untouched by `brew uninstall --zap`.

    This cask links an `omlx` CLI onto your PATH. If the `omlx` formula is also
    installed it owns that name instead, and Homebrew skips the cask's link.
  EOS
end
