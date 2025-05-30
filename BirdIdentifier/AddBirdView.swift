//
//  AddBirdView.swift
//  BirdIdentifier
//
//  Created by Türker Kızılcık on 25.12.2024.
//

import SwiftUI
import CoreLocation
import MapKit
import TPackage

struct AddBirdView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @State private var isAnalyzing = false
    @State private var commonName = ""
    @State private var scientificName = ""
    @State private var locationName = ""
    @State private var showingLocationPicker = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    let initialImageData: Data
    @State private var symbolism = ""
    @State private var story = ""
    @State private var nativeRegion = ""
    @State private var colorPatterns = ""
    @State private var size = ""
    @State private var distinctiveFeatures = ""
    @State private var conservationStatus = ""
    @State private var behavior = ""
    @StateObject private var locationManager = LocationManager()
    @State private var currentLocationName: String = ""
    @State private var identificationFailed = false
    @EnvironmentObject var premiumManager: TKPremiumManager

    private func saveBird() {
        let newBird = BirdEntity(context: viewContext)
        newBird.id = UUID()
        newBird.commonName = commonName
        newBird.scientificName = scientificName
        newBird.imageData = initialImageData
        newBird.dateAdded = Date()
        newBird.symbolism = symbolism
        newBird.story = story
        newBird.nativeRegion = nativeRegion
        newBird.colorPatterns = colorPatterns
        newBird.size = size
        newBird.distinctiveFeatures = distinctiveFeatures
        newBird.conservationStatus = conservationStatus
        newBird.behavior = behavior

        if let coordinate = selectedCoordinate {
            newBird.latitude = coordinate.latitude
            newBird.longitude = coordinate.longitude
            newBird.locationName = locationName
        } else if let currentLocation = locationManager.location {
            newBird.latitude = currentLocation.coordinate.latitude
            newBird.longitude = currentLocation.coordinate.longitude
            newBird.locationName = currentLocationName.isEmpty ? "Unknown Location" : currentLocationName
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving bird: \(error)")
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if identificationFailed {
                    ContentUnavailableView(
                        "Unable to Identify Bird",
                        systemImage: "bird.circle.fill",
                        description: Text("We couldn't identify this bird. Please try again with a clearer photo.")
                    )
                    .foregroundStyle(.red)
                } else {
                    List {
                        Section {
                            if let uiImage = UIImage(data: initialImageData) {
                                GeometryReader { geometry in
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                        )
                                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                }
                                .frame(height: 200)
                                .listRowInsets(EdgeInsets())
                            }
                        }
                        .listRowBackground(Color.clear)

                        if isAnalyzing {
                            Section {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("Analyzing bird...")
                                        .foregroundColor(.secondary)
                                        .padding(.leading)
                                }
                            }
                        }

                        if !commonName.isEmpty {
                            Section("Bird Information") {
                                HStack() {
                                    Label {
                                        Text("Common Name")
                                            .foregroundColor(.secondary)
                                    } icon: {
                                        Image(systemName: "bird.fill")
                                            .foregroundStyle(.green)
                                    }
                                    Spacer()
                                    Text(commonName)
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
                                    Text(scientificName)
                                        .italic()
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Button(action: {
                                    showingLocationPicker = true
                                }) {
                                    HStack {
                                        Label {
                                            Text("Location")
                                                .foregroundColor(.secondary)
                                        } icon: {
                                            Image(systemName: "location.fill")
                                                .foregroundStyle(.red)
                                        }
                                        Spacer()
                                        Text(locationName.isEmpty ? "Select Location" : locationName)
                                            .foregroundColor(locationName.isEmpty ? .blue : .primary)
                                            .multilineTextAlignment(.trailing)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }

                                HStack() {
                                    Label {
                                        Text("Added")
                                            .foregroundColor(.secondary)
                                    } icon: {
                                        Image(systemName: "calendar")
                                            .foregroundStyle(.blue)
                                    }
                                    Spacer()
                                    Text(Date().formatted(date: .abbreviated, time: .shortened))
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                if !symbolism.isEmpty {
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
                                            .blur(radius: premiumManager.isPremium ? 0 : 3)

                                    }
                                }

                                if !nativeRegion.isEmpty {
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
                            
                            if !colorPatterns.isEmpty {
                                Section(header: HStack {
                                    Image(systemName: "paintpalette.fill")
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Color Patterns")
                                }) {
                                    Text(colorPatterns)
                                        .padding(4)
                                        .blur(radius: premiumManager.isPremium ? 0 : 5)
                                }
                            }

                            if !size.isEmpty {
                                Section(header: HStack {
                                    Image(systemName: "ruler.fill")
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Size")
                                }) {
                                    Text(size)
                                        .padding(4)
                                }
                            }

                            if !distinctiveFeatures.isEmpty {
                                Section(header: HStack {
                                    Image(systemName: "sparkles.rectangle.stack.fill")
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Distinctive Features")
                                }) {
                                    Text(distinctiveFeatures)
                                        .padding(4)
                                        .blur(radius: premiumManager.isPremium ? 0 : 5)

                                }
                            }

                            if !behavior.isEmpty {
                                Section(header: HStack {
                                    Image(systemName: "figure.walk")
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Behavior")
                                }) {
                                    Text(behavior)
                                        .padding(4)
                                        .blur(radius: premiumManager.isPremium ? 0 : 5)

                                }
                            }

                            if !conservationStatus.isEmpty {
                                Section(header: HStack {
                                    Image(systemName: "leaf.fill")
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Conservation Status")
                                }) {
                                    Text(conservationStatus)
                                        .padding(4)
                                }
                            }

                            if !story.isEmpty && story.lowercased() != "none" {
                                Section(header: HStack {
                                    Image(systemName: "book.pages")
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Story & Mythology")
                                }) {
                                    Text(story)
                                        .padding(4)
                                        .blur(radius: premiumManager.isPremium ? 0 : 3)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBird()
                    }
                    .disabled(commonName.isEmpty || identificationFailed)
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(
                    locationName: $locationName,
                    selectedCoordinate: $selectedCoordinate
                )
            }
        }
        .onAppear {
            Task {
                if let location = locationManager.location {
                    await getCurrentLocationName(from: location)
                }
                await analyzeBird(imageData: initialImageData)
            }
        }
    }

    private func getCurrentLocationName(from location: CLLocation) async {
        let geocoder = CLGeocoder()
        do {
            if let placemark = try await geocoder.reverseGeocodeLocation(location).first {
                let locationComponents = [
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }
                currentLocationName = locationComponents.joined(separator: ", ")
            }
        } catch {
            print("Geocoding error: \(error)")
        }
    }

    func analyzeBird(imageData: Data) async {
        isAnalyzing = true
        identificationFailed = false
        
        let endpoint = "https://api.turkerkizilcik.com/chat/index.php"

        let base64Image = imageData.base64EncodedString()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let currentDateTime = dateFormatter.string(from: Date())
        
        let locationAndTimeContext = currentLocationName.isEmpty ? 
            "Note that this picture was taken on \(currentDateTime)." :
            "Note that this picture was taken in \(currentLocationName) on \(currentDateTime). Use this information to help with identification, but do not include the location in your response."
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "temperature": 0.2,
            "top_p": 0.2,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": """
                            \(locationAndTimeContext)
                            Identify this bird and provide ONLY the following information in this exact format:
                            common_name: NAME
                            scientific_name: FULL NAME (Genus and species, e.g., Corvus corax; include both parts)
                            native_region: REGIONS (e.g., Mediterranean Basin, Eastern Asia, North America)
                            color_patterns: DESCRIBE THE MAIN COLORS AND PATTERNS OF THE BIRD'S PLUMAGE
                            size: PROVIDE LENGTH, WINGSPAN, AND APPROXIMATE WEIGHT IF KNOWN
                            distinctive_features: LIST KEY IDENTIFYING FEATURES (e.g., curved beak, long tail, distinctive crest)
                            behavior: DESCRIBE TYPICAL BEHAVIOR AND HABITS (e.g., foraging patterns, social behavior, nesting habits)
                            conservation_status: CURRENT CONSERVATION STATUS (e.g., Least Concern, Near Threatened, Vulnerable, Endangered, Critically Endangered)
                            symbolism: TWO OR THREE WORDS MAX (e.g., peace, love, resilience)
                            story: A BRIEF INTERESTING STORY OR MYTH ABOUT THIS BIRD, TWO PARAGRAPHS IS ENOUGH (if none, write NONE)
                            Ensure that only "symbolism" is limited to two or three words, and "story" can be a full sentence or more. For native_region, list the main geographical regions where this bird naturally occurs. Do not include any additional text.
                            """
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 500
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            isAnalyzing = false
            return
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                if content.lowercased().contains("unable to identify") || 
                   content.lowercased().contains("cannot identify") ||
                   !content.lowercased().contains("common_name:") {
                    identificationFailed = true
                } else {
                    print(content)

                    let lines = content.components(separatedBy: "\n")
                    for line in lines {
                        if line.lowercased().starts(with: "common_name:") {
                            commonName = line.replacingOccurrences(of: "common_name:", with: "").trimmingCharacters(in: .whitespaces)
                        } else if line.lowercased().starts(with: "scientific_name:") {
                            scientificName = line.replacingOccurrences(of: "scientific_name:", with: "").trimmingCharacters(in: .whitespaces)
                        } else if line.lowercased().starts(with: "native_region:") {
                            nativeRegion = line.replacingOccurrences(of: "native_region:", with: "").trimmingCharacters(in: .whitespaces)
                        } else if line.lowercased().starts(with: "color_patterns:") {
                            colorPatterns = line.replacingOccurrences(of: "color_patterns:", with: "").trimmingCharacters(in: .whitespaces)
                        } else if line.lowercased().starts(with: "size:") {
                            size = line.replacingOccurrences(of: "size:", with: "").trimmingCharacters(in: .whitespaces)
                        } else if line.lowercased().starts(with: "distinctive_features:") {
                            distinctiveFeatures = line.replacingOccurrences(of: "distinctive_features:", with: "").trimmingCharacters(in: .whitespaces)
                        } else if line.lowercased().starts(with: "behavior:") {
                            behavior = line.replacingOccurrences(of: "behavior:", with: "").trimmingCharacters(in: .whitespaces)
                        } else if line.lowercased().starts(with: "conservation_status:") {
                            conservationStatus = line.replacingOccurrences(of: "conservation_status:", with: "").trimmingCharacters(in: .whitespaces)
                        } else if line.lowercased().starts(with: "symbolism:") {
                            symbolism = line.replacingOccurrences(of: "symbolism:", with: "").trimmingCharacters(in: .whitespaces)
                        } else if line.lowercased().starts(with: "story:") {
                            story = line.replacingOccurrences(of: "story:", with: "").trimmingCharacters(in: .whitespaces)
                        }
                    }
                }
            } else {
                identificationFailed = true
            }
        } catch {
            print("Error: \(error)")
            identificationFailed = true
        }

        isAnalyzing = false
    }
}

struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var locationName: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var hasInitialLocation = false
    @State private var isDragging = false
    @State private var debounceTimer: Timer?

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    if !searchResults.isEmpty {
                        List(searchResults, id: \.self) { item in
                            Button {
                                selectLocation(item)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "")
                                        .foregroundColor(.primary)
                                    if let address = item.placemark.title {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    } else {
                        Map(coordinateRegion: $region, showsUserLocation: true)
                            .onChange(of: region.center.latitude) { _ in
                                isDragging = true
                                debounceTimer?.invalidate()
                                debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                    isDragging = false
                                    reverseGeocode(region.center)
                                }
                            }
                    }
                }

                if searchResults.isEmpty {
                    Circle()
                        .fill(isDragging ? .green.opacity(0.85) : .green)
                        .frame(width: 8, height: 8)

                    VStack {
                        Spacer()
                        if !locationName.isEmpty {
                            Text(isDragging ? "Moving..." : locationName)
                                .font(.caption)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedCoordinate = region.center
                        dismiss()
                    }
                }
            }
            .onAppear {
                locationManager.startUpdatingLocation()
            }
            .onChange(of: locationManager.location) { newLocation in
                if let location = newLocation, !hasInitialLocation {
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                    hasInitialLocation = true
                }
            }
        }
    }

    private func selectLocation(_ item: MKMapItem) {
        selectedCoordinate = item.placemark.coordinate
        let address = [
            item.placemark.thoroughfare,
            item.placemark.locality,
            item.placemark.administrativeArea,
            item.placemark.country
        ].compactMap { $0 }.joined(separator: ", ")
        locationName = address
        region.center = item.placemark.coordinate
        searchResults.removeAll()
        searchText = ""
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                selectedCoordinate = coordinate
                let address = [
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                locationName = address
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        self.location = location
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}
