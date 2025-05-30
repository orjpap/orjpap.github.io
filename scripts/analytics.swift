#!/usr/bin/swift

import Foundation
import Security

struct Visitor: Codable {
    let url: String
    let referrer: String
    let timestamp: String
    let userAgent: String?

    enum CodingKeys: String, CodingKey {
        case url
        case referrer
        case timestamp
        case userAgent = "user_agent"
    }
}

func fetchData(endpoint: String, apiKey: String, getHeader: String) -> [Visitor]? {
    guard let url = URL(string: endpoint) else {
        print("Invalid URL")
        return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(apiKey, forHTTPHeaderField: getHeader)

    let semaphore = DispatchSemaphore(value: 0)
    var visitors: [Visitor]?

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }

        if let error = error {
            print("Error: \(error)")
            return
        }

        guard let data = data else {
            print("No data received")
            return
        }

        do {
            visitors = try JSONDecoder().decode([Visitor].self, from: data)
        } catch {
            print("Error decoding JSON: \(error)")
            print("Payload was: \(String(data: data, encoding: .utf8)!)")
        }
    }

    task.resume()
    semaphore.wait()
    return visitors
}

func analyzeVisitors(_ visitors: [Visitor]) {
    let calendar = Calendar.current
    let now = Date()
    let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
    let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
    let yearAgo = calendar.date(byAdding: .year, value: -1, to: now)!

    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    // Count visitors by time period
    let weeklyVisitors = visitors.filter { visitor in
        guard let date = dateFormatter.date(from: visitor.timestamp) else {
            print("Warning: Could not parse date from timestamp: \(visitor.timestamp)")
            return false
        }
        return date >= weekAgo
    }.count

    let monthlyVisitors = visitors.filter { visitor in
        guard let date = dateFormatter.date(from: visitor.timestamp) else {
            print("Warning: Could not parse date from timestamp: \(visitor.timestamp)")
            return false
        }
        return date >= monthAgo
    }.count

    let yearlyVisitors = visitors.filter { visitor in
        guard let date = dateFormatter.date(from: visitor.timestamp) else {
            print("Warning: Could not parse date from timestamp: \(visitor.timestamp)")
            return false
        }
        return date >= yearAgo
    }.count

    // Analyze referrers
    var referrerCounts: [String: Int] = [:]
    for visitor in visitors {
        let referrer = visitor.referrer.isEmpty ? "Direct" : visitor.referrer
        referrerCounts[referrer, default: 0] += 1
    }

    // Analyze most visited posts
    var postCounts: [String: Int] = [:]
    for visitor in visitors {
        if let cleanURL = URL(string: visitor.url)?.path {
            postCounts[cleanURL, default: 0] += 1
        } else {
            postCounts[visitor.url, default: 0] += 1  // fallback in case URL parsing fails
        }
    }

    let maxReferrerVisibleLength = 40
    let paddedReferrerLength = 43  // make this the same for all rows

    // Print results
    print("\n=== Visitor Statistics ===")
    let totalString = "Total".padding(toLength: paddedReferrerLength, withPad: " ", startingAt: 0)
    print("\(totalString): \(visitors.count) visitors")

    let lastSevenString = "Last 7 days".padding(
        toLength: paddedReferrerLength, withPad: " ", startingAt: 0)
    print("\(lastSevenString): \(weeklyVisitors) visitors")

    let lastThirtyString = "Last 30 days".padding(
        toLength: paddedReferrerLength, withPad: " ", startingAt: 0)
    print("\(lastThirtyString): \(monthlyVisitors) visitors")

    let lastYearString = "Last Year".padding(
        toLength: paddedReferrerLength, withPad: " ", startingAt: 0)
    print("\(lastYearString): \(yearlyVisitors) visitors")

    print("\n=== Most Visited Posts ===")
    let sortedPosts = postCounts.sorted { $0.value > $1.value }

    for (url, count) in sortedPosts {
        let filteredUrl = url
        let displayUrl = filteredUrl.split(separator: "/").last ?? "Home Page"
        let padded = displayUrl.padding(toLength: paddedReferrerLength, withPad: " ", startingAt: 0)
        let countStr = String(format: "%2d", count)
        print("\(padded): \(countStr) visits")
    }

    print("\n=== Top Referrers ===")
    let sortedReferrers = referrerCounts.sorted { $0.value > $1.value }

    for (referrer, count) in sortedReferrers {
        let displayReferrer = truncatedAndPadded(
            referrer, maxLength: maxReferrerVisibleLength, padTo: paddedReferrerLength)
        let countStr = String(format: "%2d", count)
        print("\(displayReferrer): \(countStr) visitors")
    }
}

func truncatedAndPadded(_ string: String, maxLength: Int, padTo: Int) -> String {
    let trimmed: String
    if string.count > maxLength {
        let index = string.index(string.startIndex, offsetBy: maxLength - 3)
        trimmed = String(string[..<index]) + "..."
    } else {
        trimmed = string
    }
    return trimmed.padding(toLength: padTo, withPad: " ", startingAt: 0)
}

func truncatedAndPaddedFromStart(_ string: String, maxLength: Int, padTo: Int) -> String {
    let trimmed: String
    if string.count > maxLength {
        let startIdx = string.index(string.endIndex, offsetBy: -(maxLength - 3))
        trimmed = "..." + String(string[startIdx...])
    } else {
        trimmed = string
    }
    return trimmed.padding(toLength: padTo, withPad: " ", startingAt: 0)
}

func retrieveFromKeychain(key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: key,
        kSecAttrAccount as String: keyChainUser,
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status == errSecSuccess, let data = item as? Data,
        let password = String(data: data, encoding: .utf8)
    {
        return password
    } else {
        print("Error retrieving password: \(status)")
    }

    return nil
}

// Main execution
let endpoint = "https://orjpap-bloganalyticsserver.web.val.run/analytics"
let keyChainAPIKey = "ANALYTICS_GET_KEY"
let keyChainGetHeaderKey = "ANALYTICS_GET_HEADER"
let keyChainUser = "orjpap"

guard let apiKey = retrieveFromKeychain(key: keyChainAPIKey) else {
    fatalError("No API key \(keyChainAPIKey) found in keychain")
}

guard let getHeader = retrieveFromKeychain(key: keyChainGetHeaderKey) else {
    fatalError("No GET Header \(keyChainGetHeaderKey) found in keychain")
}

if let visitors = fetchData(endpoint: endpoint, apiKey: apiKey, getHeader: getHeader) {
    analyzeVisitors(visitors)
} else {
    print("Failed to fetch or analyze visitor data")
}
