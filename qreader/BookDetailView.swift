//
//  BookDetailView.swift
//  qreader
//

import SwiftUI

struct BookDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book
    let booksModel: BookViewModel

    @State private var position: String
    @State private var note: String
    @State private var isRead: Bool
    @State private var saving = false
    @State private var errorMessage: String?

    init(book: Book, booksModel: BookViewModel) {
        self.book = book
        self.booksModel = booksModel
        _position = State(initialValue: book.position ?? "")
        _note = State(initialValue: book.note ?? "")
        _isRead = State(initialValue: book.read ?? false)
    }

    private var hasChanges: Bool {
        position != (book.position ?? "") ||
        note != (book.note ?? "") ||
        isRead != (book.read ?? false)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.title3.bold())
                    if let subtitle = book.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .foregroundStyle(.secondary)
                    }
                }
                if let authors = book.authors, !authors.isEmpty {
                    LabeledContent("Autori", value: authors.joined(separator: ", "))
                }
                if let publisher = book.publisher, !publisher.isEmpty {
                    LabeledContent("Editore", value: publisher)
                }
                if let date = book.publishedDate, !date.isEmpty {
                    LabeledContent("Pubblicato", value: date)
                }
                if let isbn = book.isbn13 ?? book.isbn10, !isbn.isEmpty {
                    LabeledContent("ISBN", value: isbn)
                }
            }

            Section("Il mio libro") {
                Toggle("Letto", isOn: $isRead)
                TextField("Posizione", text: $position)
            }

            Section("Note") {
                TextField("Scrivi una nota", text: $note, axis: .vertical)
                    .lineLimit(4...12)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Dettaglio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if saving {
                    ProgressView()
                } else {
                    Button("Salva", action: save)
                        .disabled(!hasChanges)
                }
            }
        }
    }

    private func save() {
        var updated = book
        updated.position = position.isEmpty ? nil : position
        updated.note = note.isEmpty ? nil : note
        updated.read = isRead
        saving = true
        errorMessage = nil
        Task {
            let error = await booksModel.update(book: updated)
            saving = false
            if let error {
                errorMessage = error
            } else {
                dismiss()
            }
        }
    }
}
