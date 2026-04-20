//
//  ProblemActionButtonsView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 15/01/2026.
//  Copyright © 2026 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct ProblemActionButtonsView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(MapState.self) private var mapState: MapState
    @FetchRequest(entity: Favorite.entity(), sortDescriptors: []) var favorites: FetchedResults<Favorite>
    @FetchRequest(entity: Tick.entity(), sortDescriptors: []) var ticks: FetchedResults<Tick>

    let problem: Problem
    let withHorizontalPadding: Bool

    @State private var presentSaveActionsheet = false
    @State private var presentSharesheet = false

    init(problem: Problem, withHorizontalPadding: Bool = true) {
        self.problem = problem
        self.withHorizontalPadding = withHorizontalPadding
    }

    private var saveManager: ProblemSaveManager {
        ProblemSaveManager(
            problem: problem,
            favorites: favorites,
            ticks: ticks,
            managedObjectContext: managedObjectContext
        )
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 12) {

                if problem.variants.count > 1 {
                    Menu {
                        ForEach(problem.variants.sorted { ($0.grade ?? Grade.min) < ($1.grade ?? Grade.min) }) { variant in
                            Button {
                                mapState.selectProblem(variant)
                            } label: {
                                HStack {
                                    Text("\(variant.grade?.string ?? "") - \(variant.localizedName)")
                                    if variant.id == problem.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "arrow.trianglehead.branch")
                            Text(String(format: NSLocalizedString(problem.variants.count == 1 ? "problem.startgroup.variants.singular" : "problem.startgroup.variants.plural", comment: ""), problem.variants.count))
                                .fixedSize(horizontal: true, vertical: true)
                        }
                        .adaptivePillPadding()
                    }
                    .adaptivePillStyle()
                }

                Button(action: {
                    presentSaveActionsheet = true
                }) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: (saveManager.isFavorite() || saveManager.isTicked()) ? "bookmark.fill" : "bookmark")
                        Text((saveManager.isFavorite() || saveManager.isTicked()) ? "problem.action.saved" : "problem.action.save")
                            .fixedSize(horizontal: true, vertical: true)
                    }
                    .adaptivePillPadding()
                }
                .adaptivePillStyle()
                .actionSheet(isPresented: $presentSaveActionsheet) {
                    ActionSheet(title: Text("problem.action.save"), buttons: saveManager.saveButtons())
                }

                Button(action: {
                    presentSharesheet = true
                }) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("problem.action.share")
                    }
                    .adaptivePillPadding()
                }
                .adaptivePillStyle()
                .sheet(isPresented: $presentSharesheet,
                       content: {
                    ActivityView(activityItems: [problemURL] as [Any], applicationActivities: nil)
                })
            }
            .modify {
                if withHorizontalPadding {
                    $0
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                } else {
                    $0
                }
            }
        }
        .scrollClipDisabled()
    }

    private var problemURL: URL {
        URL(string: "https://\(BrandConfig.Domains.www)/\(NSLocale.websiteLocale)/p/\(String(problem.id))")!
    }
}

