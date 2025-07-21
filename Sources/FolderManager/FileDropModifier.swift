//
//  FileDropModifier.swift
//  ReduceProjectSize
//
//  Created by Home on 27/02/25.
//

import SwiftUI
import UniformTypeIdentifiers

public typealias URLsCompletion = (_ urls: [URL])-> Void

public extension View {
    func onFileDrop(
        disabled: Bool = false,
        allowedFormats: [UTType] = [UTType.directory],
        filter: ((URL) -> Bool)? = nil,
        onURLsFetched: @escaping URLsCompletion
    ) -> some View {
        self.modifier(
            FileDropModifier(
                disable: disabled,
                allowedFormats: allowedFormats,
                filter: filter,
                filesURLFetched: onURLsFetched
            )
        )
    }
}

/// need to make this struct more flexible for general use case

public struct FileDropModifier: ViewModifier {
    public var disable: Bool = false
    public var allowedFormats: [UTType] = [UTType.directory]
    public var filter: ((URL) -> Bool)? = nil
    public var filesURLFetched: URLsCompletion
    
    public func body(content: Content) -> some View {
        content
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil, perform: filesDropAction)
    }

    private func filesDropAction(_ providers: [NSItemProvider]) -> Bool {
        guard !disable else { return false }

        var urls: [URL] = []
        let dispatchGroup = DispatchGroup()
        // TODO: -  handle errors or failurs
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                dispatchGroup.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    defer { dispatchGroup.leave() }

                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil),
                          self.allowedFormats.isEmpty || url.conformsAny(self.allowedFormats),
                          filter?(url) ?? true
                    else { return }

                    urls.append(url)
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            filesURLFetched(urls)
        }

        return true
    }
}

extension URL {
    var fileType: UTType? {
        try? self.resourceValues(forKeys: [.contentTypeKey]).contentType
    }
    
    func conformsAny(_ types: [UTType])-> Bool {
        fileType.map { fileType in
            types.contains(where: { fileType.conforms(to: $0) })
        } ?? false
    }
}
