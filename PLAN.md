# Octaspace PMS + Channel Manager - Technical Plan

## Overview

Building a modern Property Management System (PMS) with integrated Channel Manager (CMS) targeting small-to-medium hospitality businesses (5-20 properties, 50-500 rooms). Inspired by Loventis and MyAllocator but addressing their pain points with modern UX and architecture.

## Target Market

- **Primary**: Small hotel groups, hostel chains, property managers
- **Scale**: 5-20 properties, 50-500 rooms per account
- **Geography**: Initially EU-focused (Lithuania), expandable

---

## Core Features (MVP)

### 1. Property & Inventory Management
- Multi-property support with configurable views
- Room types with flexible attributes
- Room-level inventory (bed-level can be added later via `unit_type`)
- Room status tracking (clean/dirty/inspected/out-of-order)
- Amenities and features per room type

### 2. Reservation Management
- Calendar grid view (like Loventis) - highly configurable
- Reservation creation, modification, cancellation
- Multi-room bookings (single guest, multiple rooms)
- Guest profiles with history
- Reservation statuses and workflows
- Notes and internal tags
- Arrival/departure tracking

### 3. Rate Management
- Dynamic per-room/date pricing
- Rate plans (standard, non-refundable, early bird, etc.)
- Derived rates (channel-specific markup/discount from master rate)
- Weekend/seasonal rate rules
- Minimum stay and close-out rules

### 4. Channel Manager Integration
- **MVP Channels**: Booking.com, Airbnb
- Two-way sync: availability, rates, restrictions
- Reservation import from channels
- Rate derivation per channel
- Sync status monitoring and error handling

### 5. Guest Management
- Guest profiles (contact, nationality, documents)
- Booking history per guest
- Guest portal for self-service:
  - View/modify booking
  - Online check-in
  - Document upload
  - Payment status

### 6. Payments & Invoicing
- Payment tracking (deposits, partial, full)
- Multiple payment methods
- Stripe integration for card payments
- Invoice generation (PDF)
- Articles/extras (city tax, breakfast, parking)
- Refund tracking

### 7. Reporting & Analytics
- Occupancy rates (daily, weekly, monthly)
- ADR (Average Daily Rate), RevPAR
- Revenue by channel
- Forecasting and demand analysis
- Booking pace reports

### 8. Housekeeping
- Room status management (clean/dirty/inspected)
- Daily status board
- Basic task tracking

### 9. White-label & Embedding
- Subdomain booking pages: `hotel-name.octaspace.com`
- Embeddable booking widget for third-party websites
- Customizable branding (colors, logo)

---

## Pain Points Addressed

Based on research from Reddit, Capterra reviews, and industry forums:

| Pain Point | Our Solution |
|------------|--------------|
| Long training time (4+ months) | Intuitive UI, contextual help, quick onboarding |
| Overbooking from sync delays | Real-time sync with retry logic, sync status dashboard |
| Poor mobile experience | Responsive design, PWA support |
| Hidden pricing/add-ons | Transparent freemium tiers, no hidden fees |
| Slow customer support | In-app help, comprehensive docs, chat support |
| Rigid, outdated UX | Highly configurable calendar, modern Phoenix LiveView |
| Integration complexity | Pre-built OTA connectors, simple setup wizard |
| Financial reporting issues | Clean accounting integration, proper ledger design |

---

## Technical Architecture

### Stack
- **Backend**: Elixir/Phoenix (existing)
- **Frontend**: Phoenix LiveView with TailwindCSS + DaisyUI
- **Database**: PostgreSQL
- **Background Jobs**: Oban
- **File Storage**: S3-compatible (invoices, documents)
- **Payments**: Stripe
- **Channel APIs**: Direct integration (Booking.com Partner API, Airbnb API)

### Key Design Decisions

1. **Multi-tenancy**: Organization-based (one org = one customer account)
2. **Audit Trail**: All mutations logged for compliance
3. **Soft Deletes**: Critical data never hard-deleted
4. **Timezone Handling**: Store UTC, display in property timezone
5. **Currency**: Store cents as integers, support multi-currency
6. **i18n**: Full internationalization support (already using Gettext)

---

## Freemium Tiers

### Free Tier
- 1 property, up to 10 rooms
- Basic calendar view
- Manual reservations only (no channel sync)
- Basic reporting
- Email support

### Professional ($29/month per property)
- Unlimited rooms per property
- Channel manager (Booking.com, Airbnb)
- Guest portal
- Advanced reporting
- Invoice generation
- Priority support

### Business ($49/month per property)
- Everything in Professional
- White-label booking page
- Embeddable widget
- Stripe payment processing
- API access
- Advanced analytics & forecasting
- Multiple users with roles

### Enterprise (Custom pricing)
- Everything in Business
- Custom integrations
- Dedicated support
- SLA guarantees
- Custom development

---

## Data Model Overview

See `SCHEMA.dbml` for full entity relationship diagram.

### Core Entities

```
Organizations (tenants)
├── Properties
│   ├── RoomTypes
│   │   └── Units (rooms/beds)
│   ├── RatePlans
│   │   └── Rates (per date)
│   └── ChannelConnections
│       └── ChannelRateMappings
├── Guests
├── Reservations
│   ├── ReservationRooms
│   ├── ReservationArticles (extras)
│   └── Payments
└── Users
    └── UserRoles
```

---

## Implementation Phases

### Phase 1: Core PMS (Weeks 1-6)
- [ ] Database schema and migrations
- [ ] Property/RoomType/Unit CRUD
- [ ] Reservation management
- [ ] Calendar view (enhance existing)
- [ ] Guest management
- [ ] Basic room status

### Phase 2: Rates & Payments (Weeks 7-10)
- [ ] Rate plans and daily rates
- [ ] Rate rules engine
- [ ] Payment tracking
- [ ] Invoice generation
- [ ] Stripe integration

### Phase 3: Channel Manager (Weeks 11-16)
- [ ] Channel connection framework
- [ ] Booking.com integration
- [ ] Airbnb integration
- [ ] Sync engine (availability, rates)
- [ ] Reservation import

### Phase 4: Guest Features (Weeks 17-20)
- [ ] Guest portal
- [ ] Online check-in
- [ ] Booking page (white-label)
- [ ] Embeddable widget

### Phase 5: Analytics & Polish (Weeks 21-24)
- [ ] Reporting dashboard
- [ ] Forecasting
- [ ] Performance optimization
- [ ] Mobile responsiveness
- [ ] Documentation

---

## Calendar View Configuration

The main calendar view must support extensive configuration:

### View Modes
1. **Detailed** (default): Full reservation cards with guest name, dates, status, tags
2. **Overview**: Compact cells showing just occupancy/availability
3. **Rates**: Focus on pricing per room/date
4. **Housekeeping**: Room status focus

### Configurable Elements

| Component | Configurable Options |
|-----------|---------------------|
| `day_header` | Show/hide: occupancy %, arrivals, departures, available rooms, revenue |
| `room_label` | Show/hide: capacity, type, info, property badge, room status |
| `day_cell` | Show/hide: price, availability count, room status icon |
| `reservation_card` | Show/hide: guest name, dates, nights, guests, status, tags, channel source |
| Grid sizing | Column width (compact/normal/wide), row height |
| Filtering | Properties, room types, statuses, date range |

### User Preferences Storage
```elixir
%CalendarPreferences{
  view_mode: :detailed | :overview | :rates | :housekeeping,
  column_width: :compact | :normal | :wide,
  show_day_header: %{occupancy: true, arrivals: true, ...},
  show_room_label: %{capacity: true, type: true, ...},
  show_reservation: %{guest_name: true, status: true, ...},
  property_filter: [property_ids],
  room_type_filter: [room_type_ids]
}
```

---

## Channel Manager Architecture

### Sync Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Octaspace  │────▶│  Sync Queue  │────▶│   Channel   │
│   (PMS)     │     │   (Oban)     │     │    APIs     │
└─────────────┘     └──────────────┘     └─────────────┘
       │                   │                    │
       │                   ▼                    │
       │           ┌──────────────┐             │
       └──────────▶│  Sync State  │◀────────────┘
                   │   Tracking   │
                   └──────────────┘
```

### Sync Types
1. **Availability Sync**: Triggered on reservation create/update/cancel
2. **Rate Sync**: Triggered on rate change
3. **Restriction Sync**: Min stay, closed dates
4. **Reservation Pull**: Periodic + webhook-triggered

### Error Handling
- Exponential backoff on failures
- Manual retry for persistent failures
- Sync status dashboard with error details
- Alert notifications for critical failures

---

## Booking Widget Integration

### Embed Options

1. **Subdomain**: `hotel.octaspace.com`
   - Full booking flow
   - Custom branding
   - SEO-friendly

2. **Iframe Widget**:
   ```html
   <iframe src="https://book.octaspace.com/embed/PROPERTY_ID"
           width="100%" height="600"></iframe>
   ```

3. **JavaScript SDK**:
   ```html
   <script src="https://octaspace.com/sdk.js"></script>
   <div id="octaspace-booking" data-property="PROPERTY_ID"></div>
   ```

---

## API Design

RESTful API for external integrations:

### Endpoints (v1)
```
GET    /api/v1/properties
GET    /api/v1/properties/:id/availability
POST   /api/v1/reservations
GET    /api/v1/reservations/:id
PATCH  /api/v1/reservations/:id
DELETE /api/v1/reservations/:id
GET    /api/v1/guests
GET    /api/v1/reports/occupancy
```

### Authentication
- API keys per organization
- Rate limiting (1000 req/min Professional, 5000 req/min Business)

---

## Security Considerations

- Row-level security via organization_id
- Audit logging for all data changes
- PCI compliance for payment data (via Stripe)
- GDPR compliance (data export, deletion)
- Encrypted sensitive fields (passport numbers, etc.)

---

## Next Steps

1. Review and approve this plan
2. Create DBML schema file
3. Generate Ecto migrations
4. Begin Phase 1 implementation

