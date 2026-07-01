class OpenScribe < Formula
  desc "YouTube video transcription tool with multiple engines"
  homepage "https://github.com/ysys143/open-scribe"
  url "https://github.com/ysys143/open-scribe/archive/refs/tags/0.2.0.tar.gz"
  sha256 "c3bce71c8886c4bd417476eb6476fdc35b26c80802466a044f1ebf94b19b35f5"
  license "MIT"

  depends_on "python@3.11"
  depends_on "uv"

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
          local UPDATE_OUTPUT=$(uv pip install --upgrade yt-dlp -p "$PYTHON_PATH" 2>&1)
          if echo "$UPDATE_OUTPUT" | grep -q "Successfully installed"; then
            echo "[OK] yt-dlp가 업데이트되었습니다"
          else
            echo "[OK] yt-dlp가 최신 버전입니다: $CURRENT_VERSION"
          fi
        fi

        mkdir -p "$(dirname "$VERSION_CHECK_FILE")"
        echo "$CURRENT_DATE" > "$VERSION_CHECK_FILE"
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
