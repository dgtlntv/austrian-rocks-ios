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
            let topoHeight = isExpanded ? geo.size.height : compactImageHeight

            ZStack(alignment: .bottom) {
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .zIndex(1)

                sheetBottomContent(problem: problem)
                    .alignmentGuide(.bottom) { dimensions in
                        isExpanded ? dimensions[.bottom] : geo.size.height - compactImageHeight
                    }
                    .animation(.snappy(duration: 0.28), value: isExpanded)
                    .zIndex(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.easeInOut(duration: 0.3), value: mapState.isInTopoMode)
        }
    }

    @ViewBuilder
    private func sheetBottomContent(problem: Problem) -> some View {
        VStack(alignment: .leading, spacing: isExpanded ? 0 : 8) {
            if mapState.isInTopoMode {
                TopoCarouselView(problem: problem, style: isExpanded ? .overlay : .inline)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                problemSummaryPanel(problem: problem)

                if !isExpanded {
                    descriptionAndVideos(for: problem)
                        .transition(.identity)
                }
            }
        }
    }

    private func problemSummaryPanel(problem: Problem) -> some View {
        VStack(alignment: .leading, spacing: isExpanded ? 12 : 0) {
            ProblemInfoView(problem: problem)
                .padding(.top, isExpanded ? 0 : 4)
                .padding(.horizontal, isExpanded ? 0 : 16)
                .foregroundStyle(.primary.opacity(isExpanded ? 0.8 : 1.0))

            ProblemActionButtonsView(problem: problem, withHorizontalPadding: !isExpanded)
        }
        .padding(isExpanded ? 16 : 0)
        .frame(maxWidth: .infinity, minHeight: isExpanded ? 150 : nil, alignment: .topLeading)
        .modify {
            if isExpanded {
                if #available(iOS 26, *) {
                    $0.background(.regularMaterial, in: Rectangle())
                }
                else {
                    $0.background(Color.systemBackground)
                }
            }
            else {
                $0
            }
        }
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
