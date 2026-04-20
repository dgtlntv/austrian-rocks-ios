//
//  AreaToolbarView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 19/12/2022.
//  Copyright © 2022 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct AreaToolbarView: View {
    @Environment(MapState.self) private var mapState: MapState
    
    @State private var presentAllFilters = false
    
    var body: some View {
        @Bindable var mapState = mapState

        return VStack {
            HStack(spacing: 12) {
                Button {
                    mapState.presentProblemDetails = false
                    mapState.presentSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .adaptiveCircleButtonIcon()
                        .frame(minWidth: 32, minHeight: 32)
                }
                .adaptiveCircleButtonStyle()
                
                Button {
                    if(mapState.presentProblemDetails) {
                        mapState.presentProblemDetails = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // to avoid a weird race condition
                            mapState.presentAreaView = true
                        }
                    }
                    else {
                        mapState.presentAreaView = true
                    }
                } label: {
                    HStack {
                        Text(mapState.selectedArea?.name ?? "")
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.head)
                        
                        if let area = mapState.selectedArea {
                            if let _ = area.warningDe, let _ = area.warningEn {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                            }
                            
                            Image(systemName: "info.circle")
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                }
                .modify {
                    if #available(iOS 26, *) {
                        $0.glassEffect()
                    }
                    else {
                        $0
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color(.secondaryLabel).opacity(0.5), radius: 5)
                    }
                }
                .sheet(isPresented: $mapState.presentAreaView) {
                    NavigationView {
                        AreaView(area: mapState.selectedArea!, linkToMap: false)
                    }
                }
                
                Button {
                    mapState.presentProblemDetails = false
                    presentAllFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .adaptiveCircleButtonIcon()
                        .frame(minWidth: 32, minHeight: 32)
                }
                .modify {
                    if #available(iOS 26, *) {
                        if filtersActive {
                            $0.buttonStyle(.glassProminent)
                                .buttonBorderShape(.circle)
                        } else {
                            $0.buttonStyle(.glass)
                                .buttonBorderShape(.circle)
                        }
                    } else {
                        $0
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: Color(.secondaryLabel).opacity(0.5), radius: 5)
                    }
                }
                .sheet(isPresented: $presentAllFilters, onDismiss: {
                    mapState.filtersRefresh()
                }) {
                    AllFiltersView()
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.hidden)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    var filtersActive: Bool {
        mapState.filters.filtersCount > 0
    }
}
