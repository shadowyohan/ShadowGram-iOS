import Foundation
import TelegramCore

// Snapshot model for the local anti-delete / anti-edit archive. This mirrors AyuGram Desktop's
// DeletedMessage / EditedMessage entities (a full message snapshot kept in a local database so
// deleted messages and edit revisions remain viewable). The persistence layer (SQLite/GRDB) and
// the capture pipeline (subscribing to postbox message deletions/edits) are the next step — see
// SHADOWGRAM.md §5. This type is the stable on-disk shape those will read and write.

public struct ShadowgramStoredMessage: Codable, Equatable {
    public enum Kind: Int32, Codable {
        case deleted = 0
        case editRevision = 1
    }

    public var kind: Kind
    public var accountPeerId: Int64
    public var dialogPeerId: Int64
    public var topicId: Int64
    public var messageId: Int32
    public var groupedId: Int64?
    public var fromPeerId: Int64?
    public var text: String
    public var entitiesData: Data?
    public var mediaPath: String?
    public var thumbnailPath: String?
    public var date: Int32
    public var capturedAt: Int32
    public var editRevision: Int32

    public init(
        kind: Kind,
        accountPeerId: Int64,
        dialogPeerId: Int64,
        topicId: Int64,
        messageId: Int32,
        groupedId: Int64?,
        fromPeerId: Int64?,
        text: String,
        entitiesData: Data?,
        mediaPath: String?,
        thumbnailPath: String?,
        date: Int32,
        capturedAt: Int32,
        editRevision: Int32
    ) {
        self.kind = kind
        self.accountPeerId = accountPeerId
        self.dialogPeerId = dialogPeerId
        self.topicId = topicId
        self.messageId = messageId
        self.groupedId = groupedId
        self.fromPeerId = fromPeerId
        self.text = text
        self.entitiesData = entitiesData
        self.mediaPath = mediaPath
        self.thumbnailPath = thumbnailPath
        self.date = date
        self.capturedAt = capturedAt
        self.editRevision = editRevision
    }
}
