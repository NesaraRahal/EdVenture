import Foundation
import CoreData
import CryptoKit

final class EVCoreDataStack {
    static let shared = EVCoreDataStack()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "EVCoreDataModel", managedObjectModel: model)

        let url = Self.storeURL
        print("📊 Core Data store URL: \(url.path)")
        
        let storeDescription = NSPersistentStoreDescription(url: url)
        storeDescription.type = NSSQLiteStoreType
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores { _, error in
            if let error {
                print("❌ Failed to load Core Data store: \(error.localizedDescription)")
                assertionFailure("Failed to load Core Data store: \(error.localizedDescription)")
            } else {
                print("✅ Core Data store loaded successfully")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.name = "EVCoreDataViewContext"
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.name = "EVCoreDataBackgroundContext"
        return context
    }

    func saveContext() {
        let context = container.viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
            print("✅ Core Data context saved")
        } catch {
            print("❌ Failed to save Core Data context: \(error.localizedDescription)")
            assertionFailure("Failed to save Core Data context: \(error.localizedDescription)")
        }
    }

    private static var storeURL: URL {
        let fileManager = FileManager.default
        let baseURL = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let folderURL = baseURL?.appendingPathComponent("EdVenture", isDirectory: true)
        if let folderURL {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                print("📁 Core Data folder created: \(folderURL.path)")
            } catch {
                print("⚠️ Failed to create Core Data folder: \(error)")
            }
            return folderURL.appendingPathComponent("EVCoreData.sqlite")
        }

        return fileManager.temporaryDirectory.appendingPathComponent("EVCoreData.sqlite")
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = [
            makeDiscoveryScanEntity(),
            makeNotificationEntity(),
            makeQuizSessionEntity()
        ]
        return model
    }

    private static func makeDiscoveryScanEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "EVDiscoveryScanRecord"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            makeAttribute(name: "id", type: .stringAttributeType),
            makeAttribute(name: "fingerprint", type: .stringAttributeType),
            makeAttribute(name: "title", type: .stringAttributeType),
            makeAttribute(name: "category", type: .stringAttributeType),
            makeAttribute(name: "contentData", type: .binaryDataAttributeType),
            makeAttribute(name: "createdAt", type: .dateAttributeType)
        ]
        return entity
    }

    private static func makeNotificationEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "EVNotificationRecord"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            makeAttribute(name: "id", type: .stringAttributeType),
            makeAttribute(name: "title", type: .stringAttributeType),
            makeAttribute(name: "bodyText", type: .stringAttributeType),
            makeAttribute(name: "type", type: .stringAttributeType),
            makeAttribute(name: "timestamp", type: .dateAttributeType),
            makeAttribute(name: "isRead", type: .booleanAttributeType)
        ]
        return entity
    }

    private static func makeQuizSessionEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "EVQuizSessionRecord"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            makeAttribute(name: "cacheKey", type: .stringAttributeType),
            makeAttribute(name: "userId", type: .stringAttributeType),
            makeAttribute(name: "lessonId", type: .stringAttributeType),
            makeAttribute(name: "level", type: .integer16AttributeType),
            makeAttribute(name: "sessionData", type: .binaryDataAttributeType),
            makeAttribute(name: "updatedAt", type: .dateAttributeType)
        ]
        return entity
    }

    private static func makeAttribute(name: String, type: NSAttributeType) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = false

        if type == .binaryDataAttributeType {
            attribute.allowsExternalBinaryDataStorage = true
        }

        return attribute
    }
}

private enum EVCoreDataEntityNames {
    static let discoveryScan = "EVDiscoveryScanRecord"
    static let notification = "EVNotificationRecord"
    static let quizSession = "EVQuizSessionRecord"
}

private extension NSManagedObjectContext {
    func fetchObjects(entityName: String, sortDescriptors: [NSSortDescriptor] = [], predicate: NSPredicate? = nil, fetchLimit: Int = 0) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        if fetchLimit > 0 {
            request.fetchLimit = fetchLimit
        }
        return try fetch(request)
    }
}

private enum EVCoreDataCoding {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .deferredToDate
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate
        return decoder
    }()
}

final class EVDiscoveryHistoryStore {
    static let shared = EVDiscoveryHistoryStore()

    private let stack = EVCoreDataStack.shared

    private init() {}

    func loadHistory(limit: Int = 50) -> [EducationalContent] {
        let context = stack.viewContext
        do {
            let objects = try context.fetchObjects(
                entityName: EVCoreDataEntityNames.discoveryScan,
                sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)],
                fetchLimit: max(1, limit)
            )

            return objects.compactMap { object in
                guard let data = object.value(forKey: "contentData") as? Data else { return nil }
                return try? EVCoreDataCoding.decoder.decode(EducationalContent.self, from: data)
            }
        } catch {
            return []
        }
    }

    func saveHistory(_ history: [EducationalContent], limit: Int = 50) {
        let context = stack.newBackgroundContext()
        context.performAndWait {
            do {
                let existing = try context.fetchObjects(entityName: EVCoreDataEntityNames.discoveryScan)
                existing.forEach(context.delete)

                for content in history.prefix(max(1, limit)) {
                    guard let entity = NSEntityDescription.entity(forEntityName: EVCoreDataEntityNames.discoveryScan, in: context),
                          let encoded = try? EVCoreDataCoding.encoder.encode(content) else {
                        continue
                    }

                    let object = NSManagedObject(entity: entity, insertInto: context)
                    object.setValue(content.id, forKey: "id")
                    object.setValue(scanFingerprint(for: content), forKey: "fingerprint")
                    object.setValue(content.title, forKey: "title")
                    object.setValue(content.category, forKey: "category")
                    object.setValue(encoded, forKey: "contentData")
                    object.setValue(content.generatedAt, forKey: "createdAt")
                }

                if context.hasChanges {
                    try context.save()
                }
            } catch {
                context.rollback()
            }
        }
    }

    private func scanFingerprint(for content: EducationalContent) -> String {
        let normalized = content.extractedText
            .lowercased()
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let data = Data(normalized.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

final class EVNotificationsCoreDataStore {
    static let shared = EVNotificationsCoreDataStore()

    private let stack = EVCoreDataStack.shared

    private init() {}

    func loadNotifications() -> [EVNotification] {
        let context = stack.viewContext
        do {
            let objects = try context.fetchObjects(
                entityName: EVCoreDataEntityNames.notification,
                sortDescriptors: [NSSortDescriptor(key: "timestamp", ascending: false)]
            )

            return objects.compactMap { object in
                guard
                    let id = object.value(forKey: "id") as? String,
                    let title = object.value(forKey: "title") as? String,
                    let bodyText = object.value(forKey: "bodyText") as? String,
                    let typeString = object.value(forKey: "type") as? String,
                    let timestamp = object.value(forKey: "timestamp") as? Date
                else {
                    return nil
                }

                return EVNotification(
                    id: id,
                    title: title,
                    description: bodyText,
                    type: NotificationType(rawValue: typeString) ?? .achievement,
                    timestamp: timestamp,
                    isRead: object.value(forKey: "isRead") as? Bool ?? false
                )
            }
        } catch {
            return []
        }
    }

    func saveNotifications(_ notifications: [EVNotification]) {
        let context = stack.newBackgroundContext()
        context.performAndWait {
            do {
                let existing = try context.fetchObjects(entityName: EVCoreDataEntityNames.notification)
                existing.forEach(context.delete)

                for notification in notifications {
                    guard let entity = NSEntityDescription.entity(forEntityName: EVCoreDataEntityNames.notification, in: context) else {
                        continue
                    }

                    let object = NSManagedObject(entity: entity, insertInto: context)
                    object.setValue(notification.id, forKey: "id")
                    object.setValue(notification.title, forKey: "title")
                    object.setValue(notification.description, forKey: "bodyText")
                    object.setValue(notification.type.rawValue, forKey: "type")
                    object.setValue(notification.timestamp, forKey: "timestamp")
                    object.setValue(notification.isRead, forKey: "isRead")
                }

                if context.hasChanges {
                    try context.save()
                    print("✅ Saved \(notifications.count) notifications to Core Data")
                } else {
                    print("ℹ️ No changes to save for notifications")
                }
            } catch {
                print("❌ Failed to save notifications: \(error)")
                context.rollback()
            }
        }
    }
}

final class EVQuizSessionCacheStore {
    static let shared = EVQuizSessionCacheStore()

    private let stack = EVCoreDataStack.shared

    private init() {}

    func loadSession(userId: String, lessonId: String, level: Int) -> EVQuizSessionState? {
        let cacheKey = makeCacheKey(userId: userId, lessonId: lessonId, level: level)
        let context = stack.viewContext

        do {
            let predicate = NSPredicate(format: "cacheKey == %@", cacheKey)
            guard let object = try context.fetchObjects(
                entityName: EVCoreDataEntityNames.quizSession,
                sortDescriptors: [NSSortDescriptor(key: "updatedAt", ascending: false)],
                predicate: predicate,
                fetchLimit: 1
            ).first,
            let data = object.value(forKey: "sessionData") as? Data else {
                return nil
            }

            return try EVCoreDataCoding.decoder.decode(EVQuizSessionState.self, from: data)
        } catch {
            return nil
        }
    }

    func saveSession(userId: String, session: EVQuizSessionState) {
        let cacheKey = makeCacheKey(userId: userId, lessonId: session.lessonId, level: session.level)
        let context = stack.newBackgroundContext()

        context.performAndWait {
            do {
                let predicate = NSPredicate(format: "cacheKey == %@", cacheKey)
                let existing = try context.fetchObjects(entityName: EVCoreDataEntityNames.quizSession, predicate: predicate)
                existing.forEach(context.delete)

                guard let entity = NSEntityDescription.entity(forEntityName: EVCoreDataEntityNames.quizSession, in: context),
                      let data = try? EVCoreDataCoding.encoder.encode(session) else {
                    return
                }

                let object = NSManagedObject(entity: entity, insertInto: context)
                object.setValue(cacheKey, forKey: "cacheKey")
                object.setValue(userId, forKey: "userId")
                object.setValue(session.lessonId, forKey: "lessonId")
                object.setValue(Int16(max(1, session.level)), forKey: "level")
                object.setValue(data, forKey: "sessionData")
                object.setValue(Date(), forKey: "updatedAt")

                if context.hasChanges {
                    try context.save()
                }
            } catch {
                context.rollback()
            }
        }
    }

    private func makeCacheKey(userId: String, lessonId: String, level: Int) -> String {
        "\(userId)::\(lessonId)::L\(String(format: "%02d", max(1, level)))"
    }
}
