import SwiftUI
import RevenueCat
import RevenueCatUI
import SafariServices

struct CustomPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showDismissButton = false
    @State private var isTrialEnabled = true
    @State private var currentOffering: String = "Trial"
    @State private var packages: [Package] = []
    @State private var selectedPackage: Package?
    @State private var showingPrivacy = false
    @State private var showingTerms = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Text("Unlock Premium Features")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "sparkles.rectangle.stack",
                                 title: "AI Bird Scanner", 
                                 description: "Identify any bird instantly")
                        
                        FeatureRow(icon: "book.fill", 
                                 title: "Bird Stories", 
                                 description: "Learn about their habitats & behaviors")
                        
                        FeatureRow(icon: "map.fill", 
                                 title: "Personal Bird Journal", 
                                 description: "Save where you spotted each bird")
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal)
                
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Free Trial")
                            .font(.headline)
                        Text("Not sure yet? Try first.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isTrialEnabled)
                        .labelsHidden()
                        .onChange(of: isTrialEnabled) { newValue in
                            currentOffering = newValue ? "Trial" : "Premium"
                            loadPackages()
                        }
                        .tint(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isTrialEnabled ? Color.green : Color(.systemGray5), lineWidth: isTrialEnabled ? 5 : 5)
                )
                .cornerRadius(12)
                .padding(.horizontal)
                
                VStack(spacing: 16) {
                    ForEach(packages, id: \.identifier) { package in
                        PurchaseButton(package: package, 
                                     isSelected: selectedPackage?.identifier == package.identifier,
                                     isTrialEnabled: isTrialEnabled) {
                            selectedPackage = package
                        }
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    if let package = selectedPackage {
                        Task {
                            do {
                                let result = try await Purchases.shared.purchase(package: package)
                                print("Purchase completed: \(result.customerInfo.entitlements)")
                            } catch {
                                print("Purchase failed: \(error)")
                            }
                        }
                    }
                }) {
                    Text(isTrialEnabled ? "START MY FREE 3 DAYS" : "CONTINUE")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPackage != nil ? Color.green : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(selectedPackage == nil)
                .padding(.horizontal)

                HStack(spacing: 4) {
                    Button("Restore") {
                        Task {
                            do {
                                let customerInfo = try await Purchases.shared.restorePurchases()
                                print("Purchases restored: \(customerInfo)")
                            } catch {
                                print("Restore failed: \(error)")
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Button("Privacy") {
                        showingPrivacy = true
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Button("Terms") {
                        showingTerms = true
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            if showDismissButton {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .opacity(showDismissButton ? 1 : 0)
                .animation(.easeIn, value: showDismissButton)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.1),
                    Color.green.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            loadPackages()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showDismissButton = true
                }
            }
        }
        .sheet(isPresented: $showingPrivacy) {
            SafariView(url: URL(string: "https://turkerkizilcik.com/birdid/privacy-policy.html")!)
        }
        .sheet(isPresented: $showingTerms) {
            SafariView(url: URL(string: "https://turkerkizilcik.com/birdid/terms-of-use.html")!)
        }
    }
    
    private func loadPackages() {
        Task {
            do {
                let offerings = try await Purchases.shared.offerings()
                let offering = offerings.offering(identifier: currentOffering)
                
                DispatchQueue.main.async {
                    if let offering = offering {
                        let currentPeriodUnit = selectedPackage?.storeProduct.subscriptionPeriod?.unit
                        
                        self.packages = offering.availablePackages.sorted { first, second in
                            let firstIsWeekly = first.storeProduct.subscriptionPeriod?.unit == .week
                            let secondIsWeekly = second.storeProduct.subscriptionPeriod?.unit == .week
                            return firstIsWeekly && !secondIsWeekly
                        }
                        
                        if let currentPeriodUnit = currentPeriodUnit {
                            selectedPackage = packages.first { package in
                                package.storeProduct.subscriptionPeriod?.unit == currentPeriodUnit
                            }
                        } else {
                            selectedPackage = packages.first { package in
                                if let period = package.storeProduct.subscriptionPeriod {
                                    return period.unit == .week && period.value == 1
                                }
                                return false
                            }
                        }
                    } else {
                        print("No offering found for identifier: \(currentOffering)")
                    }
                }
            } catch {
                print("Error loading packages: \(error)")
            }
        }
    }
}

struct PurchaseButton: View {
    let package: Package
    let isSelected: Bool
    let isTrialEnabled: Bool
    let action: () -> Void
    
    private var priceText: String {
        "\(package.storeProduct.localizedPriceString)/\(package.storeProduct.subscriptionPeriod?.unit.shortTitle ?? "")"
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(package.storeProduct.subscriptionPeriod?.periodTitle ?? "")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isTrialEnabled {
                            Text("Free for 3 days, then \(priceText)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text(priceText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .green : .secondary)
                        .font(.title3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.green : Color(.systemGray5), lineWidth: isSelected ? 5 : 5)
                )
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

private extension SubscriptionPeriod {
    var periodTitle: String {
        switch (unit, value) {
        case (.week, 1): return "Weekly Premium"
        case (.year, 1): return "Annual Premium"
        default: return "\(value) \(unit)"
        }
    }
}

private extension SubscriptionPeriod.Unit {
    var shortTitle: String {
        switch self {
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "period"
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CustomPaywallView()
} 
