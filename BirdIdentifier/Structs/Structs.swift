//
//  Structs.swift
//  BirdIdentifier
//
//  Created by Türker Kızılcık on 28.12.2024.
//

import Foundation
import UIKit

struct Bird: Identifiable, Codable {
    var id: UUID
    let commonName: String
    let scientificName: String
    let imageData: Data

    init(id: UUID = UUID(), commonName: String, scientificName: String, imageData: Data) {
        self.id = id
        self.commonName = commonName
        self.scientificName = scientificName
        if let uiImage = UIImage(data: imageData),
           let compressedData = uiImage.jpegData(compressionQuality: 0.7) {
            self.imageData = compressedData
        } else {
            self.imageData = imageData
        }
    }
}
