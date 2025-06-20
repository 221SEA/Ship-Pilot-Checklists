import UIKit

class ArchivedChecklistsViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var archives: [ArchivedChecklist] = []
    private var exportButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Archived Checklists"
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light

        archives = ArchivedChecklistManager.shared.loadAll()
        setupTableView()
        setupExportButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ThemeManager.apply(to: navigationController, traitCollection: traitCollection)
        tableView.reloadData()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ArchiveCell")
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupExportButton() {
        exportButton = UIBarButtonItem(
            title: "Select",
            style: .plain,
            target: self,
            action: #selector(exportPDFButtonTapped)
        )
        exportButton.isEnabled = true
        navigationItem.rightBarButtonItem = exportButton
    }

    @objc private func exportPDFButtonTapped() {
        if tableView.isEditing {
            let sel    = tableView.indexPathsForSelectedRows ?? []
            let chosen = sel.map { archives[$0.row] }
            tableView.setEditing(false, animated: true)
            exportButton.title     = "Select"
            exportButton.isEnabled = true
            generatePDF(for: chosen)
        } else {
            tableView.setEditing(true, animated: true)
            exportButton.title     = "Export"
            exportButton.isEnabled = false
        }
    }

    private func generatePDF(for archives: [ArchivedChecklist]) {
        let pageW: CGFloat = 612, pageH: CGFloat = 792
        let margin: CGFloat = 72  // 1" margins
        let fmt = UIGraphicsPDFRendererFormat()
        let bounds = CGRect(x: 0, y: 0, width: pageW, height: pageH)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: fmt)

        // build dynamic filename
        let dfName = DateFormatter(); dfName.dateFormat = "M.d.yy"
        let dateStr = dfName.string(from: Date())
        let safeTitle: String
        if archives.count == 1 {
            switch archives[0] {
            case .builtIn(let info):
                safeTitle = info.title.replacingOccurrences(of: "/", with: ".")
            case .custom(let c):
                safeTitle = c.title.replacingOccurrences(of: "/", with: ".")
            }
        } else {
            safeTitle = "Multiple_Checklists"
        }
        let fileName = "ShipPilotChecklist_\(safeTitle)_\(dateStr).pdf"
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        func drawHeader(_ archived: ArchivedChecklist, yStart: inout CGFloat, in ctx: UIGraphicsPDFRendererContext) {
            // draw app icon from CFBundleIcons
            if let iconsDict = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String:Any],
               let primary   = iconsDict["CFBundlePrimaryIcon"] as? [String:Any],
               let files     = primary["CFBundleIconFiles"] as? [String],
               let iconName  = files.last,
               let iconImage = UIImage(named: iconName) {
                let iconSize: CGFloat = 100
                iconImage.draw(in: CGRect(x: margin, y: margin, width: iconSize, height: iconSize),
                               blendMode: .normal, alpha: 0.1)
            }

            let pilot  = UserDefaults.standard.string(forKey: "pilotName") ?? "Unknown Pilot"
            let vessel = UserDefaults.standard.string(forKey: "vesselName") ?? "Unknown Vessel"
            let date   = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
            let title: String = {
                switch archived {
                case .builtIn(let info): return info.title
                case .custom(let c):      return c.title
                }
            }()

            let titleFont = UIFont.boldSystemFont(ofSize: 18)
            let subFont   = UIFont.systemFont(ofSize: 14)
            let color     = ThemeManager.themeColor

            // start below icon
            yStart = margin + 100 + 20

            func drawLine(_ text: String, font: UIFont) {
                let attrs: [NSAttributedString.Key:Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let maxW = pageW - 2*margin
                let rect = CGRect(x: margin, y: yStart, width: maxW, height: .greatestFiniteMagnitude)
                let sz = text.boundingRect(with: rect.size,
                                           options: [.usesLineFragmentOrigin],
                                           attributes: attrs,
                                           context: nil)
                text.draw(with: rect,
                          options: [.usesLineFragmentOrigin],
                          attributes: attrs,
                          context: nil)
                yStart += sz.height + 4
            }

            drawLine(title,       font: titleFont)
            drawLine("Pilot: \(pilot)",   font: subFont)
            drawLine("Vessel: \(vessel)", font: subFont)
            drawLine("Date: \(date)",     font: subFont)
            yStart += 8
        }

        // pull saved notes, stripping out placeholder
        func notesFor(_ archived: ArchivedChecklist) -> String? {
            switch archived {
            case .builtIn(let info):
                // strip trailing " M/D/YY" if present
                let fullTitle = info.title
                let pattern = " \\d{1,2}/\\d{1,2}/\\d{2}$"
                let baseTitle: String
                if let range = fullTitle.range(of: pattern, options: .regularExpression) {
                    baseTitle = String(fullTitle[..<range.lowerBound])
                } else {
                    baseTitle = fullTitle
                }
                let key = "notes_builtin_\(baseTitle)"
                if let text = UserDefaults.standard.string(forKey: key),
                   text != "Notes..." {
                    return text
                }
                return nil

            case .custom(let c):
                let key = "notes_\(c.id.uuidString)"
                if let text = UserDefaults.standard.string(forKey: key),
                   text != "Notes..." {
                    return text
                }
                return nil
            }
        }

        do {
            try renderer.writePDF(to: tmpURL) { ctx in
                for archived in archives {
                    ctx.beginPage()
                    var y: CGFloat = 0
                    drawHeader(archived, yStart: &y, in: ctx)

                    // draw sections
                    let sections: [(String, [ChecklistItem])] = {
                        switch archived {
                        case .builtIn(let info):
                            return info.sections.map { ($0.title, $0.items) }
                        case .custom(let c):
                            return c.sections.map { ($0.title, $0.items) }
                        }
                    }()

                    let textFont = UIFont.systemFont(ofSize: 14)
                    let bullet = "• "
                    let maxW   = pageW - 2*margin

                    for (secTitle, items) in sections where !items.isEmpty {
                        // section heading
                        let secAttrs: [NSAttributedString.Key:Any] = [
                            .font: UIFont.boldSystemFont(ofSize: 16),
                            .foregroundColor: ThemeManager.themeColor
                        ]
                        let secRect = CGRect(x: margin, y: y, width: maxW, height: .greatestFiniteMagnitude)
                        let secSz   = secTitle.boundingRect(with: secRect.size,
                                                            options: [.usesLineFragmentOrigin],
                                                            attributes: secAttrs,
                                                            context: nil)
                        secTitle.draw(with: secRect,
                                      options: [.usesLineFragmentOrigin],
                                      attributes: secAttrs,
                                      context: nil)
                        y += secSz.height + 6

                        for item in items {
                            // title
                            let titleText  = bullet + item.title
                            let titleAttrs: [NSAttributedString.Key:Any] = [
                                .font: textFont,
                                .foregroundColor: ThemeManager.themeColor
                            ]
                            let titleRect = CGRect(x: margin+10, y: y,
                                                   width: maxW-10,
                                                   height: .greatestFiniteMagnitude)
                            let titleSz   = titleText.boundingRect(with: titleRect.size,
                                                                   options: [.usesLineFragmentOrigin],
                                                                   attributes: titleAttrs,
                                                                   context: nil)
                            titleText.draw(with: titleRect,
                                           options: [.usesLineFragmentOrigin],
                                           attributes: titleAttrs,
                                           context: nil)
                            y += titleSz.height + 2

                            // timestamp
                            if let ts = item.timestamp, !ts.isEmpty {
                                let tsAttrs: [NSAttributedString.Key:Any] = [
                                    .font: UIFont.italicSystemFont(ofSize: 12),
                                    .foregroundColor: ThemeManager.themeColor
                                ]
                                let tsRect = CGRect(x: margin+20, y: y,
                                                    width: maxW-20,
                                                    height: .greatestFiniteMagnitude)
                                let tsSz   = ts.boundingRect(with: tsRect.size,
                                                             options: [.usesLineFragmentOrigin],
                                                             attributes: tsAttrs,
                                                             context: nil)
                                ts.draw(with: tsRect,
                                        options: [.usesLineFragmentOrigin],
                                        attributes: tsAttrs,
                                        context: nil)
                                y += tsSz.height + 2
                            }

                            // quick note
                            if let note = item.quickNote?.trimmingCharacters(in: .whitespaces),
                               !note.isEmpty {
                                let noteAttrs: [NSAttributedString.Key:Any] = [
                                    .font: textFont,
                                    .foregroundColor: ThemeManager.themeColor
                                ]
                                let noteRect = CGRect(x: margin+20, y: y,
                                                      width: maxW-20,
                                                      height: .greatestFiniteMagnitude)
                                let noteSz   = note.boundingRect(with: noteRect.size,
                                                                  options: [.usesLineFragmentOrigin],
                                                                  attributes: noteAttrs,
                                                                  context: nil)
                                note.draw(with: noteRect,
                                          options: [.usesLineFragmentOrigin],
                                          attributes: noteAttrs,
                                          context: nil)
                                y += noteSz.height + 6
                            }

                            // photos
                            let thumb: CGFloat = 50
                            for (i, fn) in item.photoFilenames.enumerated().prefix(2) {
                                if let docs = FileManager.default
                                               .urls(for: .documentDirectory, in: .userDomainMask)
                                               .first {
                                    let url = docs.appendingPathComponent(fn)
                                    if let img = UIImage(contentsOfFile: url.path) {
                                        let x = margin + CGFloat(i) * (thumb + 8)
                                        img.draw(in: CGRect(x: x, y: y, width: thumb, height: thumb))
                                    }
                                }
                            }
                            if !item.photoFilenames.isEmpty {
                                y += thumb + 8
                            }

                            // page break
                            if y > pageH - margin - 100 {
                                ctx.beginPage()
                                y = margin
                            }
                        }
                    }

                    // Additional Notes
                    if let extra = notesFor(archived) {
                        y += 12
                        let header = "Additional Notes:"
                        let hdrAttrs: [NSAttributedString.Key:Any] = [
                            .font: UIFont.boldSystemFont(ofSize: 16),
                            .foregroundColor: ThemeManager.themeColor
                        ]
                        let hdrRect = CGRect(x: margin, y: y,
                                             width: maxW,
                                             height: .greatestFiniteMagnitude)
                        let hdrSz   = header.boundingRect(with: hdrRect.size,
                                                          options: [.usesLineFragmentOrigin],
                                                          attributes: hdrAttrs,
                                                          context: nil)
                        header.draw(with: hdrRect,
                                    options: [.usesLineFragmentOrigin],
                                    attributes: hdrAttrs,
                                    context: nil)
                        y += hdrSz.height + 4

                        let noteAttrs: [NSAttributedString.Key:Any] = [
                            .font: textFont,
                            .foregroundColor: ThemeManager.themeColor
                        ]
                        let noteRect = CGRect(x: margin, y: y,
                                              width: maxW,
                                              height: .greatestFiniteMagnitude)
                        extra.draw(with: noteRect,
                                   options: [.usesLineFragmentOrigin],
                                   attributes: noteAttrs,
                                   context: nil)
                    }
                }
            }

            let ac = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
            present(ac, animated: true)
        } catch {
            showAlert(title: "PDF Error", message: error.localizedDescription)
        }
    }

    private func showAlert(title: String, message: String?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(.init(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

extension ArchivedChecklistsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return archives.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ArchiveCell",
            for: indexPath
        )
        cell.backgroundColor    = ThemeManager.backgroundColor(for: traitCollection)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.font       = UIFont.systemFont(ofSize: 17, weight: .medium)
        cell.textLabel?.textColor  = ThemeManager.titleColor(for: traitCollection)
        cell.accessoryType         = tableView.isEditing ? .none : .disclosureIndicator

        let archived = archives[indexPath.row]
        switch archived {
        case .builtIn(let info): cell.textLabel?.text = info.title
        case .custom(let c):     cell.textLabel?.text = c.title
        }
        return cell
    }

    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath)
                   -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView,
                   shouldIndentWhileEditingRowAt indexPath: IndexPath)
                   -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            exportButton.isEnabled = (tableView.indexPathsForSelectedRows?.isEmpty == false)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            let archived = archives[indexPath.row]
            let detailVC = ChecklistViewController()
            switch archived {
            case .builtIn(let info): detailVC.checklist       = info
            case .custom(let c):      detailVC.customChecklist = c
            }
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    func tableView(_ tableView: UITableView,
                   didDeselectRowAt indexPath: IndexPath) {
        guard tableView.isEditing else { return }
        exportButton.isEnabled = (tableView.indexPathsForSelectedRows?.isEmpty == false)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
                   -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in
            let toRemove = self.archives[indexPath.row]
            ArchivedChecklistManager.shared.delete(toRemove)
            self.archives.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
