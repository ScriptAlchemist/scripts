import Foundation

// The UTI for plain text files
let uti = "public.plain-text"

// Path to the Neovim binary
let nvimPath = "/opt/homebrew/bin/nvim"

// Check if the binary exists
let fileManager = FileManager.default
if !fileManager.fileExists(atPath: nvimPath) {
    print("Neovim binary not found at \(nvimPath)")
    exit(1)
}

// Create a wrapper application
let wrapperPath = "\(NSHomeDirectory())/Applications/NeovimWrapper.app"
let wrapperBundleID = "com.custom.NeovimWrapper"

do {
    // Create a basic .app structure
    try fileManager.createDirectory(atPath: wrapperPath, withIntermediateDirectories: true, attributes: nil)
    let wrapperExecutablePath = "\(wrapperPath)/Contents/MacOS/NeovimWrapper"
    try fileManager.createDirectory(atPath: "\(wrapperPath)/Contents/MacOS", withIntermediateDirectories: true, attributes: nil)

    // Write the wrapper script
    let wrapperScript = """
    #!/usr/bin/env bash
    \(nvimPath) "$@"
    """
    try wrapperScript.write(toFile: wrapperExecutablePath, atomically: true, encoding: .utf8)
    try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: wrapperExecutablePath)

    // Create an Info.plist for the app
    let infoPlist = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleIdentifier</key>
        <string>\(wrapperBundleID)</string>
        <key>CFBundleName</key>
        <string>NeovimWrapper</string>
        <key>CFBundleExecutable</key>
        <string>NeovimWrapper</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
    </dict>
    </plist>
    """
    try infoPlist.write(toFile: "\(wrapperPath)/Contents/Info.plist", atomically: true, encoding: .utf8)

    print("Wrapper app created at \(wrapperPath)")
} catch {
    print("Failed to create wrapper: \(error)")
    exit(1)
}

// Use Launch Services to set the default handler
let result = LSSetDefaultRoleHandlerForContentType(uti as CFString, LSRolesMask.all, wrapperBundleID as CFString)
if result == 0 {
    print("Neovim set as the default editor for \(uti).")
} else {
    print("Failed to set default editor. Error code: \(result)")
}

