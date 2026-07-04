//
//  AcknowledgementsView.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import SwiftUI

struct AcknowledgementsView: View {
    @State private var loadState: AcknowledgementsLoadState = .loading

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                ProgressView()
            case .loaded(let catalog):
                acknowledgementsList(catalog)
            case .failed(let message):
                AcknowledgementsFailureView(message: message)
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
                ForEach(AcknowledgementsContent.aboutParagraphKeys, id: \.self) { key in
                    Text(LocalizedStringKey(key))
                        .font(.body)
                }

                AcknowledgementsWebsiteLink()
            }

            Section {
                AcknowledgementsBasemapLink()
                AcknowledgementsCopyrightLabel()
            } header: {
                Text("acknowledgements.section.data")
            }

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
                            AcknowledgementEntryRow(entry: entry)
                        }
                    }
                } header: {
                    Text(LocalizedStringKey(section.titleKey))
                }
            }
        }
    }

    private func loadCatalogIfNeeded() {
        guard case .loading = loadState else { return }

        do {
            loadState = .loaded(try AcknowledgementCatalog.load())
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}

/// Bottom-card presentation for the map info FAB. It deliberately reuses the
/// same acknowledgement rows/detail pieces as the Discover page, but wraps them
/// in transparent custom content so the sheet behaves like the map feature and
/// problem cards rather than like a full navigation/list page.
struct AcknowledgementsCardView: View {
    let isExpanded: Bool
    let onContentHeightChange: (CGFloat) -> Void

    init(isExpanded: Bool = false, onContentHeightChange: @escaping (CGFloat) -> Void = { _ in }) {
        self.isExpanded = isExpanded
        self.onContentHeightChange = onContentHeightChange
    }

    @State private var loadState: AcknowledgementsLoadState = .loading
    @State private var selectedEntry: AcknowledgementEntry?

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let catalog):
                loadedCard(catalog)
            case .failed(let message):
                AcknowledgementsFailureView(message: message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea()
        }
        .task {
            loadCatalogIfNeeded()
        }
    }

    private func loadedCard(_ catalog: AcknowledgementCatalog) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                cardHeader

                if let selectedEntry {
                    cardDetail(for: selectedEntry)
                } else {
                    cardOverview(catalog)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .readAcknowledgementsHeight(onContentHeightChange)
        }
        .scrollDisabled(!isExpanded)
    }

    private var cardHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            if selectedEntry != nil {
                Button {
                    selectedEntry = nil
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("acknowledgements.back"))
            }

            Text("acknowledgements.title")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Spacer(minLength: 0)
        }
    }

    private func cardOverview(_ catalog: AcknowledgementCatalog) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(AcknowledgementsContent.aboutParagraphKeys, id: \.self) { key in
                    Text(LocalizedStringKey(key))
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                AcknowledgementsWebsiteLink()
            }

            AcknowledgementsCardSection(titleKey: "acknowledgements.section.data") {
                AcknowledgementsBasemapLink()
                AcknowledgementsCopyrightLabel()
            }

            AcknowledgementsCardSection {
                Text("acknowledgements.intro")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            ForEach(catalog.sections) { section in
                AcknowledgementsCardSection(titleKey: section.titleKey) {
                    ForEach(section.entries) { entry in
                        Button {
                            selectedEntry = entry
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                AcknowledgementEntryRow(entry: entry)

                                Spacer(minLength: 0)

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func cardDetail(for entry: AcknowledgementEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(entry.name)
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                AcknowledgementMetadataRow(labelKey: "acknowledgements.version", value: entry.version)
                AcknowledgementMetadataRow(labelKey: "acknowledgements.license", value: entry.licenseName)
                AcknowledgementWebsiteLink(url: entry.url, title: entry.url.absoluteString)
                AcknowledgementCopyrightText(entry: entry)
            }

            Divider()

            AcknowledgementNoticeText(entry: entry)
        }
    }

    private func loadCatalogIfNeeded() {
        guard case .loading = loadState else { return }

        do {
            loadState = .loaded(try AcknowledgementCatalog.load())
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}

private enum AcknowledgementsLoadState {
    case loading
    case loaded(AcknowledgementCatalog)
    case failed(String)
}

private enum AcknowledgementsContent {
    static let aboutParagraphKeys = [
        "acknowledgements.about.p1",
        "acknowledgements.about.p2",
        "acknowledgements.about.p3"
    ]

    static var websiteURL: URL {
        URL(string: "https://\(BrandConfig.Domains.www)")!
    }
}

private struct AcknowledgementsCardSection<Content: View>: View {
    let titleKey: String?
    private let content: Content

    init(titleKey: String? = nil, @ViewBuilder content: () -> Content) {
        self.titleKey = titleKey
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let titleKey {
                Text(LocalizedStringKey(titleKey))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }

            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct AcknowledgementEntryRow: View {
    let entry: AcknowledgementEntry

    var body: some View {
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
}

private struct AcknowledgementsWebsiteLink: View {
    var body: some View {
        AcknowledgementWebsiteLink(
            url: AcknowledgementsContent.websiteURL,
            title: BrandConfig.Domains.www
        )
    }
}

private struct AcknowledgementsBasemapLink: View {
    var body: some View {
        Link(destination: URL(string: "https://basemap.at/")!) {
            Text("Grundkarte: basemap.at")
                .font(.body)
        }
    }
}

private struct AcknowledgementsCopyrightLabel: View {
    var body: some View {
        Text("© Austrian Rocks")
            .font(.body)
    }
}

private struct AcknowledgementWebsiteLink: View {
    let url: URL
    let title: String

    var body: some View {
        Link(destination: url) {
            Label(title, systemImage: "link")
                .font(.footnote)
                .lineLimit(2)
        }
        .accessibilityLabel(Text("acknowledgements.website"))
    }
}

private struct AcknowledgementMetadataRow: View {
    let labelKey: LocalizedStringKey
    let value: String

    var body: some View {
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

private struct AcknowledgementCopyrightText: View {
    let entry: AcknowledgementEntry

    var body: some View {
        Text(entry.copyright)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
    }
}

private struct AcknowledgementNoticeText: View {
    let entry: AcknowledgementEntry

    var body: some View {
        Text(entry.notice)
            .font(.footnote.monospaced())
            .textSelection(.enabled)
    }
}

private struct AcknowledgementsFailureView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("acknowledgements.title", systemImage: "exclamationmark.triangle")
        } description: {
            Text(String(format: NSLocalizedString("acknowledgements.load_failed", comment: "Acknowledgements load failure message"), message))
        }
        .padding()
    }
}

private struct AcknowledgementDetailView: View {
    let entry: AcknowledgementEntry

    var body: some View {
        List {
            Section {
                AcknowledgementMetadataRow(labelKey: "acknowledgements.version", value: entry.version)
                AcknowledgementMetadataRow(labelKey: "acknowledgements.license", value: entry.licenseName)
                AcknowledgementWebsiteLink(url: entry.url, title: entry.url.absoluteString)
                AcknowledgementCopyrightText(entry: entry)
            }

            Section {
                AcknowledgementNoticeText(entry: entry)
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AcknowledgementsHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension View {
    func readAcknowledgementsHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: AcknowledgementsHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(AcknowledgementsHeightPreferenceKey.self, perform: onChange)
    }
}
