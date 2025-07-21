//
//  FolderManagerView.swift
//  basicGit
//
//  Created by Home on 20/07/25.
//

import SwiftUI
import UniformTypeIdentifiers

public struct FolderManagerView<Destination: View>: View {
    @StateObject private var viewModel = FolderManagerViewModel()
    let destinationBuilder: (URL) -> Destination
    let filter: ((URL) -> Bool)?
    @State private var url: URL?
    
    public init(filter: ((URL) -> Bool)? = nil, destination: @escaping (URL) -> Destination) {
        self.destinationBuilder = destination
        self.filter = filter
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button("Choose Folder") {
                    viewModel.pickFolder()
                }

                Spacer()
            }
            
            List(viewModel.folders, id: \.self) { folder in
                NavigationLink(value: folder) {
                    HStack {
                        Text(folder.path)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.removeFolder(folder)
                        }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
            .onFileDrop(allowedFormats: [UTType.directory], filter: filter) { urls in
                for url in urls {
                    viewModel.addFolder(url)
                }
            }

            Text("Drag and drop folders here or use the button above.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 5)
        }
        .padding()
        .navigationDestination(for: URL.self, destination: { url in
            destinationBuilder(url)
        })
        .frame(minWidth: 400, minHeight: 300)
    }
}
