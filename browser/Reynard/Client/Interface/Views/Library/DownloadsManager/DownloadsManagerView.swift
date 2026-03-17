//
//  DownloadsManagerView.swift
//  Reynard
//
//  Created by Minh Ton on 9/3/26.
//

import UIKit

final class DownloadsManagerView: UIView, UITableViewDataSource, UITableViewDelegate {
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(DownloadCell.self, forCellReuseIdentifier: DownloadCell.reuseIdentifier)
        table.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        return table
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No Downloads"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private var items: [DownloadItem] { DownloadManager.shared.items }

    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.delegate = self
        addSubview(tableView)
        addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        NotificationCenter.default.addObserver(
            self, selector: #selector(downloadsDidUpdate),
            name: DownloadManager.didUpdateNotification, object: nil
        )

        updateEmptyState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func downloadsDidUpdate() {
        tableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !items.isEmpty
        tableView.isHidden = items.isEmpty
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DownloadCell.reuseIdentifier, for: indexPath) as! DownloadCell
        cell.configure(with: items[indexPath.row])
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        guard item.isCompleted, let localURL = item.localFileURL else { return }

        let controller = UIDocumentInteractionController(url: localURL)
        controller.presentPreview(animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            let item = self.items[indexPath.row]
            DownloadManager.shared.removeItem(item)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        64
    }
}

private final class DownloadCell: UITableViewCell {
    static let reuseIdentifier = "DownloadCell"

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()

    private let filenameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()

    private let progressBar: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(iconView)
        contentView.addSubview(filenameLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(progressBar)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            filenameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            filenameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            filenameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            detailLabel.leadingAnchor.constraint(equalTo: filenameLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: filenameLabel.trailingAnchor),
            detailLabel.topAnchor.constraint(equalTo: filenameLabel.bottomAnchor, constant: 2),

            progressBar.leadingAnchor.constraint(equalTo: filenameLabel.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: filenameLabel.trailingAnchor),
            progressBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: DownloadItem) {
        filenameLabel.text = item.filename

        switch item.status {
        case .pending:
            iconView.image = UIImage(systemName: "arrow.down.circle")
            detailLabel.text = "Waiting..."
            progressBar.isHidden = true
        case .downloading:
            iconView.image = UIImage(systemName: "arrow.down.circle")
            let sizeText = item.totalBytes > 0
                ? "\(ByteCountFormatter.string(fromByteCount: item.receivedBytes, countStyle: .file)) of \(item.formattedFileSize)"
                : "\(ByteCountFormatter.string(fromByteCount: item.receivedBytes, countStyle: .file))"
            detailLabel.text = sizeText
            progressBar.isHidden = false
            progressBar.progress = item.progress
        case .completed:
            iconView.image = UIImage(systemName: "checkmark.circle.fill")
            iconView.tintColor = .systemGreen
            detailLabel.text = [item.formattedFileSize, item.formattedDate].filter { !$0.isEmpty }.joined(separator: " — ")
            progressBar.isHidden = true
        case .failed:
            iconView.image = UIImage(systemName: "exclamationmark.circle.fill")
            iconView.tintColor = .systemRed
            detailLabel.text = "Download failed"
            progressBar.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.tintColor = .systemBlue
        progressBar.isHidden = true
        progressBar.progress = 0
    }
}
