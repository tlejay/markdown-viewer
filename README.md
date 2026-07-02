# Markdown Viewer

A tiny, native macOS Markdown viewer. Right-click a `.md` file → **Open With** → and it's on screen before you've let go of the mouse.

---

## Start with Why

There is no shortage of Markdown apps. Some are heavy editors that take a full second to boot. Some are Electron wrappers that eat 300 MB of RAM to show a page of text. Some render beautifully but hide it behind a subscription, an account, and a splash screen.

None of them felt right for the one thing I do most: **glance at a `.md` file.**

I didn't want to write. I didn't want to sync. I just wanted to double-click a file and *read it*, styled the way GitHub styles it, as fast as hitting the spacebar on a photo in Finder.

So I built the smallest possible thing that does exactly that — and nothing else.

This isn't here to solve a problem for the whole world. It's here as a clean, honest starting point: a real native macOS app, small enough to read in one sitting, that you can fork and shape into whatever *your* ideal Markdown viewer looks like. Add a table of contents. Wire in your own theme. Bolt on export. It's yours.

**Why it's built the way it is:**

- **Native Swift + SwiftUI.** No web view, no Chromium, no runtime to warm up. Just AppKit and the OS.
- **GitHub-quality rendering** via [`swift-markdown-ui`](https://github.com/gonzalezreal/swift-markdown-ui) — headings, tables, fenced code with syntax highlighting, task lists, blockquotes, images.
- **Cold start is the feature.** The file is read synchronously and painted on the first frame; everything non-essential (file watching) is deferred until *after* you can already see your document. The goal is Preview / Quick Look speed.
- **No Apple Developer account required.** It's ad-hoc signed and built with a plain shell script. Clone it, run one command, and it's in your Applications folder.

## Features

- 📄 Open Markdown from Finder's **right-click → Open With** (or set it as the default app)
- ⚡ Fast cold start — no web engine, first paint on launch
- 🎨 GitHub-style rendering (tables, code highlighting, task lists, images)
- 🔄 **Live reload** — edit the file in any editor, the view updates itself
- 🌓 **Light / Dark / System** appearance
- 🔠 **Font zoom** — `⌘ +` / `⌘ −` / `⌘ 0`
- 🪟 **Multiple files** — native window tabs, one document per window

## Requirements

- macOS 13 (Ventura) or later
- Swift toolchain — either full Xcode **or** just the Command Line Tools (`xcode-select --install`). No Xcode project, no `xcodebuild`.

## Build & Install

```bash
git clone https://github.com/<you>/markdown-viewer.git
cd markdown-viewer

# Build the .app, then install to ~/Applications and register with Finder
make install
```

That's it. Now in Finder, right-click any `.md` file → **Open With → Markdown Viewer**.
To make it permanent: select a `.md` file → **Get Info → Open with → Markdown Viewer → Change All…**

### Other commands

```bash
make build    # just build dist/Markdown Viewer.app
make run      # build and launch
make dev      # fast debug run during development (swift run)
make clean    # remove build artifacts
```

## A note on Gatekeeper

Because there's no paid Developer ID signing this app is **ad-hoc signed**. On the machine that built it, it just runs. If you copy it to *another* Mac, macOS may block it the first time — right-click the app → **Open**, or run:

```bash
xattr -dr com.apple.quarantine "/Applications/Markdown Viewer.app"
```

This is expected for any self-signed app and is not a bug.

## How it's laid out

```
Sources/MarkdownViewer/
  MarkdownViewerApp.swift   # @main App — DocumentGroup gives open/tabs/windows for free
  MarkdownDocument.swift    # read-only FileDocument (synchronous, cheap)
  DocumentView.swift        # the reading surface (MarkdownUI + toolbar)
  FileWatcher.swift         # DispatchSource-based live reload
  AppSettings.swift         # persisted font scale + appearance
Resources/Info.plist        # document types → this is what enables "Open With"
scripts/build.sh            # compile → assemble .app → ad-hoc sign
scripts/install.sh          # copy to ~/Applications + lsregister
scripts/make-icon.swift     # draws the app icon in code (no image assets)
```

## Make it yours

The whole point. Some starting ideas:

- A sidebar table of contents generated from the headings
- Your own `Theme` in `DocumentView.swift` (swap `.gitHub` for a custom palette)
- Export to PDF / HTML
- A "Share" button that posts to your own link service

Fork it, break it, make it the viewer *you* always wanted.

## License

MIT — see [LICENSE](LICENSE). Built by [Tle](https://madebytle.com).
