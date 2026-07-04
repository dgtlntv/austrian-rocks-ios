//
//  ClusterView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 28/06/2024.
//  Copyright © 2024 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct ClusterView: View {
    var clusterDownloader: ClusterDownloader

    private let areaDownloaders: [AreaDownloader]

    init(clusterDownloader: ClusterDownloader) {
        self.clusterDownloader = clusterDownloader
        self.areaDownloaders = clusterDownloader.areas
    }

    var body: some View {
        List {
            clusterStatus
            clusterAction

            Section(header: Text("download.cluster.areas")) {
                ForEach(areaDownloaders) { areaDownloader in
                    AreaDownloadRowView(areaDownloader: areaDownloader, clusterDownloader: clusterDownloader)
                }
            }
        }
        .sensoryFeedback(.success, trigger: clusterDownloader.allDownloaded) { oldValue, newValue in
            newValue
        }
    }

    @ViewBuilder
    private var clusterStatus: some View {
        if clusterDownloader.downloadingOrQueued && clusterDownloader.queueType == .auto {
            Section {
                HStack {
                    CircularProgressView(progress: clusterDownloader.progress)
                        .frame(height: 18)
                    Text(titleDownloading)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var clusterAction: some View {
        if clusterDownloader.allDownloaded {
            Section {
                Button(role: .destructive) {
                    clusterDownloader.removeDownloads()
                } label: {
                    HStack {
                        Spacer()
                        Text("download.cluster.remove.all.action")
                        Spacer()
                    }
                }
            }
        }
        else if clusterDownloader.downloadingOrQueued && clusterDownloader.queueType == .auto {
            Section {
                Button {
                    clusterDownloader.stopDownloads()
                } label: {
                    HStack {
                        Image(systemName: "stop.circle").frame(height: 18)
                        Text("download.cancel.action")
                    }
                    .font(.title3.weight(.semibold))
                    .padding(.vertical, 12)
                }
                .buttonStyle(LargeButton())
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        else {
            Section {
                Button {
                    clusterDownloader.start()
                } label: {
                    HStack {
                        Image(systemName: "icloud.and.arrow.down").frame(height: 18)
                        Text("download.cluster.download")
                    }
                    .font(.title3.weight(.semibold))
                    .padding(.vertical, 12)
                }
                .buttonStyle(LargeButton())
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    var titleDownloading: String {
        let percentage = Int(Double(clusterDownloader.progress*100).rounded())
        return String(format: NSLocalizedString("download.cluster.downloading", comment: ""), percentage)
    }
}

//#Preview {
//    DownloadsView()
//}
