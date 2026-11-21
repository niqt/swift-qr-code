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
    @State var booksModel = BookViewModel()
    @State var read = false
    @State var position = ""

    private var selectedBook: VolumeInfo? {
        booksModel.books.first?.volumeInfo
    }

    var body: some View {
        VStack {
            switch booksModel.state {
            case .Loading:
                ProgressView()
            case .Error:
                VStack(spacing: 16) {
                    Text(booksModel.errorMessage.isEmpty ? "Errore" : booksModel.errorMessage)
                        .multilineTextAlignment(.center)
                    Button("Riprova") {
                        // Azzerare il codice permette di riscansionare lo stesso libro
                        qrCode = ""
                        read = false
                        position = ""
                        booksModel.reset()
                    }
                }
                .padding()
            case .Loaded:
                if booksModel.books.isEmpty {
                    QrScannerView(qr: $qrCode)
                } else {
                    List {
                        ForEach(booksModel.books, id:\.id) { book in
                            if let volumeInfo = book.volumeInfo {
                                Text(volumeInfo.title)
                            }
                        }
                        Toggle("Letto", isOn: $read)
                        TextField("Posizione (opzionale)", text: $position)
                    }
                }
            }
        }.overlay(
            VStack {
                Spacer()
                Button("Send") {
                    guard var book = selectedBook else { return }
                    book.read = read
                    book.position = position.isEmpty ? nil : position
                    Task {
                        if await booksModel.send(book: book) {
                            dismiss()
                        }
                    }
                }.foregroundStyle(.black)
                    .frame(maxWidth: 60, maxHeight: 60)
                    .background(.yellow)
                    .cornerRadius(10)
                    .disabled(selectedBook == nil || booksModel.state != .Loaded)
                    .opacity(selectedBook == nil || booksModel.state != .Loaded ? 0.4 : 1)
            }
        ).onChange(of: qrCode) {
            guard !qrCode.isEmpty else { return }
            print(qrCode)
            Task {
                await booksModel.loadBooks(isbn: qrCode)
            }
        }
    }
}

#Preview {
    @Previewable @State var dum = ""
    return SheetView(qrCode: $dum)
}
