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
    @Environment(\.discoverRouter) private var router

    let area: Area
    @Environment(AppState.self) private var appState: AppState
    let linkToMap: Bool
    // Set when presented as a map bottom card: folds the tile-property card
    // data into the page. The page renders its own grade distribution and
    // warning from SQLite, so the header section omits those.
    var mapCard: MapFeatureCardModel? = nil

    @State private var problems = [Problem]()
    @State private var searchText = ""
    @State private var selectedSegment = Segment.all
    @State private var poiRoutes = [PoiRoute]()

    @State private var selectedPoi: Poi?

    var body: some View {
        ZStack {
            List {
                if let mapCard {
                    MapFeatureCardHeaderSection(card: mapCard, showsHistogram: false, showsWarning: false)
                }

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
                
                
                if(linkToMap) {
                    // leave room for sticky footer
                    Section(header: Text("")) {
                        EmptyView()
                    }
                    .padding(.bottom, 24)
                }
            }
            
            if(linkToMap) {
                VStack {
                    Spacer()
                    
                    Button {
                        appState.tab = .map
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // to avoid a weird race condition
                            appState.selectedArea = area
                        }
                    } label: {
                        Text("area.see_on_the_map")
                            .font(.body.weight(.semibold))
                            .modify {
                                if #available(iOS 26, *) {
                                    $0
                                }
                                else {
                                    $0.padding(.vertical)
                                }
                            }
                    }
                    .modify {
                        if #available(iOS 26, *) {
                            $0.buttonStyle(.glassProminent).controlSize(.large)
                                
                        }
                        else {
                            $0.buttonStyle(LargeButton())
                        }
                    }
                    .padding()
                }
            }

        }
        .task {
            problems = area.problems
            poiRoutes = area.poiRoutes
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            breadcrumb
        }
        .navigationTitle(area.name)
        .navigationBarTitleDisplayMode(.inline)
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
    
    @ViewBuilder
    var breadcrumb: some View {
        if let cluster = area.cluster, let region = cluster.region {
            HStack(spacing: 6) {
                breadcrumbSegment(label: region.name, route: .region(region.id)) {
                    RegionDetailView(region: region)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                breadcrumbSegment(label: cluster.name, route: .cluster(cluster.id)) {
                    ClusterDetailView(cluster: cluster)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
            .overlay(alignment: .bottom) {
                Divider()
            }
        }
    }

    @ViewBuilder
    private func breadcrumbSegment<Destination: View>(
        label: String,
        route: DiscoverRoute,
        @ViewBuilder fallback: () -> Destination
    ) -> some View {
        if let router {
            Button {
                router.navigate(to: route)
            } label: {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.appBrandColor)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(destination: fallback()) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.appBrandColor)
            }
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

//struct AreaView_Previews: PreviewProvider {
//    static var previews: some View {
//        AreaView(viewModel: AreaViewModel(areaId: 1))
//    }
//}
