# homebrew-open-scribe

Homebrew Tap for [Open-Scribe](https://github.com/ysys143/open-scribe).

```sh
brew tap ysys143/open-scribe
brew install open-scribe
scr --version
scr config show
scr config validate
scr ls
```

Version 0.3.0 uses `~/.config/open-scribe/settings.json` for general settings.
Old `.env` option defaults are not loaded. Set `copy_to_path` explicitly if copies are desired.
Reference existing credential files in JSON; key values are never stored in JSON or initialized by the wrapper.
See the [upgrade notes](https://github.com/ysys143/open-scribe/releases/tag/0.3.0).

```sh
scr "https://youtu.be/VIDEO_ID"
scr "/path/to/audio.wav" --no-summary
scr ls 20
brew upgrade open-scribe
```

The default Scribe v2 model uses OpenRouter. Existing engines remain available through `--engine`.
The JSON example is installed under the formula's libexec directory.

```sh
brew uninstall open-scribe
brew untap ysys143/open-scribe
```
