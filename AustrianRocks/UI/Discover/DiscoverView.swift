//
//  DiscoverView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 27/10/2020.
//  Copyright © 2020 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct DiscoverView: View {
    @Environment(\.openURL) var openURL

    @State private var popularRegions: [Region] = []
    @State private var regions: [Region] = []
    @State private var router = DiscoverRouter()

    @Environment(AppState.self) private var appState: AppState

    var body: some View {
        NavigationStack(path: $router.path) {
            GeometryReader { geo in
                ScrollView {
                    if popularRegions.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            Spacer()
                        }
                        .frame(minHeight: 200)
                    }
                    else {

                        VStack(alignment: .leading) {
                            Text("discover.popular")
                                .font(.title2).bold()
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                                .padding(.horizontal)

                            VStack {
                                VStack(alignment: .leading) {

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(alignment: .top, spacing: 0) {

                                            Color.white.opacity(0)
                                                .frame(width: 0, height: 1)
                                                .padding(.leading, 8)

                                            ForEach(popularRegions) { region in
                                                NavigationLink(value: DiscoverRoute.region(region.id)) {
                                                    RegionCardView(region: region, width: abs(geo.size.width-16*2-8)/2, height: abs(geo.size.width-16*2-8)/2*9/16)
                                                        .padding(.leading, 8)
                                                        .contentShape(Rectangle())
                                                }

                                            }

                                            Color.white.opacity(0)
                                                .frame(width: 0, height: 1)
                                                .padding(.trailing, 16)
                                        }
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading) {
                            HStack {
                                Text("discover.regions.all")
                                    .font(.title2.bold())

                                Spacer()

                            }

                            .padding(.top, 24)
                            .padding(.bottom, 8)
                            .padding(.horizontal)

                            VStack {
                                Divider()

                                ForEach(regions) { region in

                                    NavigationLink(value: DiscoverRoute.region(region.id)) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(region.name)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }

                                            Spacer()

                                            Text(String(format: NSLocalizedString("discover.regions.clusters", comment: ""), region.clusters.count)).foregroundColor(Color(.systemGray))

                                            Image(systemName: "chevron.right")
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(.gray.opacity(0.7))

                                        }
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding(.horizontal)
                                        .padding(.vertical, 4)
                                    }


                                    Divider().padding(.leading)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("discover.support")
                                .font(.title2).bold()
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading) {
                                Divider()
                                
                                if let reviewURL = BrandConfig.AppStore.reviewURL {
                                    Button(action: {
                                        openURL(reviewURL)
                                    }, label: {
                                        HStack {
                                            Image(systemName: "star")
                                            Text("discover.rate")
                                            Spacer()
                                        }
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    })
                                    
                                    Divider()
                                }
                                
                                Button(action: {
                                    openURL(contributeURL)
                                }, label: {
                                    HStack {
                                        Image(systemName: "plus.app")
                                        Text("discover.contribute")
                                        Spacer()
                                    }
                                    .font(.body)
                                    .foregroundColor(.primary)
                                })
                                
                                Divider()

                                NavigationLink(value: DiscoverRoute.acknowledgements) {
                                    HStack {
                                        Image(systemName: "info.circle")
                                        Text("discover.acknowledgements")
                                        Spacer()
                                    }
                                    .font(.body)
                                    .foregroundColor(.primary)
                                }

                                Divider()
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                        
#if DEVELOPMENT
                        VStack(alignment: .leading) {
                            Text("Dev")
                                .font(.title2).bold()
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading) {
                                Divider()
                                
                                NavigationLink(value: DiscoverRoute.settings) {
                                    HStack {
                                        Image(systemName: "gearshape")
                                        Text("Settings")
                                        Spacer()
                                    }
                                    .font(.body)
                                    .foregroundColor(.primary)
                                }
                                
                                Divider()
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
#endif
                    }
                }
                .navigationBarTitle(Text("discover.title"))
                .navigationDestination(for: DiscoverRoute.self) { route in
                    destination(for: route)
                }
                .task {
                    popularRegions = Region.all.filter{$0.popular}

                    regions = Region.all.sorted{
                        $0.name.folding(options: .diacriticInsensitive, locale: .current) < $1.name.folding(options: .diacriticInsensitive, locale: .current)
                    }

                    applyPendingRoute()
                }
            }
        }
        .environment(\.discoverRouter, router)
        // Forwarded from a map feature card's "More details" button. Handled
        // both here (when DiscoverView is already alive) and in `.task`
        // (first appearance, before this observer is attached).
        .onChange(of: appState.discoverRoute) { _, _ in
            applyPendingRoute()
        }
    }

    private func applyPendingRoute() {
        guard let route = appState.discoverRoute else { return }
        router.path = [route]
        appState.discoverRoute = nil
    }

    @ViewBuilder
    private func destination(for route: DiscoverRoute) -> some View {
        switch route {
        case .region(let id):
            if let region = Region.load(id: id) {
                RegionDetailView(region: region)
            }
        case .cluster(let id):
            if let cluster = Cluster.load(id: id) {
                ClusterDetailView(cluster: cluster)
            }
        case .area(let id):
            if let area = Area.load(id: id) {
                AreaView(area: area, linkToMap: true)
            }
        case .acknowledgements:
            AcknowledgementsView()
        case .settings:
            SettingsView()
        }
    }
    
    var contributeURL: URL {
        if(NSLocale.websiteLocale == "en") {
            return URL(string: "https://\(BrandConfig.Domains.www)/en/contribute")!
        }
        return URL(string: "https://\(BrandConfig.Domains.www)/de/contribute")!
    }
}

// FIXME: there is a weird bug when using StackNavigationViewStyle() on iPhone: the sheets get dismissed automatically the first time they are presented. Sometimes but not always. It seems to happen only when I try to present the sheet a couple of seconds after the app launch, which seems to indicate that the app is not properly loaded? maybe it's still setting up the navigationview "style"?? Anywa, I figured it's easier to just avoid using StackNavigationViewStyle() for now :)
// PLOT TWIST: https://stackoverflow.com/questions/62083810/swiftui-navigation-bar-items-going-haywire-when-swipe-back-fails
extension View {
    func phoneOnlyStackNavigationView() -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return AnyView(self.navigationViewStyle(StackNavigationViewStyle()))
        } else {
            return AnyView(self)
        }
    }
}

//struct DiscoverView_Previews: PreviewProvider {
//    static var previews: some View {
//        DiscoverView()
//    }
//}
