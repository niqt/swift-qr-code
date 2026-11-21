//
//  ContentView.swift
//  qreader
//
//  Created by Nicola De Filippo on 09/03/24.
//

import SwiftUI

struct ContentView: View {
    @State var qr = ""
    @State var scan = false
    @State var manual = false
    @State var settings = false
    @State var booksModel = BookViewModel()
    @State var searchText = ""
    @State var readFilter: ReadFilter = .all
    // Ricordato tra un avvio e l'altro
    @AppStorage("sortDescending") var sortDescending = false
    // Libro in attesa di conferma della cancellazione
    @State var bookToDelete: Book?
    @State var deleteError: String?

    enum ReadFilter: String, CaseIterable, Identifiable {
        case all = "Tutti"
        case read = "Letti"
        case unread = "Da leggere"
        var id: Self { self }
    }

    // La ricerca testuale la fa il server; il filtro letti/da leggere resta locale
    private var filteredBooks: [Book] {
        booksModel.serverBooks.filter { book in
            let isRead = book.read ?? false
            switch readFilter {
            case .all: return true
            case .read: return isRead
            case .unread: return !isRead
            }
        }
    }

    private func count(_ filter: ReadFilter) -> Int {
        let books = booksModel.serverBooks
        switch filter {
        case .all: return books.count
        case .read: return books.filter { $0.read == true }.count
        case .unread: return books.filter { $0.read != true }.count
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func reload() {
        Task { await booksModel.loadServerBooks(search: searchText, descending: sortDescending) }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch booksModel.state {
                case .Loading where booksModel.serverBooks.isEmpty && !isSearching:
                    ProgressView()
                case .Error:
                    VStack(spacing: 16) {
                        Text(booksModel.errorMessage)
                            .multilineTextAlignment(.center)
                        Button("Riprova", action: reload)
                    }
                    .padding()
                default:
                    if booksModel.serverBooks.isEmpty && !isSearching && booksModel.state == .Loaded {
                        ContentUnavailableView("Nessun libro", systemImage: "books.vertical",
                                               description: Text("Scansiona un codice o aggiungi un libro a mano."))
                    } else {
                        List {
                            HStack {
                                Picker("Filtro", selection: $readFilter) {
                                    ForEach(ReadFilter.allCases) { filter in
                                        Text("\(filter.rawValue) \(count(filter))").tag(filter)
                                    }
                                }
                                .pickerStyle(.segmented)

                                Button {
                                    sortDescending.toggle()
                                } label: {
                                    Text(sortDescending ? "Z→A" : "A→Z")
                                        .font(.footnote.weight(.semibold))
                                        .monospaced()
                                }
                                .buttonStyle(.bordered)
                                .accessibilityLabel(sortDescending ? "Ordine Z-A, tocca per A-Z" : "Ordine A-Z, tocca per Z-A")
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())

                            ForEach(filteredBooks) { book in
                                NavigationLink {
                                    BookDetailView(book: book, booksModel: booksModel)
                                } label: {
                                    BookRow(book: book)
                                }
                                // Niente role .destructive: farebbe sparire la riga prima della conferma
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        bookToDelete = book
                                    } label: {
                                        Label("Elimina", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                        .overlay {
                            if booksModel.state == .Loading {
                                ProgressView()
                            } else if filteredBooks.isEmpty {
                                if !isSearching {
                                    ContentUnavailableView("Nessun libro \(readFilter == .read ? "letto" : "da leggere")",
                                                           systemImage: "line.3.horizontal.decrease.circle")
                                } else {
                                    ContentUnavailableView.search(text: searchText)
                                }
                            }
                        }
                        .refreshable {
                            await booksModel.loadServerBooks(search: searchText, descending: sortDescending)
                        }
                    }
                }
            }
            .navigationTitle("Libri")
            .alert("Eliminare il libro?",
                   isPresented: Binding(get: { bookToDelete != nil },
                                        set: { if !$0 { bookToDelete = nil } }),
                   presenting: bookToDelete) { book in
                Button("Elimina", role: .destructive) {
                    Task {
                        deleteError = await booksModel.delete(book: book)
                    }
                }
                Button("Annulla", role: .cancel) {}
            } message: { book in
                Text("\"\(book.title)\" verrà eliminato definitivamente dal server.")
            }
            .alert("Impossibile eliminare il libro",
                   isPresented: Binding(get: { deleteError != nil },
                                        set: { if !$0 { deleteError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteError ?? "")
            }
            // Sul Group, così la barra resta visibile anche quando non ci sono risultati
            .searchable(text: $searchText, prompt: "Titolo, autore, ISBN, posizione, note…")
            .task(id: "\(searchText)|\(sortDescending)") {
                // All'avvio carica tutto; poi ricarica a ogni ricerca,
                // aspettando una pausa nella digitazione per non chiamare il server a ogni lettera
                if isSearching {
                    try? await Task.sleep(for: .milliseconds(350))
                    if Task.isCancelled { return }
                }
                await booksModel.loadServerBooks(search: searchText, descending: sortDescending)
            }
            .sheet(isPresented: $scan, onDismiss: reload) {
                SheetView(qrCode: $qr)
            }.sheet(isPresented: $manual, onDismiss: reload) {
                ManualSheetUIView()
            }.sheet(isPresented: $settings, onDismiss: reload) {
                SettingsUIView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    
                    Button(action: {
                        settings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    
                    Button(action: {
                        qr = ""
                        scan = true
                    }) {
                        Image(systemName: "qrcode.viewfinder")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                       
                        manual = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                       
                        
                    }) {
                        Image(systemName: "printer")
                    }
                }
            }
            
        }
    }
}

struct BookRow: View {
    let book: Book

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                if let authors = book.authors, !authors.isEmpty {
                    Text(authors.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let position = book.position, !position.isEmpty {
                    Label(position, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if book.read == true {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("Letto")
            }
        }
    }
}

#Preview {
    ContentView()
}
