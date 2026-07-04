//
//  AreaView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 19/12/2022.
//  Copyright © 2022 Nicolas Mondollot. All rights reserved.
//

import SwiftUI
import CoreLocation

struct AreaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL

    let area: Area
    @Environment(AppState.self) private var appState: AppState
    let linkToMap: Bool

    @State private var problems = [Problem]()
    @State private var searchText = ""
    @State private var selectedSegment = Segment.all
    @State private var poiRoutes = [PoiRoute]()

    @State private var selectedPoi: Poi?

    private var areaDownloader: AreaDownloader {
        DownloadCenter.shared.areaDownloader(id: area.id)
    }

    var body: some View {
        List {
            if area.tags.count > 0 || area.localizedDescription != nil || area.localizedWarning != nil {
                Section {
                    tagsWithFlowLayout
                    descriptionAndWarning
                }
            }

            levelsSection

            problemsSection

            if poiRoutes.count > 0 {
                poiRoutesList
            }
        }
        .task {
            problems = area.problems
            poiRoutes = area.poiRoutes
        }
        .navigationTitle(area.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if linkToMap {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAreaOnMap()
                    } label: {
                        Image(systemName: "map")
                    }
                    .accessibilityLabel(Text("area.see_on_the_map"))
                }

                if #available(iOS 26, *) {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                AreaDownloadToolbarButton(areaDownloader: areaDownloader)
            }
        }
        .modify {
            if(linkToMap) {
                $0
            }
            else {
                if #available(iOS 26, *) {
                    $0.navigationBarItems(
                        leading: Button(role: .close) { dismiss() }
                        )
                }
                else {
                    $0.navigationBarItems(
                        leading: Button(action: {
                            dismiss()
                        }) {
                            Text("area.close")
                                .padding(.vertical)
                                .font(.body)
                        }
                    )
                }
            }
        }
        
    }

    private func showAreaOnMap() {
        appState.tab = .map

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // to avoid a weird race condition
            appState.selectedArea = area
        }
    }
    
    var tags: some View {
        ForEach(area.tags, id: \.self) { tag in
            Text(NSLocalizedString("area.tags.\(tag)", comment: ""))
                .font(.callout)
                .padding(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                .background(Color.systemBackground)
                .cornerRadius(32)
                .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color(UIColor.darkGray), lineWidth: 1.0))
        }
    }
    
    var tagsWithFlowLayout: some View {
        Group {
            if area.tags.count > 0 {
                Group {
                    FlowLayout(alignment: .leading) {
                        tags
                    }
                }
            }
        }
    }
    
    var descriptionAndWarning: some View {
        Group {
            if let description = area.localizedDescription {
                VStack(alignment: .leading) {
                    Text(description)
                }
            }

            if let warning = area.localizedWarning {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(warning).foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var levelsSection: some View {
        if area.levels.contains(where: { $0.count > 0 }) {
            Section(header: Text("area.levels")) {
                GradeDistributionView(
                    entries: area.levels.map { GradeDistributionEntry(label: $0.name, count: $0.count) },
                    showsTitle: false
                )
                .padding(.vertical, 4)
            }
        }
    }

    var problemsSection: some View {
        Section(header: Text("area.problems")) {
            Picker("Filter", selection: $selectedSegment) {
                ForEach(Segment.allCases) { segment in
                    Text(segment.title).tag(segment)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("area.problems.search_prompt", text: $searchText)
                    .autocorrectionDisabled()
            }

            ForEach(problemsFilteredBySearch) { problem in
                Button {
                    appState.tab = .map
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // to avoid a weird race condition
                        appState.selectedProblem = problem
                    }
                } label: {
                    HStack {
                        ProblemCircleView(problem: problem)
                        Text(problem.localizedName)
                        Spacer()
                        if(problem.featured) {
                            Image(systemName: "heart.fill").foregroundColor(.pink)
                        }
                        Text(problem.grade?.string ?? "")
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }

    var problemsFilteredBySearch: [Problem] {
        if searchText.count > 0 {
            return problemsFilteredByPopular.filter { ($0.name?.normalized ?? "").contains(searchText.normalized) }
        }
        else
        {
            return problemsFilteredByPopular
        }
    }

    var problemsFilteredByPopular: [Problem] {
        if selectedSegment == .popular {
            return problems.filter { $0.featured }
        }
        else {
            return problems
        }
    }

    enum Segment: Int, CaseIterable, Identifiable {
        case all
        case popular

        var id: Self { self }

        var title: String {
            switch self {
            case .all:
                return NSLocalizedString("area.problems.all", comment: "")
            case .popular:
                return NSLocalizedString("area.problems.popular", comment: "")
            }
        }
    }

    var poiRoutesList: some View {
        Section(header: Text("area.access")) {
            ForEach(poiRoutes) { poiRoute in
                if let poi = poiRoute.poi {
                    
                    Button {
                        selectedPoi = poi
                    } label: {
                        HStack {
                            if poi.type == .parking {
                                Image(systemName: "p.square.fill")
                                    .foregroundColor(Color(UIColor(red: 0.16, green: 0.37, blue: 0.66, alpha: 1.00)))
                                    .font(.title2)
                            }
                            else if poi.type == .trainStation {
                                Image(systemName: "tram.fill")
                                    .font(.body)
                            }
                            
                            Text(poi.shortName)
                            
                            Spacer()
                            
                            if poiRoute.transport == .bike {
                                Image(systemName: "bicycle")
                            }
                            else {
                                Image(systemName: "figure.walk")
                            }
                            
                            Text("\(poiRoute.distanceInMinutes) min")
                        }
                        .foregroundColor(.primary)
                    }
                    .poiActionSheet(selectedPoi: $selectedPoi)
                }
            }
        }
    }
    
}

private struct AreaDownloadToolbarButton: View {
    var areaDownloader: AreaDownloader

    @State private var showingCancelConfirmation = false
    @State private var showingRemoveConfirmation = false

    var body: some View {
        Button(action: handleTap) {
            statusIcon
                .frame(width: 24, height: 24)
        }
        .accessibilityLabel(accessibilityLabel)
        .disabled(areaDownloader.isRemoving)
        .confirmationDialog(
            Text("download.cancel.title"),
            isPresented: $showingCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("download.cancel.action", role: .destructive) {
                areaDownloader.cancel()
            }
        }
        .confirmationDialog(
            Text("download.remove.title"),
            isPresented: $showingRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("download.remove.action", role: .destructive) {
                areaDownloader.remove()
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch areaDownloader.status {
        case .initial:
            Image(systemName: "icloud.and.arrow.down")
        case .queued, .downloading(_):
            CircularProgressView(progress: areaDownloader.status.progress)
        case .downloaded:
            Image(systemName: "checkmark.icloud")
        }
    }

    private var accessibilityLabel: Text {
        switch areaDownloader.status {
        case .initial:
            Text("download.area.download")
        case .queued:
            Text("download.area.queued")
        case .downloading:
            Text(titleDownloading)
        case .downloaded:
            Text("download.area.downloaded")
        }
    }

    private var titleDownloading: String {
        let percentage = Int(Double(areaDownloader.status.progress * 100).rounded())
        return String(format: NSLocalizedString("download.area.downloading", comment: ""), percentage)
    }

    private func handleTap() {
        switch areaDownloader.status {
        case .initial:
            areaDownloader.queue()
            areaDownloader.start(onSuccess: {}, onFailure: {})
        case .queued:
            areaDownloader.cancel()
        case .downloading:
            showingCancelConfirmation = true
        case .downloaded:
            showingRemoveConfirmation = true
        }
    }
}

//struct AreaView_Previews: PreviewProvider {
//    static var previews: some View {
//        AreaView(viewModel: AreaViewModel(areaId: 1))
//    }
//}
