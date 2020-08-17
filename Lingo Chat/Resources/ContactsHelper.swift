//
//  ContactsHelper.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-15.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import Contacts

final class ContactsHelper {
    
    public static var store = CNContactStore()
    
    public static func fetchContacts() -> [String] {
        var emails: [String] =  []
        store.requestAccess(for: .contacts) { (granted, error) in
            guard error == nil else {
                print("Contacts not available")
                return
            }
            let keys = [CNContactEmailAddressesKey]
            let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
            if granted {
                do {
                    try store.enumerateContacts(with: request) { (contact, stopEnumerationPointer) in
                        for email in contact.emailAddresses {
                            emails.append(email.value as String)
                        }
                    }
                }
                catch {
                    print("Error while fetching contact")
                }
                print(emails)
             }
            else {
                print("Contacts access permission denied!")
            }
            
        }
        return emails
    }
}
