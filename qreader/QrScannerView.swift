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

    static var scannerAvailable: Bool {
        DataScannerViewController.isSupported &&
        DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        // Creato una sola volta da SwiftUI, non a ogni ricreazione della struct
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean8, .ean13, .qr])],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: false
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.parent = self
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: QrScannerView

        init(_ parent: QrScannerView) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                processItem(item: item)
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            processItem(item: item)
        }

        func processItem(item: RecognizedItem) {
            switch item {
            case .barcode(let code):
                parent.qr = code.payloadStringValue ?? ""
            case .text(let t):
                parent.qr = t.transcript
            @unknown default:
                print("Should not happen")
            }
        }
    }
}
