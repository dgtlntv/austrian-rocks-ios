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

    let isExpanded: Bool

    init(isExpanded: Bool = false) {
        self.isExpanded = isExpanded
    }
    
    @State private var presentTopoFullScreenView = false
    
    @Namespace private var topoTransitionNamespace
    
    var body: some View {
        if let problem = mapState.selectedProblem {
            persistentTopoLayout(for: problem)
                .clipped()
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

    private func persistentTopoLayout(for problem: Problem) -> some View {
        GeometryReader { geo in
            let compactImageHeight = geo.size.width * 3 / 4
            let detailsHeight = detailsRegionHeight(sheetHeight: geo.size.height, compactImageHeight: compactImageHeight)
            let topoHeight = isExpanded
                ? max(compactImageHeight, geo.size.height - detailsHeight)
                : compactImageHeight

            VStack(alignment: .leading, spacing: 0) {
                TopoSwipeContentView(problem: problem, zoomable: isExpanded)
                    .frame(width: geo.size.width, height: topoHeight)
                    .background(Color.systemBackground)
                    .clipped()
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
                                if !isExpanded && value > 1.1 {
                                    presentTopoFullScreenView = true
                                }
                            },
                        including: isExpanded ? .subviews : .all
                    )

                sheetBottomContent(problem: problem, detailsHeight: max(0, geo.size.height - topoHeight))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.easeInOut(duration: 0.3), value: mapState.isInTopoMode)
        }
    }

    @ViewBuilder
    private func sheetBottomContent(problem: Problem, detailsHeight: CGFloat) -> some View {
        if mapState.isInTopoMode {
            TopoCarouselView(problem: problem, style: .inline)
                .frame(height: detailsHeight, alignment: .top)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 8) {
                    problemSummaryPanel(problem: problem)
                    descriptionAndVideos(for: problem)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.bottom, isExpanded ? 16 : 0)
            }
            .frame(height: detailsHeight, alignment: .top)
            .scrollIndicators(.visible)
        }
    }

    private func problemSummaryPanel(problem: Problem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ProblemInfoView(problem: problem)
                .padding(.top, 4)
                .padding(.horizontal)

            ProblemActionButtonsView(problem: problem)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func descriptionAndVideos(for problem: Problem) -> some View {
        let hasDescription = problem.problemDescription?.isEmpty == false
        let videoLinks = problem.videoLinks ?? []

        if hasDescription || !videoLinks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                if let description = problem.problemDescription, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                }

                if !videoLinks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("problem.videos.title")
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
                                        Text("problem.videos.watch")
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
    }

    private func detailsRegionHeight(sheetHeight: CGFloat, compactImageHeight: CGFloat) -> CGFloat {
        if !isExpanded {
            return max(0, sheetHeight - compactImageHeight)
        }

        let maxDetailsHeight = max(0, sheetHeight - compactImageHeight)
        let preferredDetailsHeight: CGFloat

        if mapState.isInTopoMode {
            preferredDetailsHeight = min(max(sheetHeight * 0.14, 88), 120)
        } else {
            preferredDetailsHeight = min(max(sheetHeight * 0.32, 220), 320)
        }

        return min(maxDetailsHeight, preferredDetailsHeight)
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
