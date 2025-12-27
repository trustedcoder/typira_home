# How to Activate the Typira Keyboard Extension

I have generated the source files for the iOS Keyboard Extension, but you must manually add the Target to your Xcode project for it to compile and bundle correctly.

## Steps:

1.  Open `ios/Runner.xcworkspace` in Xcode.
2.  Go to **File > New > Target...**.
3.  Choose **Custom Keyboard Extension** (under iOS > Application Extension).
4.  Click **Next**.
5.  **Product Name**: `TypiraKeyboard` (Must match the folder name I created).
6.  **Team**: Select your development team.
7.  **Language**: Swift.
8.  **Finish**. 
    *   *If Xcode asks to "Activate" the scheme, say Yes.*
9.  **Important**: Xcode will generate its own `KeyboardViewController.swift` and `Info.plist`.
    *   You can delete the default generated `KeyboardViewController.swift`.
    *   Right-click the `TypiraKeyboard` folder in the Xcode project navigator, choose "Add Files to Runner...", and select the `KeyboardViewController.swift` and `Info.plist` (or copy contents) from the directory `mobile/typira/ios/TypiraKeyboard` if they aren't already there.
    *   *Simpler*: Since I created the files on disk, when you create the Target named `TypiraKeyboard`, Xcode might create a NEW folder.
    *   **Recommended**: Just copy the code I wrote in `mobile/typira/ios/TypiraKeyboard/KeyboardViewController.swift` into the file Xcode creates for you.

## Files I Created:
- `mobile/typira/ios/TypiraKeyboard/KeyboardViewController.swift`: The logic for the keyboard.
- `mobile/typira/ios/TypiraKeyboard/Info.plist`: The configuration.
