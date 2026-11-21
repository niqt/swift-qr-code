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
    var body: some View {
        VStack {
            if booksModel.books.isEmpty {
                VStack {
                    Form {
                        TextField("isbn", text: $isbn)
                        TextField("Title", text: $title)
                        TextField("Subtitle", text: $subtitle)
                        TextField("Author 1", text: $author1)
                        TextField("Author 2", text: $author2)
                        TextField("Author 3", text: $author3)
                        TextField("Author 4", text: $author4)
                        Toggle("Letto", isOn: $read)
                        TextField("Posizione (opzionale)", text: $position)
                        
                            
                    }
                    Button("Send") {
                        var book: VolumeInfo
                        book = VolumeInfo(title: title,
                            subtitle: subtitle,
                            authors: [author1, author2, author3, author4].filter { !$0.isEmpty },
                            imageLinks: nil,
                            isbn13: isbn,
                            isbn10: isbn,
                            publisher: "",
                            publishedDate: "",
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
