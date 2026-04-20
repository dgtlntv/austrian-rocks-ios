//
//  AreaView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 19/12/2022.
//  Copyright © 2022 Nicolas Mondollot. All rights reserved.
//

import SwiftUI
import Charts
import CoreLocation

struct AreaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL
    
    let area: Area
    @Environment(AppState.self) private var appState: AppState
    let linkToMap: Bool
    
    @State private var popularProblems = [Problem]()
    @State private var showChart = false
    @State private var chartData: [Level] = []
    @State private var poiRoutes = [PoiRoute]()

    @State private var selectedPoi: Poi?

    var body: some View {
        ZStack {
            List {
                // Breadcrumb navigation
                if let cluster = area.cluster, let region = cluster.region {
                    Section {
                        HStack(spacing: 4) {
                            NavigationLink(destination: RegionDetailView(region: region)) {
                                Text(region.name)
                                    .font(.caption)
                                    .foregroundColor(.appBrandColor)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(cluster.name)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(area.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if area.tags.count > 0 || area.localizedDescription != nil || area.localizedWarning != nil {
                    Section {
                        tagsWithFlowLayout
                        descriptionAndWarning
                    }
                }

                problems
                
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
            popularProblems = area.popularProblems
            
            chartData = [
                .init(name: "1", count: min(150, area.level1Count)),
                .init(name: "2", count: min(150, area.level2Count)),
                .init(name: "3", count: min(150, area.level3Count)),
                .init(name: "4", count: min(150, area.level4Count)),
                .init(name: "5", count: min(150, area.level5Count)),
                .init(name: "6", count: min(150, area.level6Count)),
                .init(name: "7", count: min(150, area.level7Count)),
                .init(name: "8", count: min(150, area.level8Count)),
            ]
            
            poiRoutes = area.poiRoutes
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
    
    var problems: some View {
        Section {
            VStack {
                Button {
                    showChart.toggle()
                } label: {
                    HStack {
                        Text("area.levels")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        AreaLevelsBarView(area: area)
                        
                        Image(systemName: showChart ? "chevron.down" : "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                            .frame(minWidth: 16)
                    }
                }

                if showChart {
                    Chart {
                        ForEach(chartData) { shape in
                            BarMark(
                                x: .value("area.chart.level", shape.name),
                                y: .value("area.chart.problems", shape.count)
                            )
                        }
                    }
                    .chartYScale(domain: 0...150)
                    .foregroundColor(.levelGreen)
                    .frame(height: 150)
                    .padding(.vertical)
                    .clipShape(Rectangle())
                }
            }
            
            NavigationLink {
                AreaProblemsView(area: area)
            } label: {
                HStack {
                    Text("area.problems")
                    Spacer()
                    Text("\(area.problemsCount)")
                }
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
    
    struct Level: Identifiable {
        var name: String
        var count: Int
        var id = UUID()
    }
}

//struct AreaView_Previews: PreviewProvider {
//    static var previews: some View {
//        AreaView(viewModel: AreaViewModel(areaId: 1))
//    }
//}
