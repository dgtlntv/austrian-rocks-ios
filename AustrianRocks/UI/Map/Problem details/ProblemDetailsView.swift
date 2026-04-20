//
//  ProblemDetailsView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 25/04/2020.
//  Copyright © 2020 Nicolas Mondollot. All rights reserved.
//

import SwiftUI
import StoreKit
import MapKit

struct ProblemDetailsView: View {
    @AppStorage("problemDetails/viewCount") var viewCount = 0
    @AppStorage("lastVersionPromptedForReview") var lastVersionPromptedForReview = ""
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    @Environment(MapState.self) private var mapState: MapState
    
    @State private var presentTopoFullScreenView = false
    
    @Namespace private var topoTransitionNamespace
    
    var body: some View {
        if let problem = mapState.selectedProblem {
            VStack {
                GeometryReader { geo in
                    VStack(alignment: .leading, spacing: 8) {
                        TopoSwipeContentView(problem: problem, zoomable: false)
                        .frame(width: geo.size.width, height: geo.size.width * 3/4)
                        .zIndex(10)
                        .modify {
                            if #available(iOS 18, *) {
                                $0.matchedTransitionSource(id: "topo-\(problem.topoId ?? 0)", in: topoTransitionNamespace)
                            }
                            else {
                                $0
                            }
                        }
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    if value > 1.1 {
                                        presentTopoFullScreenView = true
                                    }
                                }
                        )
                        .fullScreenCover(isPresented: $presentTopoFullScreenView) {
                            TopoFullScreenView()
                                .modify {
                                    if #available(iOS 18, *) {
                                        $0.navigationTransition(.zoom(sourceID: "topo-\(problem.topoId ?? 0)", in: topoTransitionNamespace))
                                    }
                                    else {
                                        $0
                                    }
                                }
                        }
                        
                        if mapState.isInTopoMode {
                            TopoCarouselView(problem: problem, style: .inline)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            VStack(alignment: .leading) {
                                ProblemInfoView(problem: problem)
                                    .padding(.top, 4)
                                    .padding(.horizontal)

                                descriptionAndVideos(for: problem)

                                ProblemActionButtonsView(problem: problem)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: mapState.isInTopoMode)
                }
                
                Spacer()
            }
            .onAppear {
                viewCount += 1
            }
            .onChange(of: mapState.presentTopoFullScreenRequestCount) { _, _ in
                presentTopoFullScreenView = true
            }
            .onChange(of: viewCount) {
                guard let currentAppVersion = Bundle.currentAppVersion else {
                    return
                }

                if viewCount >= 100, currentAppVersion != lastVersionPromptedForReview {
                    presentReview()
                    lastVersionPromptedForReview = currentAppVersion
                }
            }
        }
    }

    @ViewBuilder
    private func descriptionAndVideos(for problem: Problem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let description = problem.problemDescription, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
            }

            if let videoLinks = problem.videoLinks, !videoLinks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Videos")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(videoLinks, id: \.self) { link in
                        if let url = URL(string: link) {
                            Button {
                                openURL(url)
                            } label: {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(.appBrandColor)
                                    Text("Watch video")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.forward")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func presentReview() {
        Task {
            try await Task.sleep(for: .seconds(2))
            requestReview()
        }
    }
}

//struct ProblemDetailsView_Previews: PreviewProvider {
//    static let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//
//    static var previews: some View {
//        ProblemDetailsView(problem: .constant(dataStore.problems.first!))
//            .environment(\.managedObjectContext, context)
//    }
//}
