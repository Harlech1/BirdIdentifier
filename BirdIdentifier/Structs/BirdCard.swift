//
//  BirdCard.swift
//  BirdIdentifier
//
//  Created by Türker Kızılcık on 28.12.2024.
//

import SwiftUI

struct BirdCard: View {
    let bird: BirdEntity

    var body: some View {
        HStack(spacing: 16) {
            if let imageData = bird.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(bird.commonName ?? "Undefined")
                    .font(.headline)
                    .lineLimit(1)

                Text(bird.scientificName ?? "Undefined")
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if let date = bird.dateAdded {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.blue)
                            .font(.system(size: 12))

                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
