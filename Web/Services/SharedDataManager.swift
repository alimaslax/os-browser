import Foundation
import os.log

/// Manages data sharing across the App Group container.
final class SharedDataManager {
    static let shared = SharedDataManager()
    
    private let groupIdentifier = "group.com.rahyan.dev.shared"
    private let userDefaults: UserDefaults?
    
    private init() {
        self.userDefaults = UserDefaults(suiteName: groupIdentifier)
    }
    
    /// Checks if the App Group container is accessible.
    var isAccessible: Bool {
        guard let defaults = userDefaults else { return false }
        let testKey = "_access_test_key"
        let testValue = Date().timeIntervalSince1970
        defaults.set(testValue, forKey: testKey)
        defaults.synchronize()
        return defaults.double(forKey: testKey) == testValue
    }
    
    /// Saves a Codable object to the shared container.
    func save<T: Codable>(_ object: T, forKey key: String) {
        guard let defaults = userDefaults else {
            AppLog.error("SharedDataManager: Could not access UserDefaults for group \(groupIdentifier)")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(object)
            defaults.set(data, forKey: key)
            defaults.synchronize()
        } catch {
            AppLog.error("SharedDataManager: Failed to encode object for key \(key): \(error.localizedDescription)")
        }
    }
    
    /// Retrieves a Codable object from the shared container.
    func load<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: key) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            AppLog.error("SharedDataManager: Failed to decode object for key \(key): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Removes an item from the shared container.
    func remove(forKey key: String) {
        userDefaults?.removeObject(forKey: key)
        userDefaults?.synchronize()
    }
}
