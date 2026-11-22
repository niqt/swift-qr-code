//
//  ManualSheetUIView.swift
//  qreader
//
//  Created by Nicola De Filippo on 13/12/25.
//

import SwiftUI

struct ManualSheetUIView: View {
    @Environment(\.dismiss) private var dismiss
    @State var found = false
    @State var booksModel = BookViewModel()
    @State var isbn: String = ""
    @State var title: String = ""
    @State var subtitle: String = ""
    @State var author1: String = ""
    @State var author2: String = ""
    @State var author3: String = ""
    @State var author4: String = ""
    @State var read = false
    @State var position = ""
    // Dati arrivati da Google Books che il form non mostra ma vanno salvati
    @State var publisher: String?
    @State var publishedDate: String?
    @State var imageLinks: ImagesLink?
    @State var isLookingUp = false
    @State var lookupMessage: String?

    private var parsedISBN: ISBN? { ISBN(isbn) }

    /// Cerca l'ISBN su Google Books e riempie i campi del form.
    private func lookup() {
        guard let code = parsedISBN else { return }
        isLookingUp = true
        lookupMessage = nil
        Task {
            let result = await booksModel.lookup(isbn: code)
            isLookingUp = false
            switch result {
            case .success(let info):
                title = info.title
                subtitle = info.subtitle ?? ""
                let authors = (info.authors ?? []) + Array(repeating: "", count: 4)
                author1 = authors[0]
                author2 = authors[1]
                author3 = authors[2]
                author4 = authors[3]
                publisher = info.publisher
                publishedDate = info.publishedDate
                imageLinks = info.imageLinks
                lookupMessage = (info.authors?.count ?? 0) > 4 ? "Trovato. Mostrati solo i primi 4 autori." : nil
            case .failure(let error):
                lookupMessage = error.message
            }
        }
    }
    var body: some View {
        VStack {
            if booksModel.books.isEmpty {
                VStack {
                    Form {
                        Section {
                            HStack {
                                TextField("ISBN", text: $isbn)
                                    .keyboardType(.numbersAndPunctuation)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .onSubmit { if parsedISBN != nil { lookup() } }
                                if isLookingUp {
                                    ProgressView()
                                } else {
                                    Button("Cerca", systemImage: "magnifyingglass", action: lookup)
                                        .labelStyle(.iconOnly)
                                        .buttonStyle(.borderless)
                                        .disabled(parsedISBN == nil)
                                        .accessibilityLabel("Cerca i dati del libro su Google Books")
                                }
                            }
                        } footer: {
                            if let lookupMessage {
                                Text(lookupMessage)
                            } else if !isbn.isEmpty && parsedISBN == nil {
                                Text("ISBN non valido: servono 10 o 13 cifre con la cifra di controllo corretta.")
                            }
                        }
                        TextField("Title", text: $title)
                        TextField("Subtitle", text: $subtitle)
                        TextField("Author 1", text: $author1)
                        TextField("Author 2", text: $author2)
                        TextField("Author 3", text: $author3)
                        TextField("Author 4", text: $author4)
                        Toggle("Letto", isOn: $read)
                        TextField("Posizione (opzionale)", text: $position)
                        
                            
                    }
                    .onChange(of: isbn) {
                        lookupMessage = nil
                        publisher = nil
                        publishedDate = nil
                        imageLinks = nil
                    }
                    Button("Send") {
                        var book: VolumeInfo
                        book = VolumeInfo(title: title,
                            subtitle: subtitle,
                            authors: [author1, author2, author3, author4].filter { !$0.isEmpty },
                            imageLinks: imageLinks,
                            isbn13: parsedISBN?.isbn13 ?? isbn,
                            isbn10: parsedISBN.map { $0.isbn10 } ?? isbn,
                            publisher: publisher ?? "",
                            publishedDate: publishedDate ?? "",
                            read: read,
                            position: position.isEmpty ? nil : position
                      )
                        Task {
                            let  result = await booksModel.send(book: book)
                            dismiss()
                        }
                        
                    }
                        
                }
            } else {
                switch booksModel.state {
                case .Loading:
                    ProgressView()
                case .Error:
                    Text("Error")
                case .Loaded:
                    VStack {
                        List {
                            ForEach(booksModel.books, id:\.id) { book in
                                if let volumeInfo = book.volumeInfo {
                                    Text(volumeInfo.title)
                                }
                            }
                        }
                        Spacer()
                        Button("Send") {
                            //dismiss()
                            Task {
                                guard var book = self.booksModel.books.first?.volumeInfo else { return }
                                book.read = read
                                book.position = position.isEmpty ? nil : position
                                let result = await booksModel.send(book: book)
                                if result {
                                    dismiss()
                                }
                            }
                        }.foregroundStyle(.black)
                            .frame(maxWidth: 60, maxHeight: 60)
                            .background(.yellow)
                            .cornerRadius(10)
                        
                    }
                }
            }
        }
    }
}

#Preview {
    ManualSheetUIView()
}
