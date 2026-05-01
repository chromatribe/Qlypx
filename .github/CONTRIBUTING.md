# Contributing to Qlypx

:tada: Thank you for contributing to Qlypx :tada:

Qlypx is a modern, clean, and fast clipboard manager optimized for Apple Silicon and the latest macOS.

## Core Values & Guidelines

When contributing, please keep the following principles in mind:

- **Native First**: Prioritize Apple's standard frameworks. Minimize external dependencies.
- **Lightweight & Fast**: Keep binary size, memory usage, and CPU load to a minimum.
- **Modern Architecture**:
    - Use **Swift Package Manager (SPM)** for any necessary libraries.
    - Use **Combine** for data binding and state management.
    - Use **Codable** for persistence (JSON-based).
    - Use the `qly_observe` extension for monitoring `UserDefaults` changes.
- **System Friendly**: Follow the latest macOS design guidelines (Unified Toolbar, SF Symbols, etc.).

## Localization

We welcome translations for new languages!

### Add New Language

1. Open `Qlypx.xcodeproj` in Xcode.
2. Select the project in the Project Navigator.
3. In the **Info** tab, under the **Localizations** section, click the `+` button and select the language.

### Localization Files

Please update the following `.strings` files for your language:

- **Main UI Strings**: `Qlypx/Resources/#{language_name}.lproj/Localizable.strings`
- **Preferences**: `Qlypx/Sources/Preferences/#{language_name}.lproj/*.strings`
- **Preference Panels**: `Qlypx/Sources/Preferences/Panels/#{language_name}.lproj/*.strings`
- **Snippets Editor**: `Qlypx/Sources/Snippets/#{language_name}.lproj/*.strings`

## Development Setup

1. Clone the repository.
2. Open `Qlypx.xcodeproj`.
3. Swift Package Manager (SPM) dependencies will be resolved automatically.
4. To create a production build, use **Product > Archive** in Xcode.
