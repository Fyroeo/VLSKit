import Foundation

/// The main entry point for the private, authenticated Cyclocity API.
///
/// This class holds the `AuthSession` object. It also creates one service struct for
/// each API domain.
///
/// Use `OpenDataClient` or `GBFSClient` instead if you only need read-only public
/// station data with no login. See the doc comments on those types in the PublicAPI
/// folder. They explain why those clients are the safer starting point.
public final class VLSClient: Sendable {

    // MARK: - Environment and Authentication

    /// The backend environment this client uses.
    ///
    /// See `VLSEnvironment` for the settings each environment holds.
    public let environment: VLSEnvironment
    /// The Keycloak login and identity session for this client.
    ///
    /// This session supplies the `Identity` header that authorizes every call below.
    /// See `AuthSession`'s documentation comment for more detail.
    public let auth: AuthSession

    private let httpClient: HTTPClient

    // MARK: - Services

    /// Account endpoints under `/contracts/{contract}/accounts`.
    public let account: AccountService
    /// Bike lookup by number or by station. Also handles post-ride ratings.
    public let bikes: BikeService
    /// Holds a bike at a stand for later pickup.
    public let bookings: BookingService
    /// Promotional campaigns.
    public let campaigns: CampaignService
    /// In-app CMS content.
    public let contents: ContentService
    /// System and contract metadata.
    public let contract: ContractService
    /// Category list for the report-a-defect feature.
    public let defectTypes: DefectTypeService
    /// Push notification device registration.
    public let devices: DeviceService
    /// Account document upload and delete. Also gets a stored asset.
    public let documents: DocumentService
    /// The in-app contact-us complaint form. The client sends it as multipart form data.
    public let email: EmailService
    /// Station and service event feed.
    public let events: EventService
    /// In-app FAQ search.
    public let faqs: FaqService
    /// Balance, transactions, and invoice line items.
    public let invoices: InvoiceService
    /// RSS news feed. This is the only endpoint in this API that does not return JSON.
    public let news: NewsService
    /// Offers, badges, options, CGAU terms, packages, and supplements.
    ///
    /// This is the largest service in this API.
    public let offers: OfferService
    /// Bike parkings. Also opens a parking gate remotely.
    public let parkings: ParkingService
    /// Hosted checkout to add funds or pay an outstanding balance.
    public let pay: PayService
    /// Starts a generic asynchronous workflow.
    public let processes: ProcessService
    /// Reward points earned for good bike-share behavior.
    public let rewards: RewardService
    /// Partner shops.
    public let shops: ShopService
    /// Referral program.
    public let sponsoring: SponsoringService
    /// Marks a station as a favorite.
    public let stationBookmarks: StationBookmarkService
    /// Real-time station list and detail, from the authenticated backend.
    ///
    /// Use `GBFSClient` or `OpenDataClient` instead if you do not need an authenticated
    /// session.
    public let stations: StationService
    /// Usage statistics shown on the app's impact screen.
    public let statistics: StatisticsService
    /// Subscriptions. You must have a subscription to unlock a bike.
    public let subscriptions: SubscriptionService
    /// Trip history and GPS route. Also releases (unlocks) a bike.
    public let trips: TripService

    // MARK: - Initialization

    /// Creates a client for one VLS backend environment.
    /// - Parameters:
    ///   - environment: The backend environment to connect to. The default value is
    ///     `.lyon`.
    ///   - tokenStore: Where the client saves and loads login tokens.
    ///   - urlSession: The URL session the client uses for network calls. The default
    ///     value is `.shared`.
    public init(environment: VLSEnvironment = .lyon, tokenStore: TokenStore, urlSession: URLSession = .shared) {
        self.environment = environment
        let auth = AuthSession(environment: environment, tokenStore: tokenStore, urlSession: urlSession)
        self.auth = auth
        let anonymousSession = AnonymousSession(environment: environment, urlSession: urlSession)
        let httpClient = HTTPClient(
            baseURL: environment.apiBaseURL,
            tokenProvider: auth,
            secondaryTokenProvider: anonymousSession,
            authHeaderStyle: .identity,
            session: urlSession
        )
        self.httpClient = httpClient

        let contract = environment.contract
        self.account = AccountService(httpClient: httpClient, contract: contract)
        self.bikes = BikeService(httpClient: httpClient, contract: contract)
        self.bookings = BookingService(httpClient: httpClient, contract: contract)
        self.campaigns = CampaignService(httpClient: httpClient, contract: contract)
        self.contents = ContentService(httpClient: httpClient, contract: contract)
        self.contract = ContractService(httpClient: httpClient, contract: contract)
        self.defectTypes = DefectTypeService(httpClient: httpClient, contract: contract)
        self.devices = DeviceService(httpClient: httpClient, contract: contract)
        self.documents = DocumentService(httpClient: httpClient, contract: contract)
        self.email = EmailService(httpClient: httpClient, contract: contract)
        self.events = EventService(httpClient: httpClient, contract: contract)
        self.faqs = FaqService(httpClient: httpClient, contract: contract)
        self.invoices = InvoiceService(httpClient: httpClient, contract: contract)
        self.news = NewsService(httpClient: httpClient, contract: contract)
        self.offers = OfferService(httpClient: httpClient, contract: contract)
        self.parkings = ParkingService(httpClient: httpClient, contract: contract)
        self.pay = PayService(httpClient: httpClient, contract: contract)
        self.processes = ProcessService(httpClient: httpClient, contract: contract)
        self.rewards = RewardService(httpClient: httpClient, contract: contract)
        self.shops = ShopService(httpClient: httpClient, contract: contract)
        self.sponsoring = SponsoringService(httpClient: httpClient, contract: contract)
        self.stationBookmarks = StationBookmarkService(httpClient: httpClient, contract: contract)
        self.stations = StationService(httpClient: httpClient, contract: contract)
        self.statistics = StatisticsService(httpClient: httpClient, contract: contract)
        self.subscriptions = SubscriptionService(httpClient: httpClient, contract: contract)
        self.trips = TripService(httpClient: httpClient, contract: contract)
    }

    // MARK: - Authentication State

    /// Indicates whether the client currently has a valid login session.
    public var isAuthenticated: Bool {
        get async { await auth.isAuthenticated }
    }

    // MARK: - Login

    /// Starts the login flow. This is step 1 of 2.
    ///
    /// See `AuthSession.beginLogin()` for detail on the PKCE authorize URL this builds.
    /// - Returns: A pending authorization. Pass it to
    ///   `completeLogin(callbackURL:pending:)` to finish the flow.
    public func beginLogin() async -> PendingAuthorization {
        await auth.beginLogin()
    }

    /// Finishes the login flow. This is step 2 of 2.
    ///
    /// Call this after a login web view redirects back to the environment's redirect
    /// URI with a `code` query parameter. See `AuthSession.completeLogin(callbackURL:pending:)`
    /// for more detail.
    /// - Parameters:
    ///   - callbackURL: The redirect URL the login web view received, including its
    ///     query parameters.
    ///   - pending: The pending authorization returned by `beginLogin()`.
    /// - Returns: The new login tokens.
    /// - Throws: `VLSError.authenticationFailed` if the callback URL or the state
    ///   does not match.
    @discardableResult
    public func completeLogin(callbackURL: URL, pending: PendingAuthorization) async throws -> VLSTokens {
        try await auth.completeLogin(callbackURL: callbackURL, pending: pending)
    }

    /// Ends the current login session.
    ///
    /// This method clears the local tokens. It also ends the Keycloak single sign-on
    /// session on the server. See `AuthSession.logout()` for why both steps matter.
    public func logout() async {
        await auth.logout()
    }
}
