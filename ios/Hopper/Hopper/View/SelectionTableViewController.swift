//
//  SelectionTableViewController.swift
//  Coinstream
//
//  Created by Olivier van den Biggelaar on 10/08/2017.
//  Copyright © 2017 Olivier van den Biggelaar. All rights reserved.
//

import UIKit

class SelectionTableViewController: UITableViewController {
    
    // Public API
    
    var options: [Any]?
    
    var selectedOption: Any? // used as both input and output
    
    var descriptionForOption: ((Any) -> String?)?
    
    var isOptionPopular: ((Any) -> Bool)?
    
    var popularSectionTitle: String? = "Popular"
    
    var cellIdentifier: String?
    
    var unwindSegueIdentifier: String?
    
    var oneSectionPerStartingLetter = true
    
    var searchBarPlaceholder: String = "Search Table"
    
    // Private Convenience Properties
    
    private func rebuildSectionsPerIndexes() -> [(String, [Any])] {
        let options = isFiltering() ? self.filteredOptions : self.options
        let popularOptions = isFiltering() ? self.filteredPopularOptions : self.popularOptions
        
        var sectionsPerIndexes = [(String, [Any])]()
        var optionsPerSections: [String: [Any]]
        
        if self.oneSectionPerStartingLetter {
            optionsPerSections = options?.reduce(into: [String: [Any]]()) { result, option in
                if let description = self.descriptionForOption?(option)  {
                    var firstLetter = String(description[description.startIndex]).uppercased()
                    if Int(firstLetter) != nil { firstLetter = "0" }
                    result[firstLetter] = (result[firstLetter] ?? []) + [option]
                }
                } ?? ["": []]
        } else {
            optionsPerSections = ["": options ?? []]
        }
        
        sectionsPerIndexes = optionsPerSections.sorted { $0.0 < $1.0 }
        
        if let popularOptions = popularOptions, popularOptions.count > 0,
            let popularTitle = self.popularSectionTitle {
            sectionsPerIndexes.insert((popularTitle, popularOptions), at: 0)
        }
        
        return sectionsPerIndexes
    }
    
    private lazy var sectionsPerIndexes: [(String, [Any])] = {
        return rebuildSectionsPerIndexes()
    }()
    
    private lazy var popularOptions: [Any]? = {
        guard let options = self.options, let isOptionPopular = self.isOptionPopular else { return nil }
        return options.filter(isOptionPopular).sorted {
            (self.descriptionForOption?($0) ?? "").localizedCaseInsensitiveCompare((self.descriptionForOption?($1) ?? "")) == .orderedAscending
        }
    }()
    
    // TableView DataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionsPerIndexes.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionsPerIndexes[section].1.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionsPerIndexes[section].0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellIdentifier = self.cellIdentifier
            else { return super.tableView(tableView, cellForRowAt: indexPath) }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        let option = sectionsPerIndexes[indexPath.section].1[indexPath.row]
        if let optionDescription = descriptionForOption?(option) {
            cell.textLabel?.text = optionDescription
            
            if let selected = selectedOption, let selectedDescription = descriptionForOption?(selected),
                optionDescription == selectedDescription {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedOption = sectionsPerIndexes[indexPath.section].1[indexPath.row]
        
        if let unwindSegueIdentifier = self.unwindSegueIdentifier {
            if searchController.isActive {
                searchController.dismiss(animated: false, completion: { [weak self] in
                    self?.performSegue(withIdentifier: unwindSegueIdentifier, sender: self)
                })
            } else {
                performSegue(withIdentifier: unwindSegueIdentifier, sender: self)
            }
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return [""] + sectionsPerIndexes.dropFirst().map { $0.0 }
    }
    
    // MARK: - Search
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredOptions: [Any]?
    private var filteredPopularOptions: [Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = searchBarPlaceholder
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        definesPresentationContext = true
    }
    
    private func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        filteredOptions = options?.filter({( option : Any) -> Bool in
            return descriptionForOption?(option)?.lowercased().contains(searchText.lowercased()) == true
        })
        
        filteredPopularOptions = popularOptions?.filter({( option : Any) -> Bool in
            return descriptionForOption?(option)?.lowercased().contains(searchText.lowercased()) == true
        })
        
        sectionsPerIndexes = rebuildSectionsPerIndexes()
        
        tableView.reloadData()
    }
    
    private func isFiltering() -> Bool {
        return /*searchController.isActive &&*/ !searchBarIsEmpty()
    }
    
}

extension SelectionTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text ?? "")
    }
}



