//
//  PDFViewerController.swift
//  FileSpy
//
//  Created by Chaudhari, Dipak Bharat (external - Project) on 27/08/20.
//  Copyright © 2020 Ray Wenderlich. All rights reserved.
//

import Cocoa
import PDFKit

class PDFViewerController: NSViewController,PDFDocumentDelegate {

    @IBOutlet weak var pdfView: PDFView!
//    var document: PDFDocument!
    var document = PDFDocument(url: Bundle.main.url(forResource: "Chat Transcript", withExtension: "pdf")!)!

    var searchedItem: PDFSelection?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        NotificationCenter.default.addObserver(self, selector: #selector(highlightSelection), name: Notification.Name("Highlight"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PDFChanged), name: Notification.Name("PDFChanged"), object: nil)
//        self.document = PDFDocument(url: selectedUrlString)
        
        pdfView.document = self.document
        self.document.delegate = self
    }
    
    @objc func PDFChanged() {
        self.document = PDFDocument(url: selectedUrlString) ?? PDFDocument(url: Bundle.main.url(forResource: "Chat Transcript", withExtension: "pdf")!)!
        pdfView.document = self.document
        self.document.beginFindString("Chat", withOptions: [NSString.CompareOptions.caseInsensitive])

    }
    
    func documentDidFindMatch(_ notification: Notification) {
        print("Did Match")
       if let selection = notification.userInfo?.first?.value as? PDFSelection {
            selection.color = .yellow
            if searchedItem == nil {
                // The first found item sets the object.
                searchedItem = selection
            } else {
                // All other found selection will be nested
                searchedItem!.add(selection)
            }
        }
    }
    
    @objc func highlightSelection(_ notification: Notification) {
            let selections = pdfView.currentSelection?.selectionsByLine()
            guard let page = selections?.first?.pages.first else { return }
        
            selections?.forEach({ selection in
                print(selection)
                page.addAnnotation(ImageAnnotation(imageBounds: selection.bounds(for: page), image: NSImage(named: NSImage.Name(rawValue: "THANEKAR copy.png"))))
                
                let highlight = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
                highlight.color = .yellow
                page.addAnnotation(highlight)
            })
    }
    
    func didMatchString(_ instance: PDFSelection) {
        print("Did Match String")
        let selections = pdfView?.document?.findString("PDFKit, my dear!", withOptions: [.caseInsensitive])
        // Simple scenario, assuming your pdf is single-page.
        guard let page = selections?.first?.pages.first else { return }

        selections?.forEach({ selection in
            if #available(OSX 10.13, *) {
                let highlight = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
                highlight.endLineStyle = .square
                highlight.color = NSColor.orange.withAlphaComponent(0.5)
                page.addAnnotation(highlight)
            } else {
                // Fallback on earlier versions
            }
          
        })
    }
    
//    func signDoc() {
//
//        let page = self.document.page(at: 0)!
//
//         // Extract the crop box of the PDF. We need this to create an appropriate graphics context.
//        let bounds = page.bounds(for: .cropBox)
//
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = 1
//
//        // Create a `UIGraphicsImageRenderer` to use for drawing an image.
////        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: UIGraphicsImageRendererFormat.default())
//        let renderer = UIGraphicsImageRenderer(
//
//        // This method returns an image and takes a block in which you can perform any kind of drawing.
//        let image = renderer.image { (context) in
//            // We transform the CTM to match the PDF's coordinate system, but only long enough to draw the page.
//            context.cgContext.saveGState()
//
//            context.cgContext.translateBy(x: 0, y: bounds.height)
//            context.cgContext.concatenate(CGAffineTransform.init(scaleX: 1, y: -1))
//            page.draw(with: .mediaBox, to: context.cgContext)
//
//            context.cgContext.restoreGState()
//
//            let image = NSImage.Name(rawValue: "THANEKAR copy.png")
//
//            let imageRect = CGRect(x: 0, y: 0, width: 150, height: 80)
//
//            // Draw your image onto the context.
//            image.draw(in: imageRect)
//        }
//
//        // Create a new `PDFPage` with the image that was generated above.
//        let newPage = PDFPage(image: image)!
//
//        // Add the existing annotations from the existing page to the new page we created.
//        for annotation in page.annotations {
//            newPage.addAnnotation(annotation)
//        }
//
//        // Insert the newly created page at the position of the original page.
//        pdfDocument.insert(newPage, at: 0)
//
//        // Remove the original page.
//        pdfDocument.removePage(at: 1)
//
//        // Save the document changes.
//        pdfDocument.write(toFile: filePath)
//    }
}

public class ImageAnnotation: PDFAnnotation {

    private var _image: NSImage?

    public init(imageBounds: CGRect, image: NSImage?) {
        self._image = image
        super.init(bounds: imageBounds, forType: .stamp, withProperties: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let cgImage = self._image?.cgImage else {
            return
        }
       let drawingBox = self.page?.bounds(for: box)
       //Virtually changing reference frame since the context is agnostic of them. Necessary hack.

    let inUrl: URL = selectedUrlString
    let outUrl: CFURL = selectedUrlString as CFURL

    let doc: PDFDocument = PDFDocument(url: inUrl)!
        
    let page: PDFPage = doc.page(at: 0)!
    var mediaBox: CGRect = page.bounds(for: .mediaBox)

    let gc = CGContext(outUrl, mediaBox: &mediaBox, nil)!
    let nsgc = NSGraphicsContext(cgContext: gc, flipped: false)
    NSGraphicsContext.current = nsgc
    gc.beginPDFPage(nil); do {
        page.draw(with: .mediaBox, to: gc)
        gc.saveGState(); do {
            self._image?.draw(in: drawingBox!)
        }; gc.restoreGState()

    }; gc.endPDFPage()
    NSGraphicsContext.current = nil
    gc.closePDF()
    }
}
