# Markdown Viewer (mac-app)

Native macOS Markdown viewer — Swift + SwiftUI, 1 dependency (`swift-markdown-ui`), macOS 13+.
Public repo: [tlejay/markdown-viewer](https://github.com/tlejay/markdown-viewer). เป็น repo แยก — parent `00 Madebytle Kit` ignore โฟลเดอร์นี้ไว้

## Commands

```bash
make build     # dist/Markdown Viewer — madebytle.com.app (arm64 only)
make install   # build + copy to ~/Applications + lsregister
make dev       # swift run
```

## Release (ไฟล์ zip บน GitHub Releases)

`make build` ได้ arm64 อย่างเดียว — Release ต้องเป็น universal:

```bash
make build
swift build -c release --triple x86_64-apple-macosx13.0     # --arch arm64 --arch x86_64 ใช้ไม่ได้ (ไม่มี xcbuild)
lipo -create .build/arm64-apple-macosx/release/MarkdownViewer .build/x86_64-apple-macosx/release/MarkdownViewer -output <app>/Contents/MacOS/MarkdownViewer
codesign --force --deep --sign - --identifier com.madebytle.markdown-viewer <app>
ditto -c -k --keepParent <app> Markdown-Viewer-<ver>-macOS.zip
gh release create v<ver> Markdown-Viewer-<ver>-macOS.zip
```

## ภาพใน README (`docs/`)

ถ่ายจากแอปจริงทั้งหมด (26 ก.ย. 2026) ด้วยสกิล `/kiki-gh-readme` — **UI เปลี่ยนเมื่อไหร่ต้องถ่ายใหม่ทั้งชุด**

- ภาพหน้าต่าง: `screencapture -l <windowID>` (หา window id ด้วย `CGWindowListCopyWindowInfo` กรองด้วย PID)
  ย่อ/ย้ายหน้าต่างด้วย `cliclick` ลากมุม — AppleScript System Events โดน Accessibility บล็อก
- `demo.gif`: หน้าต่าง Ghostty (instance แยก `--window-save-state=never`) รันสคริปต์ที่ append บรรทัดลงไฟล์ทีละขั้น
  คู่กับ viewer ที่ live reload จริง → ถ่ายทีละเฟรม → ffmpeg · TextEdit ใช้ไม่ได้เพราะไม่รีโหลดไฟล์ที่ถูกแก้จากข้างนอก
- `hero.png` / `social-preview.png`: template ของสกิลดัดแปลงให้วางหน้าต่างแอปจริง 2 บาน (light+dark) แทนกรอบเบราว์เซอร์
- เนื้อหาในภาพเป็นเอกสารสมมติ ("Orbit 2.4 Release Notes") — ห้ามถ่ายจากไฟล์งานจริง

## ข้อควรระวังเวลาเขียน README

- โค้ดบล็อก **ไม่มี syntax highlighting** (ไม่ได้ตั้ง `CodeSyntaxHighlighter`) — อย่าเขียนว่ามี
- ปุ่ม Share ต้องใช้ API key ของ `kit.madebytle.com` คนนอกใช้ไม่ได้ — README วางไว้ท้าย ๆ เป็น optional
