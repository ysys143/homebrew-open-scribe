class OpenScribe < Formula
  desc "YouTube video transcription tool with multiple engines"
  homepage "https://github.com/ysys143/open-scribe"
  url "https://github.com/ysys143/open-scribe/archive/refs/tags/0.2.4.tar.gz"
  sha256 "44d551dbbf8810e92d3bb24d8934aee475c5642851d5883b3799954693b4a917"
  license "MIT"

  depends_on "python@3.11"
  depends_on "uv"

  # Rust/maturin wheels bundled in the venv (jiter, pydantic_core) ship an
  # @rpath LC_ID_DYLIB. Homebrew would rewrite it to a long Cellar path, but
  # the pre-built .so has no Mach-O header padding, so the rewrite fails and
  # `brew install` exits non-zero. These are dlopen-ed Python extensions whose
  # dylib ID is never used for linking, so keep the @rpath ID as-is.
  # (Requires Homebrew >= 4.6.17.)
  preserve_rpath

  def install
    # Create installation directory
    prefix_dir = libexec

    # Copy project files to libexec
    cp_r ".", prefix_dir

    # Create Python virtual environment
    system "uv", "venv", "#{prefix_dir}/.venv"

    # Install dependencies using uv
    system "uv", "pip", "install", "--upgrade", "pip", "setuptools", "wheel", "-p", "#{prefix_dir}/.venv"
    system "uv", "pip", "install", "-r", "#{prefix_dir}/requirements.txt", "-p", "#{prefix_dir}/.venv"

    # yt-dlp tracks YouTube's frequent changes; force the newest build past
    # uv's index cache so a fresh install is never stale.
    system "uv", "pip", "install", "--upgrade", "--refresh-package", "yt-dlp", "yt-dlp", "-p", "#{prefix_dir}/.venv"

    # Create wrapper script.
    # API key setup and .env loading are handled entirely by the app:
    # src/config.py loads ~/.config/open-scribe/.env (XDG), `scribe --update-key`
    # rotates the key, and the first run prompts interactively when it is missing.
    bin.mkpath
    (bin/"scribe").write <<~EOS
      #!/bin/bash

      INSTALL_DIR="#{prefix_dir}"
      ENTRY="${INSTALL_DIR}/main.py"
      VENV_ACTIVATE="${INSTALL_DIR}/.venv/bin/activate"

      # Helper function to check and update yt-dlp
      function _check_and_update_ytdlp() {
        local VENV_PATH="$1"
        local PYTHON_PATH="${VENV_PATH}/bin/python"
        local VERSION_CHECK_FILE="${VENV_PATH}/../.ytdlp_version_check"
        local CURRENT_DATE=$(date +%Y%m%d)

        # Check if we already checked today
        if [[ -f "$VERSION_CHECK_FILE" ]]; then
          local LAST_CHECK=$(cat "$VERSION_CHECK_FILE" 2>/dev/null || echo "0")
          if [[ "$LAST_CHECK" == "$CURRENT_DATE" ]]; then
            return 0
          fi
        fi

        echo "[INFO] yt-dlp 버전 확인 중..."
        local CURRENT_VERSION=$(uv pip list -p "$PYTHON_PATH" 2>/dev/null | grep yt-dlp | awk '{print $2}' || echo "not_found")

        if [[ "$CURRENT_VERSION" != "not_found" ]]; then
          # --refresh-package bypasses uv's stale index cache so new releases
          # are actually seen. Decide success by comparing versions, not by
          # grepping output: uv prints "+ yt-dlp==X", not pip's "Successfully
          # installed" (the old grep always missed, so updates were skipped).
          if uv pip install --upgrade --refresh-package yt-dlp yt-dlp -p "$PYTHON_PATH" >/dev/null 2>&1; then
            local NEW_VERSION=$(uv pip list -p "$PYTHON_PATH" 2>/dev/null | grep yt-dlp | awk '{print $2}')
            if [[ -n "$NEW_VERSION" && "$NEW_VERSION" != "$CURRENT_VERSION" ]]; then
              echo "[OK] yt-dlp 업데이트: $CURRENT_VERSION -> $NEW_VERSION"
            else
              echo "[OK] yt-dlp 최신 버전: $CURRENT_VERSION"
            fi
            # Only stamp the marker on a successful check so a failed run
            # (e.g. offline) retries next time instead of silently skipping.
            mkdir -p "$(dirname "$VERSION_CHECK_FILE")"
            echo "$CURRENT_DATE" > "$VERSION_CHECK_FILE"
          else
            echo "[WARN] yt-dlp 업데이트 확인 실패 (다음 실행 때 재시도)"
          fi
        else
          mkdir -p "$(dirname "$VERSION_CHECK_FILE")"
          echo "$CURRENT_DATE" > "$VERSION_CHECK_FILE"
        fi
      }

      # Activate virtualenv
      if [[ -f "$VENV_ACTIVATE" ]]; then
        source "$VENV_ACTIVATE"
      fi

      # Check and update yt-dlp if a URL is provided
      if [[ $# -gt 0 && ("$1" == http://* || "$1" == https://*) ]]; then
        _check_and_update_ytdlp "$INSTALL_DIR/.venv"
      fi

      # Run transcription (the app manages the API key and .env itself)
      exec "#{prefix_dir}/.venv/bin/python" "$ENTRY" "$@"
    EOS
    (bin/"scribe").chmod 0755

    # Shell-agnostic short alias: `scr` works in any shell via PATH, no zsh/bash
    # alias needed.
    bin.install_symlink "scribe" => "scr"
  end

  def post_install
    puts <<~EOS
      [OK] Open-Scribe installed successfully!

      To get started:
        scribe "https://www.youtube.com/watch?v=VIDEO_ID"

      On first run you'll be prompted for your OpenAI API Key, which is
      stored securely at ~/.config/open-scribe/.env.
      Get your key at: https://platform.openai.com/api-keys
      Rotate it later with: scribe --update-key

      Options:
        scribe "URL" --engine whisper-api --summary
        scribe "URL" --timestamp --srt
        scribe "PLAYLIST_URL" --parallel 4

      For more help:
        scribe --help
    EOS
  end

  test do
    system "#{bin}/scribe", "--help"
  end
end
