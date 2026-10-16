import Cocoa

/// Small Settings window (Cmd+,) for choosing the page Hover opens at launch.
final class SettingsWindowController: NSWindowController, NSTextFieldDelegate {

    private let choicePopUp = NSPopUpButton()
    private let addressField = NSTextField()
    private let useCurrentButton = NSButton(title: "Use Current Page", target: nil, action: nil)
    private let hintLabel = NSTextField(wrappingLabelWithString: "")
    private var grid: NSGridView!
    private let currentPageURL: () -> URL?

    /// `currentPageURL` returns the player's current address, for "Use Current Page".
    init(currentPageURL: @escaping () -> URL?) {
        self.currentPageURL = currentPageURL
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 160),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Hover Settings"
        // The player floats above other windows, so Settings must too or it opens behind it
        window.level = .floating
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildContent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func show() {
        refresh()
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Layout

    private func buildContent() {
        for page in StartPage.allCases {
            choicePopUp.addItem(withTitle: page.title)
        }
        choicePopUp.target = self
        choicePopUp.action = #selector(choiceChanged)

        addressField.placeholderString = "https://www.youtube.com/watch?v=…"
        addressField.delegate = self
        addressField.translatesAutoresizingMaskIntoConstraints = false
        addressField.widthAnchor.constraint(equalToConstant: 300).isActive = true

        useCurrentButton.bezelStyle = .rounded
        useCurrentButton.target = self
        useCurrentButton.action = #selector(useCurrentPage)

        hintLabel.textColor = .secondaryLabelColor
        hintLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        hintLabel.preferredMaxLayoutWidth = 300

        grid = NSGridView(views: [
            [NSTextField(labelWithString: "Open at launch:"), choicePopUp],
            [NSGridCell.emptyContentView, addressField],
            [NSGridCell.emptyContentView, useCurrentButton],
            [NSGridCell.emptyContentView, hintLabel],
        ])
        grid.column(at: 0).xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 8
        grid.columnSpacing = 8
        grid.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            grid.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
        ])
        window?.contentView = content
    }

    // MARK: - State

    private func refresh() {
        choicePopUp.selectItem(at: StartPage.allCases.firstIndex(of: StartPage.current) ?? 0)
        addressField.stringValue = StartPage.customAddress
        updateRows()
    }

    /// The address field and its button only apply to "A Specific Page".
    private func updateRows() {
        let isCustom = StartPage.current == .custom
        grid.row(at: 1).isHidden = !isCustom
        grid.row(at: 2).isHidden = !isCustom
        updateHint()
    }

    /// Grow or shrink the window as rows show and hide, keeping its top edge in place.
    private func fitWindowToContent() {
        guard let window, let content = window.contentView else { return }
        content.layoutSubtreeIfNeeded()
        let size = content.fittingSize
        var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: size))
        frame.origin = NSPoint(x: window.frame.minX, y: window.frame.maxY - frame.height)
        window.setFrame(frame, display: true)
    }

    private func updateHint(_ override: String? = nil) {
        // The hint can wrap to two lines, so refit the window after every change
        defer { fitWindowToContent() }
        if let override {
            hintLabel.stringValue = override
            return
        }
        switch StartPage.current {
        case .watchLater:
            hintLabel.stringValue = "Your Watch Later playlist. When you're signed out, Hover opens YouTube Home instead."
        case .home:
            hintLabel.stringValue = "YouTube's home page. Works signed in or out."
        case .custom:
            hintLabel.stringValue = StartPage.youTubeURL(from: StartPage.customAddress) == nil
                ? "Enter a YouTube address. Until then, Hover opens Watch Later (or Home when signed out)."
                : "Hover opens this page at launch."
        }
    }

    // MARK: - Actions

    @objc private func choiceChanged() {
        let index = choicePopUp.indexOfSelectedItem
        guard StartPage.allCases.indices.contains(index) else { return }
        StartPage.current = StartPage.allCases[index]
        updateRows()
        if StartPage.current == .custom, StartPage.customAddress.isEmpty {
            window?.makeFirstResponder(addressField)
        }
    }

    @objc private func useCurrentPage() {
        guard let url = currentPageURL(), StartPage.youTubeURL(from: url.absoluteString) != nil else {
            NSSound.beep()
            updateHint("The page open in Hover isn't a YouTube page.")
            return
        }
        addressField.stringValue = url.absoluteString
        StartPage.customAddress = url.absoluteString
        updateHint()
    }

    func controlTextDidChange(_ notification: Notification) {
        StartPage.customAddress = addressField.stringValue
        updateHint()
    }
}
