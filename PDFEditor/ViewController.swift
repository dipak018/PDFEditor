
import Cocoa

var selectedUrlString:URL = URL(fileURLWithPath: "")
var selectedFolderURL:URL = URL(fileURLWithPath: "")
var selectedSignatureURL:URL = URL(fileURLWithPath: "")

class ViewController: NSViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: NSTableView!
    //  @IBOutlet weak var infoTextView: NSTextView!
    @IBOutlet weak var selectSignature: NSButton!
    @IBOutlet weak var moveUpButton: NSButton!
    
    // MARK: - Properties
    
    var filesList: [URL] = []
    
    var selectedFolder: URL? {
        didSet {
            if let selectedFolder = selectedFolder {
                
                selectedFolderURL = selectedFolder
                NotificationCenter.default.post(name:Notification.Name("FolderChanged"), object: nil)
                
                filesList = contentsOf(folder: selectedFolder)
                selectedItem = nil
                self.tableView.reloadData()
                self.tableView.scrollRowToVisible(0)
                moveUpButton.isEnabled = true
                view.window?.title = selectedFolder.path
            } else {
                moveUpButton.isEnabled = false
                view.window?.title = "Add Signature to PDF"
            }
        }
    }
    
    var selectedItem: URL? {
        didSet {
            //      infoTextView.string = ""
            //      selectSignature.isEnabled = false
            
            guard let selectedUrl = selectedItem else {
                return
            }
            selectedUrlString = selectedUrl
            NotificationCenter.default.post(name:Notification.Name("PDFChanged"), object: nil)
        }
    }
    
    // MARK: - View Lifecycle & error dialog utility
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        restoreCurrentSelections()
    }
    
    override func viewWillDisappear() {
        saveCurrentSelections()
        
        super.viewWillDisappear()
    }
    
    func showErrorDialogIn(window: NSWindow, title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.beginSheetModal(for: window, completionHandler: nil)
    }
    
}

// MARK: - Getting file or folder information

extension ViewController {
    
    func contentsOf(folder: URL) -> [URL] {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
            let urls = contents.map { return folder.appendingPathComponent($0) }
            return urls
        } catch {
            return []
        }
    }
    
    func infoAbout(url: URL) -> String {
        let fileManager = FileManager.default
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            var report: [String] = ["\(url.path)", ""]
            
            for (key, value) in attributes {
                // ignore NSFileExtendedAttributes as it is a messy dictionary
                if key.rawValue == "NSFileExtendedAttributes" { continue }
                report.append("\(key.rawValue):\t \(value)")
            }
            return report.joined(separator: "\n")
        } catch {
            return "No information available for \(url.path)"
        }
    }
    
    func formatInfoText(_ text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.minimumLineHeight = 24
        paragraphStyle?.alignment = .left
        paragraphStyle?.tabStops = [ NSTextTab(type: .leftTabStopType, location: 240) ]
        
        let textAttributes: [NSAttributedStringKey: Any] = [
            NSAttributedStringKey.font: NSFont.systemFont(ofSize: 14),
            NSAttributedStringKey.paragraphStyle: paragraphStyle ?? NSParagraphStyle.default
        ]
        
        let formattedText = NSAttributedString(string: text, attributes: textAttributes)
        return formattedText
    }
    
    
}

// MARK: - Actions

extension ViewController {
    
    @IBAction func selectFolderClicked(_ sender: Any) {
        guard let window = view.window else { return }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModal(for: window) { (result) in
            if result.rawValue == NSFileHandlingPanelOKButton {
                self.selectedFolder = panel.urls[0]
            }
        }
    }
    
    
    @IBAction func tableViewDoubleClicked(_ sender: Any) {
        if tableView.selectedRow < 0 { return }
        
        let selectedItem = filesList[tableView.selectedRow]
        if selectedItem.hasDirectoryPath {
            selectedFolder = selectedItem
        }
    }
    
    @IBAction func moveUpClicked(_ sender: Any) {
        
        NotificationCenter.default.post(name:Notification.Name("Highlight"), object: nil)
        //    if selectedFolder?.path == "/" { return }
        //    selectedFolder = selectedFolder?.deletingLastPathComponent()
        
        let formUrls = self.contentsOf(folder: selectedFolderURL)
        
        let index = 0
        self.selectRow(index: index, totalRows: formUrls.count)
        
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    
    func selectRow(index:Int, totalRows:Int){
        let indexSet = IndexSet(integer: index)
        self.tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        delay(2) {
            if totalRows > index+1 {
                self.selectRow(index: index+1, totalRows: totalRows)
            }
        }
    }
    
    
    @IBAction func selectSignatureButtonAction(_ sender: Any) {
        guard let window = view.window else { return }
        
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModal(for: window) { (result) in
            if result.rawValue == NSFileHandlingPanelOKButton {
                selectedSignatureURL = panel.urls[0]
                print(selectedSignatureURL)
            }
        }
    }
    
    @IBAction func saveInfoClicked(_ sender: Any) {
        guard let window = view.window else { return }
        guard let selectedUrl = selectedItem else { return }
        
        let panel = NSSavePanel()
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        panel.nameFieldStringValue = selectedUrl
            .deletingPathExtension()
            .appendingPathExtension("fs.txt")
            .lastPathComponent
        
        panel.beginSheetModal(for: window) { (result) in
            if result.rawValue == NSFileHandlingPanelOKButton,
                let url = panel.url {
                do {
                    let infoAsText = self.infoAbout(url: selectedUrl)
                    try infoAsText.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    self.showErrorDialogIn(window: window,
                                           title: "Unable to save file",
                                           message: error.localizedDescription)
                }
            }
        }
    }
    
}

// MARK: - NSTableViewDataSource

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filesList.count
    }
    
}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor
        tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = filesList[row]
        
        let fileIcon = NSWorkspace.shared.icon(forFile: item.path)
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileCell"), owner: nil)
            as? NSTableCellView {
            cell.textField?.stringValue = item.lastPathComponent
            cell.imageView?.image = fileIcon
            return cell
        }
        
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tableView.selectedRow < 0 {
            selectedItem = nil
            return
        }
        
        selectedItem = filesList[tableView.selectedRow]
    }
    
}

// MARK: - Save & Restore previous selection

extension ViewController {
    
    func saveCurrentSelections() {
        guard let dataFileUrl = urlForDataStorage() else { return }
        
        let parentForStorage = selectedFolder?.path ?? ""
        let fileForStorage = selectedItem?.path ?? ""
        let completeData = "\(parentForStorage)\n\(fileForStorage)\n"
        
        try? completeData.write(to: dataFileUrl, atomically: true, encoding: .utf8)
    }
    
    func restoreCurrentSelections() {
        guard let dataFileUrl = urlForDataStorage() else { return }
        
        do {
            let storedData = try String(contentsOf: dataFileUrl)
            let storedDataComponents = storedData.components(separatedBy: .newlines)
            if storedDataComponents.count >= 2 {
                if !storedDataComponents[0].isEmpty {
                    selectedFolder = URL(fileURLWithPath: storedDataComponents[0])
                    if !storedDataComponents[1].isEmpty {
                        selectedItem = URL(fileURLWithPath: storedDataComponents[1])
                        selectUrlInTable(selectedItem)
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    private func selectUrlInTable(_ url: URL?) {
        guard let url = url else {
            tableView.deselectAll(nil)
            return
        }
        
        if let rowNumber = filesList.index(of: url) {
            let indexSet = IndexSet(integer: rowNumber)
            DispatchQueue.main.async {
                self.tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
                print(rowNumber)
            }
        }
    }
    
    private func urlForDataStorage() -> URL? {
        let fileManager = FileManager.default
        guard let folder = fileManager.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first else {
                                                return nil
        }
        let appFolder = folder.appendingPathComponent("PDFEditor")
        
        var isDirectory: ObjCBool = false
        let folderExists = fileManager.fileExists(atPath: appFolder.path, isDirectory: &isDirectory)
        if !folderExists || !isDirectory.boolValue {
            do {
                try fileManager.createDirectory(at: appFolder,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            } catch {
                return nil
            }
        }
        
        let dataFileUrl = appFolder.appendingPathComponent("StoredState.txt")
        return dataFileUrl
    }
    
}
