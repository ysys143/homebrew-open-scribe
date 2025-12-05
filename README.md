# homebrew-open-scribe

Homebrew Tap for [Open-Scribe](https://github.com/jaesolshin/open-scribe) - YouTube video transcription tool.

## Installation

```bash
brew tap jaesolshin/homebrew-open-scribe
brew install open-scribe
```

## Usage

```bash
# Basic usage
scribe "https://www.youtube.com/watch?v=VIDEO_ID"

# With options
scribe "URL" --engine whisper-api --summary
scribe "URL" --timestamp --srt
scribe "PLAYLIST_URL" --parallel 4
```

On first run, you'll be prompted for your OpenAI API Key.

## Update

```bash
brew upgrade open-scribe
```

## Uninstall

```bash
brew uninstall open-scribe
brew untap jaesolshin/homebrew-open-scribe
```

## About

This is the official Homebrew Tap for [Open-Scribe](https://github.com/jaesolshin/open-scribe).

For more information, visit the [main repository](https://github.com/jaesolshin/open-scribe).
