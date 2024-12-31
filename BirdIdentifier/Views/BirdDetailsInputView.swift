import SwiftUI

struct BirdDetailsInputView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var location = ""
    @State private var photoDate = Date()
    let image: UIImage
    let onComplete: (String, Date) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Help us identify the bird better")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Where was this photo taken?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g. Central Park, New York", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When was this photo taken?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $photoDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                Button {
                    onComplete(location, photoDate)
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(location.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(location.isEmpty)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
} 