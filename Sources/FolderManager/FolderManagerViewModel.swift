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

    private let storageFilename = "folderBookmarks.plist"
    private var bookmarkFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("FolderManager", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(storageFilename)
    }

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
        guard !folders.contains(url) else { return }

        do {
            let bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            folders.append(url)
            saveBookmarks()
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }

    public func removeFolder(_ url: URL) {
        folders.removeAll { $0 == url }
        saveBookmarks()
    }

    private func saveBookmarks() {
        let bookmarkDataArray: [Data] = folders.compactMap { url in
            try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        }

        do {
            let data = try PropertyListEncoder().encode(bookmarkDataArray)
            try data.write(to: bookmarkFileURL, options: .atomic)
        } catch {
            print("Failed to save bookmarks: \(error)")
        }
    }

    private func loadFolders() {
        guard let data = try? Data(contentsOf: bookmarkFileURL),
              let bookmarkDataArray = try? PropertyListDecoder().decode([Data].self, from: data) else {
            return
        }

        for bookmarkData in bookmarkDataArray {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], bookmarkDataIsStale: &isStale)
                if isStale { continue }

                folders.append(url)
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        }
    }
}
