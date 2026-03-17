//
//  DownloadItem.swift
//  Reynard
//

import Foundation

enum DownloadStatus {
    case pending
    case downloading
    case completed
    case failed(Error?)
}

final class DownloadItem {
    let id: UUID
    let url: URL
    let filename: String
    let startDate: Date
    var status: DownloadStatus
    var progress: Float
    var totalBytes: Int64
    var receivedBytes: Int64
    var localFileURL: URL?

    init(url: URL, filename: String) {
        self.id = UUID()
        self.url = url
        self.filename = filename
        self.startDate = Date()
        self.status = .pending
        self.progress = 0
        self.totalBytes = 0
        self.receivedBytes = 0
    }

    var isCompleted: Bool {
        if case .completed = status { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = status { return true }
        return false
    }

    var formattedFileSize: String {
        guard totalBytes > 0 else { return "" }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
}
