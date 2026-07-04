//
//  AreaDownloadRowView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 20/12/2023.
//  Copyright © 2023 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct AreaDownloadRowView : View {
    var areaDownloader: AreaDownloader
    var clusterDownloader: ClusterDownloader

    var body: some View {
        Group {
            if case .downloaded = areaDownloader.status {
                downloadedRow
            } else {
                Button(action: handleTap) {
                    rowContent {
                        statusAccessory
                    }
                }
                .buttonStyle(.plain)
                .disabled(areaDownloader.isRemoving || (clusterDownloader.queueRunning && clusterDownloader.queueType != .manual))
            }
        }
    }

    private var downloadedRow: some View {
        rowContent {
            Button(role: .destructive) {
                areaDownloader.remove()
            } label: {
                Text("download.remove.action")
            }
            .buttonStyle(.borderless)
        }
    }

    private func rowContent<Accessory: View>(@ViewBuilder accessory: () -> Accessory) -> some View {
        HStack {
            Text(areaDownloader.area.name)
                .foregroundColor(.primary)

            Spacer()

            accessory()
        }
        .frame(minHeight: 24)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var statusAccessory: some View {
        if case .initial = areaDownloader.status  {
            Image(systemName: "icloud.and.arrow.down")
                .font(.body)
                .frame(width: 24, height: 24)
        }
        else if areaDownloader.isRemoving {
            Image(systemName: "icloud.and.arrow.down")
                .font(.body)
                .frame(width: 24, height: 24)
        }
        else if areaDownloader.downloadingOrQueued  {
            CircularProgressView(progress: areaDownloader.status.progress).frame(height: 18)
        }
        else {
            Text(areaDownloader.status.label)
        }
    }

    private func handleTap() {
        guard !clusterDownloader.queueRunning || clusterDownloader.queueType == .manual else { return }

        if case .initial = areaDownloader.status  {
            clusterDownloader.addAreaToQueue(areaDownloader)
        }
        else if case .queued = areaDownloader.status  {
            clusterDownloader.removeAreaFromQueue(areaDownloader)
        }
        else if case .downloading(_) = areaDownloader.status  {
            areaDownloader.cancel()
        }
    }
}

//#Preview {
//    DownloadAreaButtonView()
//}
