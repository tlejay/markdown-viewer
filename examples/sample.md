# Markdown Viewer — Sample

A quick file to exercise the renderer. If everything below looks right, the app works.

## Text formatting

You can write **bold**, *italic*, ~~strikethrough~~, and `inline code`. Here's a [link](https://madebytle.com) and a footnote-style reference.

> A blockquote to check the left border and muted color.
>
> — someone wise

## Lists

- Unordered item
- Another item
  - Nested item
  - Nested item

1. First
2. Second
3. Third

### Task list

- [x] Read the file synchronously
- [x] Paint on the first frame
- [ ] Take over the world

## Table

| Feature        | Status | Notes                         |
| -------------- | :----: | ----------------------------- |
| GitHub styling |   ✅   | via swift-markdown-ui         |
| Live reload    |   ✅   | DispatchSource file watcher   |
| Dark mode      |   ✅   | System / Light / Dark         |
| Fast cold start|   ✅   | no web engine                 |

## Code block

```swift
struct MarkdownDocument: FileDocument {
    var text: String
    init(configuration: ReadConfiguration) throws {
        text = configuration.file.regularFileContents
            .map { String(decoding: $0, as: UTF8.self) } ?? ""
    }
}
```

```bash
make install
open "/Applications/Markdown Viewer.app"
```

## Image

![A placeholder](https://placehold.co/600x200/1f2436/ffffff/png?text=Markdown+Viewer)

---

That's the tour. Edit this file in any editor and watch it live-reload.
