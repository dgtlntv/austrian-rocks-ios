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
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) var openURL
    
    @AppStorage("problemDetails/viewCount") var viewCount = 0
    @AppStorage("lastVersionPromptedForReview") var lastVersionPromptedForReview = ""
    @Environment(\.requestReview) private var requestReview
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: Favorite.entity(), sortDescriptors: []) var favorites: FetchedResults<Favorite>
    @FetchRequest(entity: Tick.entity(), sortDescriptors: []) var ticks: FetchedResults<Tick>
    
    @Binding var problem: Problem
    @Environment(MapState.self) private var mapState: MapState
    
    @State private var areaResourcesDownloaded = false
    @State private var presentSaveActionsheet = false
    @State private var presentSharesheet = false
    @State private var presentTopoFullScreenView = false
    
    @State private var variants: [Problem] = []
//    @State private var startGroup: StartGroup? = nil
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        TopoView(
                            problem: $problem,
                            zoomScale: .constant(1),
                            onBackgroundTap: {
                                presentTopoFullScreenView = true
                            }
                        )
                        .fullScreenCover(isPresented: $presentTopoFullScreenView) {
                            TopoFullScreenView(problem: $problem)
                        }
                        
                        startGroupMenu
                    }
                    .frame(width: geo.size.width, height: geo.size.width * 3/4)
                    .zIndex(10)
                    
                    infos

                    descriptionAndVideos

                    actionButtons
                }
            }
            
            Spacer()
        }
        .onAppear {
            computeStartGroup()
        }
        .onChange(of: problem) {
            computeStartGroup()
        }
        .onAppear {
            viewCount += 1
        }
        // Inspired by https://developer.apple.com/documentation/storekit/requesting-app-store-reviews
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
    
    var startGroupMenu: some View {
        VStack {
            HStack {
                Spacer()
                
//                if let startGroup = startGroup {
                    
                    if(variants.count > 1) {
                        Menu {
                            ForEach(variants) { p in
                                Button {
                                    mapState.selectProblem(p)
                                } label: {
                                    Text("\(p.localizedName) \(p.grade?.string ?? "")")
                                }
                            }
                        } label: {
                            HStack {
//                                Text(paginationText)
                                Text(String(format: NSLocalizedString("problem.variants", comment: ""), variants.count))
                                Image(systemName: "chevron.down")
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.gray.opacity(0.8))
                            .foregroundColor(Color(UIColor.systemBackground))
                            .cornerRadius(16)
                            .padding(8)
                        }
                    }
//                }
            }
            
            Spacer()
        }
    }
    
//    private var paginationText: String {
//        let index = startGroup?.sortedProblems.firstIndex(of: problem) ?? 0
//        let count = startGroup?.sortedProblems.count ?? 0
//        return String(format: NSLocalizedString("problem.pagination", comment: ""), index+1, count)
//    }
    
    private var paginationText: String {
        let index = variants.firstIndex(of: problem) ?? 0
        let count = variants.count
        return String(format: NSLocalizedString("problem.pagination", comment: ""), index+1, count)
    }
    
    private func computeStartGroup() {
        variants = problem.variants
//        startGroup = problem.startGroup
    }

    
    var infos: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(problem.localizedName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.5)
                        
                        Spacer()

                        if let grade = problem.grade {
                            Text(grade.string)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.top, 4)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    
                    if(problem.sitStart) {
                        Image(systemName: "figure.rower")
                        Text("problem.sit_start")
                            .font(.body)
                    }
                    
                    if problem.steepness != .other {
                        if problem.sitStart {
                            Text("•")
                                .font(.body)
                        }
                        
                        HStack(alignment: .firstTextBaseline) {
                            Image(problem.steepness.imageName)
                                .frame(minWidth: 16)
                            Text(problem.steepness.localizedName)
                            
                        }
                        .font(.body)
                    }
                    
                    Spacer()
                    
                    if isTicked() {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.appBrandColor)
                    }
                    else if isFavorite() {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color.yellow)
                    }
                }
            }
        }
        .padding(.top, 0)
        .padding(.horizontal)
        //        .layoutPriority(1) // without this the imageview prevents the title from going multiline

    }

    var descriptionAndVideos: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Problem Description
            if let description = problem.problemDescription, !description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal)
            }

            // Video Links
            if let videoLinks = problem.videoLinks, !videoLinks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Videos")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(videoLinks, id: \.self) { link in
                        if let url = URL(string: link) {
                            Button(action: {
                                openURL(url)
                            }) {
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

    var actionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 16) {

                Button(action: {
                    presentSaveActionsheet = true
                }) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: (isFavorite() || isTicked()) ? "bookmark.fill" : "bookmark")
                        Text((isFavorite() || isTicked()) ? "problem.action.saved" : "problem.action.save")
                            .fixedSize(horizontal: true, vertical: true)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(Pill())
                .actionSheet(isPresented: $presentSaveActionsheet) {
                    ActionSheet(title: Text("problem.action.save"), buttons: saveButtons)
                }
                
                Button(action: {
                    presentSharesheet = true
                }) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
//                        Text("problem.action.share").fixedSize(horizontal: true, vertical: true)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(Pill())
                .sheet(isPresented: $presentSharesheet,
                       content: {
                    ActivityView(activityItems: [problemURL] as [Any], applicationActivities: nil) }
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
    
    var saveButtons: [ActionSheet.Button] {
        var buttons = [ActionSheet.Button]()
        
        if(!isTicked()) {
            buttons.append(
                .default(Text(isFavorite() ? "problem.action.favorite.remove" : "problem.action.favorite.add")) {
                    toggleFavorite()
                }
            )
        }
        
        buttons.append(
            .default(Text(isTicked() ? "problem.action.untick" : "problem.action.tick")) {
                toggleTick()
            }
        )
        
        buttons.append(.cancel())
        
        return buttons
    }
    
    var problemURL: URL {
        URL(string: "https://\(BrandConfig.Domains.www)/\(NSLocale.websiteLocale)/p/\(String(problem.id))")!
    }
    
    private func presentReview() {
        Task {
            // Delay for two seconds to avoid interrupting the person using the app.
            try await Task.sleep(for: .seconds(2))
            requestReview()
        }
    }
    
    // MARK: Ticks and favorites
    
    func isFavorite() -> Bool {
        favorite() != nil
    }
    
    func favorite() -> Favorite? {
        favorites.first { (favorite: Favorite) -> Bool in
            return Int(favorite.problemId) == problem.id
        }
    }
    
    func toggleFavorite() {
        if isFavorite() {
            deleteFavorite()
        }
        else {
            createFavorite()
        }
    }
    
    func createFavorite() {
        let favorite = Favorite(context: managedObjectContext)
        favorite.id = UUID()
        favorite.problemId = Int64(problem.id)
        favorite.createdAt = Date()
        
        do {
            try managedObjectContext.save()
        } catch {
            // handle the Core Data error
        }
    }
    
    func deleteFavorite() {
        guard let favorite = favorite() else { return }
        managedObjectContext.delete(favorite)
        
        do {
            try managedObjectContext.save()
        } catch {
            // handle the Core Data error
        }
    }
    
    func isTicked() -> Bool {
        tick() != nil
    }
    
    func tick() -> Tick? {
        ticks.first { (tick: Tick) -> Bool in
            return Int(tick.problemId) == problem.id
        }
    }
    
    func toggleTick() {
        if isTicked() {
            deleteTick()
        }
        else {
            createTick()
        }
    }
    
    func createTick() {
        let tick = Tick(context: managedObjectContext)
        tick.id = UUID()
        tick.problemId = Int64(problem.id)
        tick.createdAt = Date()
        
        do {
            try managedObjectContext.save()
        } catch {
            // handle the Core Data error
        }
    }
    
    func deleteTick() {
        guard let tick = tick() else { return }
        managedObjectContext.delete(tick)
        
        do {
            try managedObjectContext.save()
        } catch {
            // handle the Core Data error
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

