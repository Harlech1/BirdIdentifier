//
//  CollectionView.swift
//  BirdIdentifier
//
//  Created by Türker Kızılcık on 24.12.2024.
//

import SwiftUI
import PhotosUI
import CoreData
import TPackage

struct CollectionView: View {
    @EnvironmentObject var premiumManager: TKPremiumManager
    @StateObject private var ratingManager = RatingManager.shared

    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var sunBounce = false

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("launchCount") private var launchCount: Int = 0
    @State private var hasShownInitialPaywall = false
    @State private var showPaywall = false
    @State private var showOnboarding = false
    @State private var showSpecialOffer = false

    @State private var showingAddSheet = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImageData: Data?
    @State private var selectedItem: PhotosPickerItem?

    let columns = [GridItem(.flexible())]

    @State private var isBouncingRainbow = false
    @State private var isBouncingRain = false
    @State private var rainbowTimer: Timer?
    @State private var rainTimer: Timer?

    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedBird: BirdEntity?
    var birdRequest: FetchRequest<BirdEntity>
    private var birds: FetchedResults<BirdEntity> { birdRequest.wrappedValue }

    init() {
        let request: NSFetchRequest<BirdEntity> = BirdEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \BirdEntity.dateAdded, ascending: false),
            NSSortDescriptor(keyPath: \BirdEntity.commonName, ascending: true)
        ]
        self.birdRequest = FetchRequest(fetchRequest: request)
    }

    private var filteredBirds: [BirdEntity] {
        let filtered = birds.filter { bird in
            let matchesSearch = searchText.isEmpty ||
            (bird.commonName ?? "").localizedCaseInsensitiveContains(searchText) ||
            (bird.scientificName ?? "").localizedCaseInsensitiveContains(searchText)
            return matchesSearch && (!showFavoritesOnly || bird.isFavorite)
        }

        if showFavoritesOnly {
            return filtered.sorted { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() }
        } else {
            return filtered
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredBirds.isEmpty {
                    if searchText.isEmpty && !showFavoritesOnly {
                        ContentUnavailableView(
                            "Your Habitat Awaits",
                            systemImage: "rainbow",
                            description: Text("Build your first memory by adding a new discovery to your habitat.")
                        )
                        .symbolRenderingMode(.multicolor)
                        .symbolEffect(.bounce, value: isBouncingRainbow)
                        .onAppear {
                            rainbowTimer?.invalidate()
                            rainbowTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                                isBouncingRainbow.toggle()
                            }
                        }
                        .onDisappear {
                            rainbowTimer?.invalidate()
                            rainbowTimer = nil
                        }
                    } else {
                        ContentUnavailableView(
                            "No Birds Found",
                            systemImage: "cloud.rain.fill",
                            description: Text(showFavoritesOnly ?
                                "Your habitat of favorites is ready to take flight." :
                                "Let's explore a different path in your habitat."
                            )
                        )
                        .symbolEffect(.bounce, value: isBouncingRain)
                        .onAppear {
                            rainTimer?.invalidate()
                            rainTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                                isBouncingRain.toggle()
                            }
                        }
                        .onDisappear {
                            rainTimer?.invalidate()
                            rainTimer = nil
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredBirds) { bird in
                                BirdCard(bird: bird)
                                    .onTapGesture {
                                        selectedBird = bird
                                    }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, 16)
            .navigationDestination(item: $selectedBird) { bird in
                BirdDetailView(bird: bird)
            }
            .listStyle(.plain)
            .navigationTitle("Habitat")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            sunBounce.toggle()
                            showFavoritesOnly.toggle()
                        } label: {
                            Image(systemName: showFavoritesOnly ? "sun.max.fill" : "sun.max")
                                .foregroundStyle(.yellow)
                                .symbolEffect(.bounce, value: sunBounce)
                        }

                        Button(action: {
                            showingAddSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Bird")
                            }
                            .foregroundStyle(.green)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Button(action: {
                            showingAddSheet = false
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                        }

                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Choose from Gallery")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.height(150)])
            }
            .sheet(isPresented: $showingImagePicker) {
                if let imageData = selectedImageData {
                    AddBirdView(initialImageData: imageData)
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(
                    capturedImageBase64: Binding(
                        get: { nil },
                        set: { newValue in
                            if let newValue = newValue,
                               let imageData = Data(base64Encoded: newValue),
                               let uiImage = UIImage(data: imageData),
                               let compressedData = uiImage.compressed() {
                                selectedImageData = compressedData
                                showingCamera = false
                                showingImagePicker = true
                            }
                        }
                    ),
                    showingCamera: $showingCamera,
                    showingLoadingScreen: .constant(false)
                )
            }
            .onChange(of: selectedItem) { newItem in
                if let item = newItem {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data),
                           let compressedData = uiImage.compressed() {
                            selectedImageData = compressedData
                            selectedItem = nil
                            showingAddSheet = false
                            showingImagePicker = true
                        }
                    }
                }
            }
        }
        .task {
            await premiumManager.checkPremiumStatus()
            
            if !hasSeenOnboarding {
                showOnboarding = true
            } else if !hasShownInitialPaywall && !premiumManager.isPremium {
                showPaywall = true
                hasShownInitialPaywall = true
            }
            
            if launchCount == 3 {
                await ratingManager.requestReview()
            }

            launchCount += 1
        }
        .fullScreenCover(isPresented: $showSpecialOffer) {
            SpecialOfferView()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled()
                .onDisappear {
                    hasSeenOnboarding = true
                    if !premiumManager.isPremium && !hasShownInitialPaywall {
                        showPaywall = true
                        hasShownInitialPaywall = true
                    }
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
                .onDisappear {
                    if !premiumManager.isPremium && !showSpecialOffer && launchCount % 2 == 1 {
                        showSpecialOffer = true
                    }
                }
                .interactiveDismissDisabled()
        }
    }

    private func deleteBird(_ bird: BirdEntity) {
        viewContext.delete(bird)

        do {
            try viewContext.save()
        } catch {
            print("Error deleting bird: \(error)")
        }
    }
}

#Preview {
    CollectionView()
}
