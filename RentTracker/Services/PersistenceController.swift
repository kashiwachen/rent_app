import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleProperty = Property(context: viewContext)
        sampleProperty.id = UUID()
        sampleProperty.name = "Sample Apartment"
        sampleProperty.address = "123 Main St"
        sampleProperty.propertyTypeRaw = PropertyType.residential.rawValue
        sampleProperty.createdAt = Date()
        
        let sampleTenant = Tenant(context: viewContext)
        sampleTenant.id = UUID()
        sampleTenant.name = "John Doe"
        sampleTenant.phone = "123-456-7890"
        sampleTenant.email = "john@example.com"
        sampleTenant.createdAt = Date()
        
        let sampleContract = Contract(context: viewContext)
        sampleContract.id = UUID()
        sampleContract.startDate = Date()
        sampleContract.endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        sampleContract.rentAmount = 2000
        sampleContract.paymentCycleRaw = PaymentCycle.monthly.rawValue
        sampleContract.depositAmount = 4000
        sampleContract.isActive = true
        sampleContract.createdAt = Date()
        sampleContract.property = sampleProperty
        sampleContract.tenant = sampleTenant
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RentTrackerModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable file protection for data security
        container.persistentStoreDescriptions.first?.setOption(
            FileProtectionType.complete as NSObject,
            forKey: NSPersistentStoreFileProtectionKey
        )
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Failed to save context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func createBackup() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsPath.appendingPathComponent("RentTracker_Backup_\(Date().timeIntervalSince1970).sqlite")
        
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            return nil
        }
        
        do {
            try FileManager.default.copyItem(at: storeURL, to: backupURL)
            return backupURL
        } catch {
            print("Failed to create backup: \(error)")
            return nil
        }
    }
    
    func restoreFromBackup(_ backupURL: URL) -> Bool {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            return false
        }
        
        do {
            // Remove current store
            try container.persistentStoreCoordinator.destroyPersistentStore(
                at: storeURL,
                ofType: NSSQLiteStoreType,
                options: nil
            )
            
            // Copy backup to store location
            try FileManager.default.copyItem(at: backupURL, to: storeURL)
            
            // Reload store
            try container.persistentStoreCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: nil
            )
            
            return true
        } catch {
            print("Failed to restore backup: \(error)")
            return false
        }
    }
}
