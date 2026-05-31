//
//  AcknowledgementsView.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import SwiftUI

struct AcknowledgementsView: View {
    @State private var loadState: LoadState = .loading

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                ProgressView()
            case .loaded(let catalog):
                acknowledgementsList(catalog)
            case .failed(let message):
                failureView(message: message)
            }
        }
        .navigationTitle(Text("acknowledgements.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadCatalogIfNeeded()
        }
    }

    private func acknowledgementsList(_ catalog: AcknowledgementCatalog) -> some View {
        List {
            Section {
                Text("acknowledgements.intro")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            ForEach(catalog.sections) { section in
                Section {
                    ForEach(section.entries) { entry in
                        entryView(entry)
                    }
                } header: {
                    Text(LocalizedStringKey(section.titleKey))
                }
            }
        }
        .textSelection(.enabled)
    }

    private func entryView(_ entry: AcknowledgementEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.name)
                .font(.headline)
                .textSelection(.enabled)

            metadataRow(labelKey: "acknowledgements.version", value: entry.version)
            metadataRow(labelKey: "acknowledgements.license", value: entry.licenseName)

            Link(destination: entry.url) {
                Label(entry.url.absoluteString, systemImage: "link")
                    .font(.footnote)
                    .lineLimit(2)
            }
            .accessibilityLabel(Text("acknowledgements.website"))

            Text(entry.copyright)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Text(entry.notice)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
                .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }

    private func metadataRow(labelKey: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(labelKey)
                .font(.subheadline.weight(.semibold))
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .textSelection(.enabled)
    }

    private func failureView(message: String) -> some View {
        ContentUnavailableView {
            Label("acknowledgements.title", systemImage: "exclamationmark.triangle")
        } description: {
            Text(String(format: NSLocalizedString("acknowledgements.load_failed", comment: "Acknowledgements load failure message"), message))
        }
        .padding()
    }

    private func loadCatalogIfNeeded() {
        guard case .loading = loadState else { return }

        do {
            loadState = .loaded(try AcknowledgementCatalog.load())
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    private enum LoadState {
        case loading
        case loaded(AcknowledgementCatalog)
        case failed(String)
    }
}
