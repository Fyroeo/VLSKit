import Foundation

// MARK: - RSS Feed Model

/// A parsed RSS feed.
/// The API returns this feed from `GET /contracts/{contract}/news/feed/{platform}` (`ri.g`).
/// This one endpoint sends XML data. Every other endpoint in this API sends JSON.
/// `RSSParser` turns the raw XML bytes into this model.
public struct RSSFeed: Sendable {
    /// The title of the feed.
    public let title: String
    /// The link URL of the feed. This value can be absent.
    public let link: String?
    /// The description of the feed. This value can be absent.
    public let description: String?
    /// The list of news items in the feed.
    public let items: [Item]

    /// One news item inside an RSS feed.
    public struct Item: Sendable {
        /// The unique identifier of the item, from the RSS `guid` element. This value can be absent.
        public let guid: String?
        /// The title of the item.
        public let title: String
        /// The description of the item. This value can be absent.
        public let description: String?
        /// The author of the item.
        public let author: String
        /// The publish date of the item, as raw text from the RSS `pubDate` element. This value can be absent.
        public let publishedDate: String?
        /// The link URL of the item. This value can be absent.
        public let link: String?
        /// The attached media file for the item, for example an image. This value can be absent.
        public let enclosure: Enclosure?
    }

    /// A media file attached to an RSS item, from the RSS `enclosure` element.
    public struct Enclosure: Sendable {
        /// The URL of the attached file.
        public let url: String
        /// The MIME type of the attached file, for example "image/jpeg".
        public let type: String
        /// The size of the attached file, in bytes.
        public let length: Int64
    }
}

// MARK: - RSS Parser (Internal)

/// A minimal RSS 2.0 parser, built on `XMLParser`.
/// This parser only supports one feed shape: `rss > channel > item*`.
/// It is not a general-purpose RSS or Atom library.
final class RSSParser: NSObject, XMLParserDelegate {
    private var title = ""
    private var link: String?
    private var feedDescription: String?
    private var items: [RSSFeed.Item] = []

    private var currentElement = ""
    private var currentText = ""
    private var inItem = false
    private var itemGUID: String?
    private var itemTitle = ""
    private var itemDescription: String?
    private var itemAuthor = ""
    private var itemPubDate: String?
    private var itemLink: String?
    private var itemEnclosure: RSSFeed.Enclosure?

    static func parse(_ data: Data) throws -> RSSFeed {
        let parser = XMLParser(data: data)
        let delegate = RSSParser()
        parser.delegate = delegate
        guard parser.parse() else {
            throw parser.parserError ?? VLSError.decodingFailed(underlying: NSError(domain: "RSSParser", code: -1), body: data)
        }
        return RSSFeed(title: delegate.title, link: delegate.link, description: delegate.feedDescription, items: delegate.items)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        currentText = ""
        if elementName == "item" {
            inItem = true
            itemGUID = nil
            itemTitle = ""
            itemDescription = nil
            itemAuthor = ""
            itemPubDate = nil
            itemLink = nil
            itemEnclosure = nil
        }
        if elementName == "enclosure" {
            let url = attributeDict["url"] ?? ""
            let type = attributeDict["type"] ?? ""
            let length = Int64(attributeDict["length"] ?? "") ?? 0
            itemEnclosure = RSSFeed.Enclosure(url: url, type: type, length: length)
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if inItem {
            switch elementName {
            case "guid": itemGUID = text
            case "title": itemTitle = text
            case "description": itemDescription = text
            case "author": itemAuthor = text
            case "pubDate": itemPubDate = text
            case "link": itemLink = text
            case "item":
                items.append(RSSFeed.Item(guid: itemGUID, title: itemTitle, description: itemDescription, author: itemAuthor, publishedDate: itemPubDate, link: itemLink, enclosure: itemEnclosure))
                inItem = false
            default: break
            }
        } else {
            switch elementName {
            case "title": title = text
            case "link": link = text
            case "description": feedDescription = text
            default: break
            }
        }
        currentText = ""
    }
}
