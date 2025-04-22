//
//  AppCOnfig.swift
//  ChatApp1
//
//  Created by Umar Farooq on 21/04/25.
//

import Foundation

struct AppConfigModel: Codable {
    let baseURL: String
 
}

final class AppConfig {
    static let shared: AppConfigModel = {
        do {
            guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist") else {
                throw AppConfigError.configFileNotFound
            }
            let data = try Data(contentsOf: url)
            return try PropertyListDecoder().decode(AppConfigModel.self, from: data)
        } catch {
            fatalError("AppConfig initialization failed: \(error)")
        }
    }()
}
