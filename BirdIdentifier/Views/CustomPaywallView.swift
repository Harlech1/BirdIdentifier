import SwiftUI
import RevenueCat
import RevenueCatUI
import SafariServices

struct CustomPaywallView: View {
    @State private var isTrialEnabled = true
    @State private var currentOffering: String = "Trial"
    @State private var packages: [Package] = []
    @State private var selectedPackage: Package?
    @State private var showingPrivacy = false
    @State private var showingTerms = false
    
    var body: some View {
        VStack(spacing: 20) {
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
                        selectedPackage = nil
                    }
                    .tint(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isTrialEnabled ? Color.blue : Color(.systemGray5), lineWidth: isTrialEnabled ? 5 : 5)
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
                    .background(selectedPackage != nil ? Color.blue : Color.gray)
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
        .onAppear {
            loadPackages()
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
                        self.packages = offering.availablePackages.sorted { first, second in
                            let firstIsWeekly = first.storeProduct.subscriptionPeriod?.unit == .week
                            let secondIsWeekly = second.storeProduct.subscriptionPeriod?.unit == .week
                            return firstIsWeekly && !secondIsWeekly
                        }
                        
                        if selectedPackage == nil {
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
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(package.storeProduct.subscriptionPeriod?.periodTitle ?? "")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isTrialEnabled {
                            Text("Free for 3 days, then \(package.storeProduct.localizedPriceString)/\(package.storeProduct.subscriptionPeriod?.unit.shortTitle ?? "")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text(package.storeProduct.localizedPriceString)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .secondary)
                        .font(.title3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color(.systemGray5), lineWidth: isSelected ? 5 : 5)
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

#Preview {
    CustomPaywallView()
} 
