//
//  DownloadManager.swift
//  Reynard
//

import Foundation
import UIKit

final class DownloadManager: NSObject {
    static let shared = DownloadManager()
    static let didUpdateNotification = Notification.Name("DownloadManagerDidUpdate")

    private(set) var items: [DownloadItem] = []
    private var activeTasks: [URLSessionDownloadTask: DownloadItem] = [:]

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    private override init() {
        super.init()
    }

    private static let downloadsDirectory: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsPath = documentsPath.appendingPathComponent("Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: downloadsPath, withIntermediateDirectories: true)
        return downloadsPath
    }()

    @discardableResult
    func download(url: URL, suggestedFilename: String? = nil) -> DownloadItem {
        let filename = suggestedFilename ?? url.lastPathComponent.removingPercentEncoding ?? "download"
        let item = DownloadItem(url: url, filename: uniqueFilename(for: filename))

        items.insert(item, at: 0)
        item.status = .downloading

        let task = session.downloadTask(with: url)
        activeTasks[task] = item
        task.resume()

        postUpdate()
        return item
    }

    func removeItem(_ item: DownloadItem) {
        if let localURL = item.localFileURL {
            try? FileManager.default.removeItem(at: localURL)
        }
        items.removeAll { $0.id == item.id }
        postUpdate()
    }

    func clearCompleted() {
        items.removeAll { item in
            if item.isCompleted || item.isFailed {
                if let localURL = item.localFileURL {
                    try? FileManager.default.removeItem(at: localURL)
                }
                return true
            }
            return false
        }
        postUpdate()
    }

    private func uniqueFilename(for filename: String) -> String {
        let targetURL = Self.downloadsDirectory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: targetURL.path) else {
            return filename
        }

        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        var counter = 1

        while true {
            let candidate = ext.isEmpty ? "\(name) (\(counter))" : "\(name) (\(counter)).\(ext)"
            let candidateURL = Self.downloadsDirectory.appendingPathComponent(candidate)
            if !FileManager.default.fileExists(atPath: candidateURL.path) {
                return candidate
            }
            counter += 1
        }
    }

    private func postUpdate() {
        NotificationCenter.default.post(name: Self.didUpdateNotification, object: self)
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let item = activeTasks.removeValue(forKey: downloadTask) else { return }

        let destinationURL = Self.downloadsDirectory.appendingPathComponent(item.filename)
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            item.localFileURL = destinationURL
            item.status = .completed
            item.progress = 1.0
        } catch {
            item.status = .failed(error)
        }

        postUpdate()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let item = activeTasks[downloadTask] else { return }

        item.receivedBytes = totalBytesWritten
        if totalBytesExpectedToWrite > 0 {
            item.totalBytes = totalBytesExpectedToWrite
            item.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        }

        postUpdate()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask,
              let item = activeTasks.removeValue(forKey: downloadTask) else { return }

        if let error, !item.isCompleted {
            item.status = .failed(error)
            postUpdate()
        }
    }
}
