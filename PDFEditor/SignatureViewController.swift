//
//  ViewController.swift
//  SamplePDFEditor
//
//  Created by Chaudhari, Dipak Bharat (external - Project) on 14/09/20.
//  Copyright © 2020 Chaudhari, Dipak Bharat (external - Project). All rights reserved.
//

import Cocoa
import PDFKit

class SignatureViewController: NSViewController {
    
    @IBOutlet var pdfView:PDFView!
    
    var pdfDocument = PDFDocument(url: Bundle.main.url(forResource: "FORM16_16_BHAGWAN S.PAWAR (1269)_2019-20", withExtension: "pdf")!)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pdfView.document = pdfDocument
        
        pdfView.autoScales = true
        pdfDocument.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(PDFChanged), name: Notification.Name("PDFChanged"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(FolderChanged), name: Notification.Name("FolderChanged"), object: nil)
        
    }
    
    @objc func PDFChanged() {
        
        self.pdfDocument = PDFDocument(url: selectedUrlString) ?? PDFDocument(url: Bundle.main.url(forResource: "FORM16_16_BHAGWAN S.PAWAR (1269)_2019-20", withExtension: "pdf")!)!
           pdfView.document = self.pdfDocument
            self.pdfDocument.delegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.search()
        }
    }
    
    @objc func FolderChanged() {

        let formUrls = self.contentsOf(folder: selectedFolderURL)

        for urlPath in formUrls {
            
                selectedUrlString = urlPath
                self.pdfDocument = PDFDocument(url: urlPath) ?? PDFDocument(url: Bundle.main.url(forResource: "FORM16_16_BHAGWAN S.PAWAR (1269)_2019-20", withExtension: "pdf")!)!
                self.pdfView.document = self.pdfDocument
                    self.pdfDocument.delegate = self
                print(self.pdfDocument.documentURL)
                self.delay(1) {
                    self.search()
                }
//                self.makeFakeNetworkRequest(completion: {
//                    // request complete
//                })

        }
    }
    
    func makeFakeNetworkRequest(completion:()->()) {
        let interval = TimeInterval(exactly: 4)!
        print("Sleeping for: \(interval)")
        Thread.sleep(forTimeInterval: interval)
        print("Awoken after: \(interval)")
        completion()
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
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
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
//        self.search()
    }
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func search() {
        pdfDocument.beginFindString("person responsible for d", withOptions: [NSString.CompareOptions.caseInsensitive])
    }
    
    func stopSearch() {
        pdfView.highlightedSelections = nil
    }
    
    var searchItems = [PDFSelection]()
        
    func getSignatureAnnotation() -> SignaturePDFAnnotation {
        
        let annotation = SignaturePDFAnnotation(NSImage(named: NSImage.Name(rawValue: "THANEKAR copy.png")), bounds: .zero, properties: nil)
        
        annotation.color = .clear
        let border = PDFBorder()
        border.lineWidth = 0
    
        annotation.border = border
        return annotation
    }
    
}

extension SignatureViewController: PDFDocumentDelegate {
    
    func documentDidBeginDocumentFind(_ notification: Notification) {
        //        searchItems.removeAll()
        /*
         if (!_searchedItems){
         _searchedItems = [[NSMutableArray alloc]init];
         }
         */
    }
    
    func documentDidEndDocumentFind(_ notification: Notification) {
        pdfView.highlightedSelections = searchItems
        
        //        searchItems.removeAll()
    }
    
    func didMatchString(_ instance: PDFSelection) {
        
        print(instance)
        
        for page in instance.pages {

            let currentPageIndex = pdfDocument.index(for: page)
            
            var stringBounds:CGRect = instance.bounds(for: pdfDocument.page(at: currentPageIndex)!)
            stringBounds.origin.y = stringBounds.origin.y+5
            stringBounds.size.height = 30

            let currentAnnotation = self.getSignatureAnnotation()
            currentAnnotation.bounds = stringBounds
            pdfDocument.page(at: currentPageIndex)!.addAnnotation(currentAnnotation)

            print(selectedUrlString)
            
            //Lastly, write your file to the disk.
            if !pdfDocument.write(to: selectedUrlString) {
                         NSLog("Failed to save PDF")
            }
        }
        searchItems.append(instance)
    }
    
}


class SignaturePDFAnnotation:PDFAnnotation {
    var image: NSImage?

    convenience init(_ image: NSImage?, bounds: CGRect, properties: [AnyHashable : Any]?) {
        self.init(bounds: bounds, forType: PDFAnnotationSubtype.square, withProperties: properties)
        self.image = image
    }
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        super.draw(with: box, in: context)

        // Drawing the image within the annotation's bounds.
        guard let cgImage = image?.cgImage else { return }
        context.draw(cgImage, in: bounds)
    }
}


extension NSImage {
    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        proposedRect = getAspectFitFrame(sizeImgView: self.size, sizeImage: CGSize(width: 100, height: 35))
        
        return cgImage(forProposedRect: &proposedRect,
                       context: nil,
                       hints: nil)
    }
    
    func getAspectFitFrame(sizeImgView:CGSize, sizeImage:CGSize) -> CGRect{

        let imageSize:CGSize  = sizeImage
        let viewSize:CGSize = sizeImgView

        let hfactor : CGFloat = imageSize.width/viewSize.width
        let vfactor : CGFloat = imageSize.height/viewSize.height

        let factor : CGFloat = max(hfactor, vfactor)

        // Divide the size by the greater of the vertical or horizontal shrinkage factor
        let newWidth : CGFloat = imageSize.width / factor
        let newHeight : CGFloat = imageSize.height / factor

        var x:CGFloat = 0.0
        var y:CGFloat = 0.0
        if newWidth > newHeight{
            y = (sizeImgView.height - newHeight)/2
        }
        if newHeight > newWidth{
            x = (sizeImgView.width - newWidth)/2
        }
        let newRect:CGRect = CGRect(x: x, y: y, width: newWidth, height: newHeight)

        return newRect

    }
}
