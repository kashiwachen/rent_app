import Foundation
import UserNotifications
import CoreData

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                } else if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
    
    func scheduleRentDueNotification(for paymentSchedule: PaymentSchedule) {
        guard let contract = paymentSchedule.contract,
              let property = contract.property,
              let tenant = contract.tenant else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Rent Due", comment: "Rent due notification title")
        content.body = String(format: NSLocalizedString("Rent of ¥%.2f is due for %@ (Tenant: %@)", comment: "Rent due notification body"), 
                             paymentSchedule.amount as NSDecimalNumber, 
                             property.name ?? "", 
                             tenant.name ?? "")
        content.sound = .default
        content.categoryIdentifier = "RENT_DUE"
        content.userInfo = [
            "paymentScheduleID": paymentSchedule.id?.uuidString ?? "",
            "contractID": contract.id?.uuidString ?? "",
            "propertyID": property.id?.uuidString ?? ""
        ]
        
        // Schedule notifications: 3 days before, 1 day before, and on due date
        let intervals = [-3, -1, 0]
        
        for interval in intervals {
            guard let triggerDate = Calendar.current.date(byAdding: .day, value: interval, to: paymentSchedule.dueDate) else { continue }
            
            let triggerDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
            
            let identifier = "\(paymentSchedule.id?.uuidString ?? "")_\(interval)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }
    
    func scheduleOverdueNotification(for paymentSchedule: PaymentSchedule) {
        guard let contract = paymentSchedule.contract,
              let property = contract.property,
              let tenant = contract.tenant else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Payment Overdue", comment: "Payment overdue notification title")
        content.body = String(format: NSLocalizedString("Payment of ¥%.2f is overdue for %@ (Tenant: %@)", comment: "Payment overdue notification body"), 
                             paymentSchedule.amount as NSDecimalNumber, 
                             property.name ?? "", 
                             tenant.name ?? "")
        content.sound = .default
        content.categoryIdentifier = "OVERDUE"
        content.userInfo = [
            "paymentScheduleID": paymentSchedule.id?.uuidString ?? "",
            "contractID": contract.id?.uuidString ?? "",
            "propertyID": property.id?.uuidString ?? ""
        ]
        
        // Schedule overdue notifications: 1, 7, and 30 days after due date
        let intervals = [1, 7, 30]
        
        for interval in intervals {
            guard let triggerDate = Calendar.current.date(byAdding: .day, value: interval, to: paymentSchedule.dueDate) else { continue }
            
            let triggerDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
            
            let identifier = "overdue_\(paymentSchedule.id?.uuidString ?? "")_\(interval)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule overdue notification: \(error)")
                }
            }
        }
    }
    
    func cancelNotification(for paymentScheduleID: String) {
        let identifiers = [
            "\(paymentScheduleID)_-3",
            "\(paymentScheduleID)_-1",
            "\(paymentScheduleID)_0",
            "overdue_\(paymentScheduleID)_1",
            "overdue_\(paymentScheduleID)_7",
            "overdue_\(paymentScheduleID)_30"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse, context: NSManagedObjectContext) {
        let userInfo = response.notification.request.content.userInfo
        guard let paymentScheduleID = userInfo["paymentScheduleID"] as? String,
              let uuid = UUID(uuidString: paymentScheduleID) else { return }
        
        let request: NSFetchRequest<PaymentSchedule> = PaymentSchedule.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        
        do {
            let schedules = try context.fetch(request)
            guard let schedule = schedules.first else { return }
            
            switch response.actionIdentifier {
            case "MARK_PAID":
                schedule.markAsPaid()
                cancelNotification(for: paymentScheduleID)
                try context.save()
                
            case "REMIND_LATER":
                // Reschedule for 1 hour later
                scheduleReminder(for: schedule, in: 3600) // 1 hour
                
            case "CONTACT_TENANT":
                // Open phone app or message app (handled by UI)
                break
                
            default:
                break
            }
        } catch {
            print("Failed to handle notification response: \(error)")
        }
    }
    
    private func scheduleReminder(for paymentSchedule: PaymentSchedule, in seconds: TimeInterval) {
        guard let contract = paymentSchedule.contract,
              let property = contract.property,
              let tenant = contract.tenant else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Rent Reminder", comment: "Rent reminder notification title")
        content.body = String(format: NSLocalizedString("Don't forget: Rent of ¥%.2f is due for %@ (Tenant: %@)", comment: "Rent reminder notification body"), 
                             paymentSchedule.amount as NSDecimalNumber, 
                             property.name ?? "", 
                             tenant.name ?? "")
        content.sound = .default
        content.categoryIdentifier = "RENT_DUE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let identifier = "reminder_\(paymentSchedule.id?.uuidString ?? "")_\(Int(Date().timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule reminder: \(error)")
            }
        }
    }
}
