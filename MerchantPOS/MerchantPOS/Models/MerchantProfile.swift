//
//  MerchantProfile.swift
//  MerchantPOS
//

import Foundation

struct MerchantProfile: Codable {
    let merchantName: String
    let gatewayId: String
    let contactDetails: ContactDetails?
    let processors: [ProcessorInfo]?

    struct ContactDetails: Codable {
        let firstName: String?
        let lastName: String?
        let email: String?
        let company: String?
        let address: String?
        let city: String?
        let state: String?
        let zip: String?
        let country: String?
        let phoneNumber: String?
    }

    struct ProcessorInfo: Codable {
        let name: String?
    }

    var displayName: String {
        if let contact = contactDetails, let company = contact.company, !company.isEmpty {
            return company
        }
        return merchantName
    }

    var contactName: String? {
        guard let contact = contactDetails else { return nil }
        let first = contact.firstName ?? ""
        let last = contact.lastName ?? ""
        let fullName = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return fullName.isEmpty ? nil : fullName
    }

    var formattedAddress: String? {
        guard let contact = contactDetails else { return nil }
        var parts: [String] = []
        if let address = contact.address, !address.isEmpty {
            parts.append(address)
        }
        var cityStateZip: [String] = []
        if let city = contact.city, !city.isEmpty {
            cityStateZip.append(city)
        }
        if let state = contact.state, !state.isEmpty {
            cityStateZip.append(state)
        }
        if let zip = contact.zip, !zip.isEmpty {
            cityStateZip.append(zip)
        }
        if !cityStateZip.isEmpty {
            parts.append(cityStateZip.joined(separator: ", "))
        }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }
}
