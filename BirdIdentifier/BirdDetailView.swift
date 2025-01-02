import SwiftUI
import MapKit
import TPackage

struct BirdDetailView: View {
    let bird: BirdEntity
    @Environment(\.managedObjectContext) private var viewContext
    @State private var region: MKCoordinateRegion
    @State private var showingShareSheet = false
    @State private var showingMapSheet = false
    @State private var isFavorite: Bool
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State private var showPaywall = false
    @EnvironmentObject var premiumManager: TKPremiumManager
    
    private var mapsURL: URL? {
        let latitude = bird.latitude
        let longitude = bird.longitude
        return URL(string: "http://maps.apple.com/?ll=\(latitude),\(longitude)")
    }
    
    private var shareItems: [Any] {
        var items: [Any] = []
        
        if let imageData = bird.imageData,
           let uiImage = UIImage(data: imageData) {
            items.append(uiImage)
        }
        
        // Create text content
        var text = """
        Check out what I've found with Birdi!
        Common Name: \(bird.commonName ?? "Unknown")
        Scientific Name: \(bird.scientificName ?? "Unknown")
        """
        
        if let locationName = bird.locationName {
            text += "\nLocation: \(locationName)"
        }
        
        if let mapsURL = mapsURL {
            text += "\nView on Apple Maps: \(mapsURL.absoluteString)"
        }
        
        if let date = bird.dateAdded {
            text += "\nAdded: \(date.formatted(date: .long, time: .shortened))"
        }

        text += "\nInstall Birdi today! https://apps.apple.com/us/app/birdi-ai-bird-identifier/id6740003551"

        items.append(text)
        
        return items
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: bird.latitude,
            longitude: bird.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = bird.commonName
        mapItem.openInMaps()
    }
    
    private func deleteBird() {
        viewContext.delete(bird)
        try? viewContext.save()
        dismiss()
    }
    
    init(bird: BirdEntity) {
        self.bird = bird
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: bird.latitude,
                longitude: bird.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
        _isFavorite = State(initialValue: bird.isFavorite)
    }
    
    var body: some View {
        List {
            Section(header: HStack {
                Image(systemName: "laurel.leading")
                    .symbolRenderingMode(.multicolor)
                Text("Bird Information")
                Image(systemName: "laurel.trailing")
                    .symbolRenderingMode(.multicolor)
            },footer: Text("Birdi can make mistakes. Verify important information.")) {
                HStack() {
                    Label {
                        Text("Common Name")
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "bird.fill")
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Text(bird.commonName ?? "Unknown")
                        .bold()
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack() {
                    Label {
                        Text("Scientific Name")
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "text.book.closed.fill")
                            .foregroundStyle(.brown)
                    }
                    Spacer()
                    Text(bird.scientificName ?? "Unknown")
                        .italic()
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack() {
                    Label {
                        Text("Address")
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "map.fill")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Text(bird.locationName ?? "Unknown")
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if let symbolism = bird.symbolism {
                    HStack() {
                        Label {
                            Text("Symbolism")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                        }
                        Spacer()
                        Text(symbolism)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                            .blur(radius: premiumManager.isPremium ? 0 : 5)

                    }
                    .onTapGesture {
                        if !premiumManager.isPremium {
                            showPaywall = true
                        }
                    }
                }

                if let nativeRegion = bird.nativeRegion, !nativeRegion.isEmpty {
                    HStack {
                        Label {
                            Text("Native Region")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        Text(nativeRegion)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let colorPatterns = bird.colorPatterns, !colorPatterns.isEmpty {
                Section(header: HStack {
                    Image(systemName: "paintpalette.fill")
                        .symbolRenderingMode(.hierarchical)
                    Text("Color Patterns")
                }) {
                    Text(colorPatterns)
                        .padding(4)
                        .blur(radius: premiumManager.isPremium ? 0 : 5)
                        .onTapGesture {
                            if !premiumManager.isPremium {
                                showPaywall = true
                            }
                        }
                }
            }

            if let size = bird.size, !size.isEmpty {
                Section(header: HStack {
                    Image(systemName: "ruler.fill")
                        .symbolRenderingMode(.hierarchical)
                    Text("Size")
                }) {
                    Text(size)
                        .padding(4)
                    
                }
            }

            if let distinctiveFeatures = bird.distinctiveFeatures, !distinctiveFeatures.isEmpty {
                Section(header: HStack {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .symbolRenderingMode(.hierarchical)
                    Text("Distinctive Features")
                }) {
                    Text(distinctiveFeatures)
                        .padding(4)
                        .blur(radius: premiumManager.isPremium ? 0 : 5)
                        .onTapGesture {
                            if !premiumManager.isPremium {
                                showPaywall = true
                            }
                        }
                }
            }

            if let behavior = bird.behavior, !behavior.isEmpty {
                Section(header: HStack {
                    Image(systemName: "figure.walk")
                        .symbolRenderingMode(.hierarchical)
                    Text("Behavior")
                }) {
                    Text(behavior)
                        .padding(4)
                        .blur(radius: premiumManager.isPremium ? 0 : 5)
                        .onTapGesture {
                            if !premiumManager.isPremium {
                                showPaywall = true
                            }
                        }
                }
            }

            if let conservationStatus = bird.conservationStatus, !conservationStatus.isEmpty {
                Section(header: HStack {
                    Image(systemName: "leaf.fill")
                        .symbolRenderingMode(.hierarchical)
                    Text("Conservation Status")
                }) {
                    Text(conservationStatus)
                        .padding(4)
                }
            }

            if let story = bird.story, !story.isEmpty && story.lowercased() != "none" {
                Section(header: HStack {
                    Image(systemName: "book.pages")
                        .symbolRenderingMode(.hierarchical)
                    Text("Story & Mythology")
                }) {
                    Text(story)
                        .padding(4)
                        .blur(radius: premiumManager.isPremium ? 0 : 5)
                        .onTapGesture {
                            if !premiumManager.isPremium {
                                showPaywall = true
                            }
                        }
                }
            }

            if let date = bird.dateAdded {
                Section("Added") {
                    HStack {
                        Label {
                            Text("Date")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        Text(date.formatted(date: .long, time: .shortened))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(bird.commonName ?? "Bird Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        openInMaps()
                    } label: {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                    }
                    
                    Menu {
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share to Friends", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                        
                        Button {
                            showingMapSheet = true
                        } label: {
                            Label("See on Map", systemImage: "map")
                        }
                        .tint(.green)
                        
                        Button {
                            withAnimation(.spring()) {
                                isFavorite.toggle()
                                bird.isFavorite = isFavorite
                                try? viewContext.save()
                            }
                        } label: {
                            Label(
                                isFavorite ? "Remove from Habitat" : "Add to Habitat",
                                systemImage: isFavorite ? "heart.fill" : "heart"
                            )
                        }
                        .tint(isFavorite ? .red : .pink)
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Bird", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .alert("Delete Bird", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteBird()
            }
        } message: {
            Text("Are you sure you want to delete this bird? This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showingMapSheet) {
            NavigationStack {
                MapDetailView(bird: bird)
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            CustomPaywallView()
                .onPurchaseCompleted { customerInfo in
                    Task {
                        await premiumManager.checkPremiumStatus()
                        if premiumManager.isPremium {
                            showPaywall = false
                        }
                    }
                }
                .onRestoreCompleted { customerInfo in
                    Task {
                        await premiumManager.checkPremiumStatus()
                        if premiumManager.isPremium {
                            showPaywall = false
                        }
                    }
                }
                .interactiveDismissDisabled()
        }
    }
}

struct MapDetailView: View {
    let bird: BirdEntity
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: bird.latitude,
                longitude: bird.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))) {
            Marker(bird.commonName ?? "Bird", coordinate: CLLocationCoordinate2D(
                latitude: bird.latitude,
                longitude: bird.longitude
            ))
        }
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// ShareSheet wrapper for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
