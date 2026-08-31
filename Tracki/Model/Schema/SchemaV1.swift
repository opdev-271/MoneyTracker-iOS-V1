//
//  SchemaV1.swift
//  Tracki
//

import SwiftData

/// First versioned schema. Future schema changes should add `SchemaV2` etc.
/// (typically nesting frozen copies of the changed model types) and a real
/// `MigrationStage` in `MoneyTrackerMigrationPlan.stages` — never rely on
/// destructive migration for a finance app (see IOS_HANDOFF A11.3).
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Profile.self, Account.self, Category.self, Transaction.self, SavingsEnvelope.self]
    }
}

enum MoneyTrackerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
