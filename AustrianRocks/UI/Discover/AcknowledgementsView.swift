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
            aboutSection

            dataAttributionSection

            Section {
                Text("acknowledgements.intro")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            ForEach(catalog.sections) { section in
                Section {
                    ForEach(section.entries) { entry in
                        NavigationLink {
                            AcknowledgementDetailView(entry: entry)
                        } label: {
                            entryRow(entry)
                        }
                    }
                } header: {
                    Text(LocalizedStringKey(section.titleKey))
                }
            }
        }
    }

    // About copy sourced from the Rails project description (about page).
    private var aboutSection: some View {
        Section {
            Text("acknowledgements.about.p1")
                .font(.body)
            Text("acknowledgements.about.p2")
                .font(.body)
            Text("acknowledgements.about.p3")
                .font(.body)

            Link(destination: URL(string: "https://\(BrandConfig.Domains.www)")!) {
                Label(BrandConfig.Domains.www, systemImage: "link")
                    .font(.footnote)
            }
            .accessibilityLabel(Text("acknowledgements.website"))
        } header: {
            Text("acknowledgements.about.title")
        }
    }

    // Matches the shared map style's source attributions; the map's info FAB
    // is the attribution entry point, so this section must stay reachable.
    private var dataAttributionSection: some View {
        Section {
            Link(destination: URL(string: "https://basemap.at/")!) {
                Label("Grundkarte: basemap.at", systemImage: "map")
                    .font(.body)
            }

            Label("© Austrian Rocks", systemImage: "mountain.2")
                .font(.body)
        } header: {
            Text("acknowledgements.section.data")
        }
    }

    private func entryRow(_ entry: AcknowledgementEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.name)
                .font(.headline)

            Text(entry.licenseName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(entry.version)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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

private struct AcknowledgementDetailView: View {
    let entry: AcknowledgementEntry

    var body: some View {
        List {
            Section {
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
            }

            Section {
                Text(entry.notice)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
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
}
