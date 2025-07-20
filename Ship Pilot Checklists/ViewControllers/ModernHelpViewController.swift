import UIKit

// MARK: - Help Content Models (Keep as is - these look good)

/// Represents a help topic with title, content, and optional screenshot
struct HelpTopic {
    let id: String
    let title: String
    let content: String
    let screenshot: UIImage?
    let detailedContent: String?
    
    init(id: String, title: String, content: String, screenshot: UIImage? = nil, detailedContent: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.screenshot = screenshot
        self.detailedContent = detailedContent
    }
}

/// Represents a category of help topics
struct HelpCategory {
    let id: String
    let title: String
    let icon: String // SF Symbol name
    let topics: [HelpTopic]
    
    init(id: String, title: String, icon: String, topics: [HelpTopic]) {
        self.id = id
        self.title = title
        self.icon = icon
        self.topics = topics
    }
}

// MARK: - Text Size Preference

enum HelpTextSize: Int, CaseIterable {
    case small = 0
    case medium = 1
    case large = 2
    
    var titleFont: UIFont {
        switch self {
        case .small: return UIFont.systemFont(ofSize: 22, weight: .bold)  // Was 18
        case .medium: return UIFont.systemFont(ofSize: 26, weight: .bold) // Was 22
        case .large: return UIFont.systemFont(ofSize: 32, weight: .bold)  // Was 26, now much larger
        }
    }
    
    var contentFont: UIFont {
        switch self {
        case .small: return UIFont.systemFont(ofSize: 17)  // Was 14
        case .medium: return UIFont.systemFont(ofSize: 20) // Was 17
        case .large: return UIFont.systemFont(ofSize: 24)  // Was 20, now larger
        }
    }
    
    var buttonFont: UIFont {
        switch self {
        case .small: return UIFont.systemFont(ofSize: 16, weight: .medium)  // Was 14
        case .medium: return UIFont.systemFont(ofSize: 18, weight: .medium) // Was 16
        case .large: return UIFont.systemFont(ofSize: 22, weight: .medium)  // Was 18
        }
    }
    
    var categoryFont: UIFont {
        switch self {
        case .small: return UIFont.systemFont(ofSize: 18, weight: .semibold)  // Was 16
        case .medium: return UIFont.systemFont(ofSize: 22, weight: .semibold) // Was 18
        case .large: return UIFont.systemFont(ofSize: 28, weight: .semibold)  // Was 22, now much larger
        }
    }
    
    var categoryIconSize: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 32
        case .large: return 40
        }
    }
    
    var searchBarHeight: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 44
        case .large: return 56
        }
    }
    
    var cellPadding: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        }
    }
}

// MARK: - Modern Help View Controller

class ModernHelpViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    // MARK: - Properties
    
    private let closeButton = UIButton(type: .system)
    private let homeButton = UIButton(type: .system)
    private let sizeControl = UISegmentedControl(items: ["Small", "Medium", "Large"])
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchController = UISearchController(searchResultsController: nil)
    
    private var helpContent: [HelpCategory] = []
    private var filteredContent: [HelpTopic] = []
    private var currentCategory: HelpCategory?
    private var isSearching: Bool = false
    private var selectedTextSize: HelpTextSize = .medium {
        didSet {
            UserDefaults.standard.set(selectedTextSize.rawValue, forKey: "HelpTextSizePreference")
            updateFontsForCurrentTextSize()
            tableView.reloadData()
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load text size preference
        if let savedSize = UserDefaults.standard.object(forKey: "HelpTextSizePreference") as? Int,
           let textSize = HelpTextSize(rawValue: savedSize) {
            selectedTextSize = textSize
        }
        
        setupUI()
        loadHelpContent()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        applyTheme()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        
        // Close button (X)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let closeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: closeConfig), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Help home button (back to help categories)
        homeButton.translatesAutoresizingMaskIntoConstraints = false
        let homeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        homeButton.setImage(UIImage(systemName: "arrow.backward.circle.fill", withConfiguration: homeConfig), for: .normal)
        homeButton.addTarget(self, action: #selector(homeButtonTapped), for: .touchUpInside)
        homeButton.isHidden = true // Initially hidden until needed
        
        // Text size control
        sizeControl.translatesAutoresizingMaskIntoConstraints = false
        sizeControl.selectedSegmentIndex = selectedTextSize.rawValue
        sizeControl.addTarget(self, action: #selector(textSizeChanged(_:)), for: .valueChanged)
        
        // Search controller - Use your app's proven approach
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Help Topics"
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.showsCancelButton = false // Let the built-in search handle this
        
        // Table view - Fixed registration and setup
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HelpCategoryCell.self, forCellReuseIdentifier: "CategoryCell")
        tableView.register(HelpTopicCell.self, forCellReuseIdentifier: "TopicCell")
        tableView.register(HelpDetailCell.self, forCellReuseIdentifier: "DetailCell")
        
        // Improve table view appearance
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        // Add subviews
        view.addSubview(closeButton)
        view.addSubview(homeButton)
        view.addSubview(sizeControl)
        view.addSubview(tableView)
        
        // Fixed constraints - removed potential conflicts
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            homeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            homeButton.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 12),
            homeButton.widthAnchor.constraint(equalToConstant: 32),
            homeButton.heightAnchor.constraint(equalToConstant: 32),
            
            sizeControl.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            sizeControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sizeControl.widthAnchor.constraint(equalToConstant: 180),
            sizeControl.heightAnchor.constraint(equalToConstant: 32),
            
            tableView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Set up search bar - Use navigation item approach
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            // Fallback for older iOS versions
            setupTableViewWithSearch()
        }
        
        applyTheme()
    }
    
    private func setupTableViewWithSearch() {
        // Fallback method for older iOS - create simple header
        let searchContainer = UIView()
        searchContainer.backgroundColor = .clear
        
        let searchBarHeight: CGFloat = 56
        let containerHeight = searchBarHeight + 16
        
        searchContainer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: containerHeight)
        
        let searchBar = searchController.searchBar
        searchBar.frame = CGRect(x: 8, y: 8, width: view.bounds.width - 16, height: searchBarHeight)
        searchBar.autoresizingMask = [.flexibleWidth]
        
        searchContainer.addSubview(searchBar)
        tableView.tableHeaderView = searchContainer
    }
    
    private func applyTheme() {
        let textColor = ThemeManager.titleColor(for: traitCollection)
        
        closeButton.tintColor = textColor
        homeButton.tintColor = textColor
        sizeControl.tintColor = ThemeManager.themeColor
        
        // Apply search bar theming similar to your SearchViewController
        if traitCollection.userInterfaceStyle == .dark {
            searchController.searchBar.barStyle = .black
            searchController.searchBar.keyboardAppearance = .dark
        } else {
            searchController.searchBar.barStyle = .default
            searchController.searchBar.keyboardAppearance = .light
        }
        
        searchController.searchBar.tintColor = ThemeManager.themeColor
        
        // Style search text field
        let textField = searchController.searchBar.searchTextField
        textField.textColor = textColor
        textField.backgroundColor = UIColor.systemGray6.resolvedColor(with: traitCollection)
    }
    
    private func updateFontsForCurrentTextSize() {
        // For iOS 11+ using navigationItem.searchController, no manual setup needed
        // For older iOS, recreate the search bar header
        if #available(iOS 11.0, *) {
            // Search bar is managed by navigation item
        } else {
            setupTableViewWithSearch()
        }
        
        // Force table view to update
        tableView.reloadData()
    }
    
    private func updateHomeButtonVisibility() {
        // Show home button when we're in a category or have search results
        homeButton.isHidden = (currentCategory == nil && !isSearching)
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func homeButtonTapped() {
        // Go back to the main help categories screen
        currentCategory = nil
        isSearching = false
        searchController.searchBar.text = ""
        searchController.isActive = false
        filteredContent = []
        tableView.reloadData()
        updateHomeButtonVisibility()
    }
    
    @objc private func textSizeChanged(_ sender: UISegmentedControl) {
        if let newSize = HelpTextSize(rawValue: sender.selectedSegmentIndex) {
            selectedTextSize = newSize
        }
    }
    
    @objc private func backToCategories() {
        currentCategory = nil
        isSearching = false
        searchController.searchBar.text = ""
        searchController.isActive = false
        filteredContent = []
        tableView.reloadData()
        updateHomeButtonVisibility()
    }
    
    // MARK: - Data Loading
    
    private func loadHelpContent() {
        helpContent = HelpContent.allCategories
        tableView.reloadData()
    }
    
    // MARK: - Search - Fixed Implementation
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !searchText.isEmpty else {
            isSearching = false
            filteredContent = []
            tableView.reloadData()
            updateHomeButtonVisibility()
            return
        }
        
        isSearching = true
        
        // Search across all topics in all categories
        filteredContent = helpContent.flatMap { category in
            category.topics.filter { topic in
                return topic.title.localizedCaseInsensitiveContains(searchText) ||
                       topic.content.localizedCaseInsensitiveContains(searchText) ||
                       (topic.detailedContent?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                       category.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        tableView.reloadData()
        updateHomeButtonVisibility()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        filteredContent = []
        tableView.reloadData()
        updateHomeButtonVisibility()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Add a tap gesture to dismiss keyboard when tapping outside search bar
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // Remove tap gesture when done editing
        tableView.gestureRecognizers?.removeAll { $0 is UITapGestureRecognizer }
    }
    
    @objc private func dismissKeyboard() {
        searchController.searchBar.resignFirstResponder()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ModernHelpViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return filteredContent.isEmpty ? 1 : filteredContent.count
        } else if let category = currentCategory {
            return category.topics.count
        } else {
            return helpContent.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearching {
            if filteredContent.isEmpty {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "No matching help topics found"
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.textColor = .secondaryLabel
                cell.textLabel?.font = selectedTextSize.contentFont
                cell.selectionStyle = .none
                cell.backgroundColor = .clear
                return cell
            } else {
                let topic = filteredContent[indexPath.row]
                let cell = tableView.dequeueReusableCell(withIdentifier: "TopicCell", for: indexPath) as! HelpTopicCell
                cell.configure(with: topic, textSize: selectedTextSize)
                return cell
            }
        } else if let category = currentCategory {
            let topic = category.topics[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "TopicCell", for: indexPath) as! HelpTopicCell
            cell.configure(with: topic, textSize: selectedTextSize)
            return cell
        } else {
            let category = helpContent[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! HelpCategoryCell
            cell.configure(with: category, textSize: selectedTextSize)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isSearching && filteredContent.isEmpty {
            return 80
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if isSearching && !filteredContent.isEmpty {
            // For search results, we don't need to do anything as content is already shown
            return
        } else if currentCategory == nil && !isSearching {
            // From categories list to topics list
            currentCategory = helpContent[indexPath.row]
            tableView.reloadData()
            updateHomeButtonVisibility()
        }
        // For topic cells, we don't need selection action as content is already expanded
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = selectedTextSize.titleFont
        titleLabel.textColor = ThemeManager.titleColor(for: traitCollection)
        
        headerView.addSubview(titleLabel)
        
        if isSearching {
            titleLabel.text = "Search Results (\(filteredContent.count))"
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
                titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
                titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -20)
            ])
        } else if let category = currentCategory {
            titleLabel.text = category.title
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
                titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
                titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -20)
            ])
        } else {
            titleLabel.text = "Help Topics"
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
                titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
                titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -20)
            ])
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
}

// MARK: - Custom Cells (Fixed constraint issues)

class HelpCategoryCell: UITableViewCell {
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private var iconWidthConstraint: NSLayoutConstraint?
    private var iconHeightConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        
        iconImageView.contentMode = .scaleAspectFit
        titleLabel.numberOfLines = 0
        countLabel.textAlignment = .right
        countLabel.textColor = .secondaryLabel
        
        // Cell styling
        backgroundColor = .clear
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        selectionStyle = .none
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)
        
        // Store constraints that will change
        iconWidthConstraint = iconImageView.widthAnchor.constraint(equalToConstant: 32)
        iconHeightConstraint = iconImageView.heightAnchor.constraint(equalToConstant: 32)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconWidthConstraint!,
            iconHeightConstraint!,
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            titleLabel.trailingAnchor.constraint(equalTo: countLabel.leadingAnchor, constant: -8),
            
            countLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            countLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            countLabel.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configure(with category: HelpCategory, textSize: HelpTextSize) {
        titleLabel.text = category.title
        titleLabel.font = textSize.categoryFont
        
        countLabel.text = "\(category.topics.count)"
        countLabel.font = textSize.contentFont
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: textSize.categoryIconSize, weight: .medium)
        iconImageView.image = UIImage(systemName: category.icon, withConfiguration: iconConfig)
        iconImageView.tintColor = ThemeManager.themeColor
        
        // Update icon size constraints
        iconWidthConstraint?.constant = textSize.categoryIconSize
        iconHeightConstraint?.constant = textSize.categoryIconSize
    }
}

class HelpTopicCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let screenshotImageView = UIImageView()
    private let detailedContentLabel = UILabel()
    private var screenshotHeightConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        screenshotImageView.translatesAutoresizingMaskIntoConstraints = false
        detailedContentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.numberOfLines = 0
        
        contentLabel.font = UIFont.systemFont(ofSize: 15)
        contentLabel.numberOfLines = 0
        contentLabel.textColor = .secondaryLabel
        
        screenshotImageView.contentMode = .scaleAspectFit
        screenshotImageView.layer.cornerRadius = 8
        screenshotImageView.layer.masksToBounds = true
        screenshotImageView.backgroundColor = .secondarySystemBackground
        
        detailedContentLabel.font = UIFont.systemFont(ofSize: 15)
        detailedContentLabel.numberOfLines = 0
        detailedContentLabel.textColor = .label
        
        // Cell styling
        backgroundColor = .clear
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        selectionStyle = .none
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(screenshotImageView)
        contentView.addSubview(detailedContentLabel)
        
        screenshotHeightConstraint = screenshotImageView.heightAnchor.constraint(equalToConstant: 200)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            screenshotImageView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 12),
            screenshotImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            screenshotImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            screenshotHeightConstraint!,
            
            detailedContentLabel.topAnchor.constraint(equalTo: screenshotImageView.bottomAnchor, constant: 16),
            detailedContentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailedContentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailedContentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Add tap gesture to screenshot for full-screen viewing
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(screenshotTapped))
        screenshotImageView.isUserInteractionEnabled = true
        screenshotImageView.addGestureRecognizer(tapGesture)
    }
    
    func configure(with topic: HelpTopic, textSize: HelpTextSize) {
        titleLabel.text = topic.title
        contentLabel.text = topic.content
        
        // Update fonts based on text size
        titleLabel.font = textSize.categoryFont
        contentLabel.font = textSize.contentFont
        detailedContentLabel.font = textSize.contentFont
        
        // Configure screenshot if available
        if let screenshot = topic.screenshot {
            screenshotImageView.image = screenshot
            screenshotImageView.isHidden = false
            screenshotHeightConstraint?.constant = 200
        } else {
            screenshotImageView.isHidden = true
            screenshotHeightConstraint?.constant = 0
        }
        
        // Configure detailed content if available
        if let detailedContent = topic.detailedContent {
            detailedContentLabel.text = detailedContent
            detailedContentLabel.isHidden = false
        } else {
            detailedContentLabel.isHidden = true
        }
    }
    
    @objc private func screenshotTapped() {
        // Show full screen image viewer
        if let image = screenshotImageView.image,
           let viewController = findViewController() {
            let imageViewer = FullScreenImageViewController(image: image)
            if UIDevice.current.userInterfaceIdiom == .pad {
                imageViewer.modalPresentationStyle = .formSheet
                imageViewer.preferredContentSize = CGSize(width: 600, height: 800)
            } else {
                imageViewer.modalPresentationStyle = .fullScreen
            }
            
            viewController.present(imageViewer, animated: true)
        }
    }
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}

class HelpDetailCell: UITableViewCell {
    
    private let detailTextView = UITextView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        detailTextView.translatesAutoresizingMaskIntoConstraints = false
        detailTextView.isEditable = false
        detailTextView.isScrollEnabled = false
        detailTextView.backgroundColor = .clear
        detailTextView.textContainerInset = .zero
        detailTextView.textContainer.lineFragmentPadding = 0
        
        contentView.addSubview(detailTextView)
        
        NSLayoutConstraint.activate([
            detailTextView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            detailTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with text: String, textSize: HelpTextSize) {
        detailTextView.font = textSize.contentFont
        detailTextView.text = text
    }
}

// MARK: - Full Screen Image Viewer

class FullScreenImageViewController: UIViewController {
    
    private let imageView = UIImageView()
    private let closeButton = UIButton(type: .system)
    private let scrollView = UIScrollView()
    
    init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = image
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        view.backgroundColor = .black
        
        // Scroll view for zooming
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        // Image view
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        // Close button with better visibility
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let closeImage = UIImage(systemName: "xmark.circle.fill")
        closeButton.setImage(closeImage, for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        closeButton.layer.cornerRadius = 22
        closeButton.layer.masksToBounds = true
        closeButton.layer.borderWidth = 2
        closeButton.layer.borderColor = UIColor.white.cgColor
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Add double tap gesture for zooming
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        // Add single tap gesture for dismissal
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.require(toFail: doubleTapGesture)
        view.addGestureRecognizer(singleTapGesture)
        
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func handleSingleTap() {
        dismiss(animated: true)
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let location = gesture.location(in: imageView)
            let zoomRect = CGRect(
                x: location.x - (scrollView.frame.width / 4),
                y: location.y - (scrollView.frame.height / 4),
                width: scrollView.frame.width / 2,
                height: scrollView.frame.height / 2
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
}

extension FullScreenImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
