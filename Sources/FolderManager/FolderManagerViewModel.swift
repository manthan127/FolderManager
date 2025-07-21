//
//  FolderManagerViewModel.swift
//  basicGit
//
//  Created by Home on 20/07/25.
//

import SwiftUI
import UniformTypeIdentifiers

public final class FolderManagerViewModel: ObservableObject {
    @Published public var folders: [URL] = []

    private let storageKey = "SavedFolders"

    public init() {
        loadFolders()
    }

    public func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            addFolder(url)
        }
    }

    public func addFolder(_ url: URL) {
        guard url.isFileURL, url.hasDirectoryPath else { return }
        if !folders.contains(url) {
            folders.append(url)
            saveFolders()
        }
    }

    public func removeFolder(_ url: URL) {
        folders.removeAll { $0 == url }
        saveFolders()
    }

    private func saveFolders() {
        let paths = folders.map(\.path)
        UserDefaults.standard.set(paths, forKey: storageKey)
    }

    private func loadFolders() {
        guard let paths = UserDefaults.standard.array(forKey: storageKey) as? [String] else { return }
        folders = paths.map { URL(fileURLWithPath: $0) }
    }
}
