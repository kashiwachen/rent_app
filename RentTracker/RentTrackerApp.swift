import SwiftUI
import CoreData
import UserNotifications

@main
struct RentTrackerApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        setupNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(NotificationService.shared)
        }
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
        
        // Set up notification categories
        let markPaidAction = UNNotificationAction(
            identifier: "MARK_PAID",
            title: NSLocalizedString("Mark Paid", comment: "Mark payment as paid"),
            options: [.foreground]
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: NSLocalizedString("Remind Later", comment: "Remind later"),
            options: []
        )
        
        let rentDueCategory = UNNotificationCategory(
            identifier: "RENT_DUE",
            actions: [markPaidAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        let contactTenantAction = UNNotificationAction(
            identifier: "CONTACT_TENANT",
            title: NSLocalizedString("Contact Tenant", comment: "Contact tenant"),
            options: [.foreground]
        )
        
        let overdueCategory = UNNotificationCategory(
            identifier: "OVERDUE",
            actions: [markPaidAction, contactTenantAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([rentDueCategory, overdueCategory])
    }
}
