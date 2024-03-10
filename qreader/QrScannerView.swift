//
//  QrScannerView.swift
//  qreader
//
//  Created by Nicola De Filippo on 09/03/24.
//

import SwiftUI
import VisionKit

@MainActor
struct QrScannerView: UIViewControllerRepresentable {
    @Binding var qr: String
   
    var scannerViewController: DataScannerViewController = DataScannerViewController(
        recognizedDataTypes: [.barcode()],
        qualityLevel: .accurate,
        recognizesMultipleItems: false,
        isHighFrameRateTrackingEnabled: false,
        isHighlightingEnabled: false
    )
    
    var scannerAvailable: Bool {
        DataScannerViewController.isSupported &&
        DataScannerViewController.isAvailable
    }
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func start() {
        try? scannerViewController.startScanning()
    }
    
    func stop() {
        scannerViewController.stopScanning()
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: QrScannerView
        var qr = ""
        init(_ parent: QrScannerView) {
            self.parent = parent
            parent.start()

        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processAddedItems(items: addedItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            processItem(item: item)
        }
        
        func processAddedItems(items: [RecognizedItem]) {
            for item in items {
                processItem(item: item)
            }
        }

        func processItem(item: RecognizedItem) {
            switch item {
            case .barcode(let code):
                parent.qr = code.payloadStringValue ?? ""
            case .text(_):
                break
            @unknown default:
                print("Should not happen")
            }
        }
    }
}
