//
//  QRUIView.swift
//  qreader
//
//  Created by Nicola De Filippo on 10/03/24.
//

import SwiftUI

struct SheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var qrCode: String
    var body: some View {
        VStack {
            QrScannerView(qr: $qrCode)
        }.overlay(
            VStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }.foregroundStyle(.black)
                    .frame(maxWidth: 60, maxHeight: 60)
                    .background(.yellow)
                    .cornerRadius(10)
            }
        ).onChange(of: qrCode) {
            dismiss()
        }
    }
}

#Preview {
    @State var dum = ""
    return SheetView(qrCode: $dum)
}
