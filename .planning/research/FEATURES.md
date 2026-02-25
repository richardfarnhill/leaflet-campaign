# Feature Landscape: Leaflet Delivery Tracking

**Domain:** Political Campaign / Leaflet Delivery Tracking
**Researched:** February 2026
**Confidence:** MEDIUM

## Executive Summary

This research surveys the feature landscape for leaflet and political campaign delivery tracking products. The market includes both commercial delivery management platforms (Onfleet, Deliforce, DistributionDesk) and political-specific tools (NGP VAN/MiniVAN, Trail Blazer, Knockbase). Key findings indicate that basic tracking and territory management are table stakes, while demographic targeting, team coordination, and real-time progress monitoring are differentiating features. For the 5-person team (Richard, Josh, Dan, Cahner, Orla) with 800-1200 door chunks, the card-based reservation system represents a strategic opportunity to build differentiation around team coordination and demographic filtering using Census 2021 data.

## Table Stakes Features

Table stakes features are those that users expect as baseline functionality. Products missing these features feel incomplete or broken to users.

### Core Tracking Features

| Feature | Why Expected | Complexity | Notes |
|---------|---------------|------------|-------|
| **Delivery Recording** | Users must prove doors were visited | Low | Already exists in project |
| **Session Management** | Track active delivery periods | Low | Already exists in project |
| **Location Verification** | Prove delivery occurred at correct location | Medium | GPS coordinates, timestamp |
| **Basic Mapping** | Visual representation of delivery areas | Medium | Integration with mapping services |
| **Door Count Tracking** | Count of doors in an area | Low | Calculate from address data |

### Data Management

| Feature | Why Expected | Complexity | Notes |
|---------|---------------|------------|-------|
| **Address Data Storage** | Store addresses to deliver to | Low | Integration with OS Names API |
| **Progress Indicators** | Show completion percentage | Low | Visual feedback for users |
| **Export Capability** | Export data for reporting | Low | CSV/Excel export |
| **Basic Analytics** | Track doors delivered vs remaining | Low | Simple counts and percentages |

### Team Infrastructure

| Feature | Why Expected | Complexity | Notes |
|---------|---------------|------------|-------|
| **User Authentication** | Team members need individual access | Low | Already exists |
| **Team Member Management** | Manage 5 team members | Low | Already exists |
| **Role Assignment** | Differentiate coordinators from deliverers | Low | Simple role system |

## Differentiating Features

Differentiating features are those that set products apart from competitors. They are not expected by default but are valued when present.

### Territory Management and Reservation

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Area Reservation System** | Prevent duplicate delivery by reserving chunks | Medium | Core new feature for this project |
| **Chunk Sizing (800-1200 doors)** | Optimal chunk size for single session | Low | Configurable based on team capacity |
| **Real-time Availability** | See which areas are available/reserved | Medium | Prevents conflicts |
| **Reservation Expiry** | Auto-release unclaimed reservations | Medium | Prevents territory hoarding |
| **Manual Override** | Coordinator can reassign areas | Medium | Flexibility for coordination |

### Demographic Targeting

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Census 2021 Filtering** | Target specific demographics | High | Unique selling point for UK campaigns |
| **Household Composition** | Filter by number of occupants | Medium | Census data integration |
| **Age Demographics** | Target by age distribution | Medium | Census data fields |
| **Socioeconomic Indicators** | Target by housing/employment | Medium | Requires census data mapping |
| **Custom Demographic Rules** | Combine multiple filters | High | Advanced filtering logic |

### Team Coordination

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Progress Broadcasting** | See team progress in real-time | Medium | Motivational for team |
| **Workload Balancing** | Ensure fair distribution | Medium | Analytics on completion rates |
| **Team Chat/Updates** | In-app communication | Medium | Reduces external communication |
| **Leaderboards** | Gamify completion | Low | Motivational feature |
| **Completion Notifications** | Alert when areas complete | Low | Team awareness |

### Advanced Analytics

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Completion Rate by Area** | Identify difficult regions | Medium | Historical analysis |
| **Time Per Door** | Track delivery efficiency | Medium | Performance metrics |
| **Route Efficiency** | Optimize delivery order | High | Integration with routing APIs |
| **Demographic Success Tracking** | Correlate demographics with responses | High | Advanced analytics |
| **Heat Maps** | Visualise delivery density | Medium | Mapping enhancement |

### Integration and Automation

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **OS Names API Integration** | Accurate UK street data | Medium | Already planned |
| **Census 2021 Data Import** | UK demographic data | High | Data processing pipeline |
| **Finance Integration** | Link delivery to ROI | Low | Already exists in project |
| **Enquiry Tracking** | Track responses from deliveries | Low | Already exists in project |

## Anti-Features

Anti-features are things to deliberately NOT build. These are common mistakes in this domain that waste resources or create negative user experiences.

### Features to Avoid

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Real-time GPS Tracking** | Privacy concerns, battery drain, overkill for walking delivery | Manual check-in at area boundaries |
| **Customer-facing Tracking Portal** | Leaflet delivery doesn't have recipients expecting tracking | Focus on internal team tracking |
| **Complex Routing Algorithms** | Overengineering for pedestrian delivery | Simple alphabetical or street-based ordering |
| **Paid Advertising Features** | Political campaigns have strict spending limits | Focus on efficiency, not upselling |
| **Multi-language Support** | Unnecessary for UK political campaign | Single language (English) |
| **Consumer-grade App Store Apps** | Extra complexity, no value-add | Progressive Web App or simple mobile-optimized web |
| **Complex Scheduling/Appointments** | Leaflet delivery is bulk operation, not appointment-based | Simple chunk-based assignment |
| **Vehicle Routing** | Designed for pedestrian delivery | Focus on walking efficiency |
| **Real-time Push Notifications** | Annoying for team, unnecessary | Pull-based updates or daily summaries |
| **Third-party Map Embedding Costs** | Expensive at scale | Use free tile providers (OpenStreetMap) |

### Scope Creep Warnings

| Warning Sign | Risk | Mitigation |
|--------------|------|------------|
| Building for national campaigns | Too complex | Focus on 5-person team use case |
| Supporting multiple countries | Data complexity | UK-only for Census 2021 |
| White-label/reselling | Support burden | Internal tool focus |
| API-first architecture | Overengineering | Simple web interface first |

## Feature Dependencies

Understanding dependencies is critical for phased implementation.

```
Feature Dependency Graph:

OS Names API Integration
    ↓
Address Data Storage → Door Count Tracking
    ↓
Area Segmentation (800-1200 doors)
    ↓
Chunk Availability Calculation
    ↓
Area Reservation System ←── Team Member Management
    ↓                    ↓
Progress Tracking ←─── Real-time Availability
    ↓
Basic Analytics
    ↓
Completion Rate by Area
    ↓
Demographic Filtering ←─ Census 2021 Data Import
    ↓
Demographic Success Tracking (Advanced)

Finance Tracking (Existing) ←── ROI Correlation
Enquiry Tracking (Existing) ←── Response Tracking
```

### Critical Path to MVP

1. **Phase 1:** OS Names API + Address Storage + Door Counting
2. **Phase 2:** Area Segmentation into 800-1200 door chunks
3. **Phase 3:** Reservation System (claim/release chunks)
4. **Phase 4:** Progress Tracking (completion percentage)
5. **Phase 5:** Basic Analytics (completion rates)

### Features That Enable Others

| Feature | Enables | Notes |
|---------|---------|-------|
| Area Segmentation | Reservation System | Cannot reserve without defined chunks |
| Census 2021 Integration | Demographic Filtering | Required data source |
| Progress Tracking | Team Coordination | Visibility enables coordination |
| Chunk Size Configuration | Workload Balancing | Foundation for analytics |

## MVP Recommendation

For this 5-person team (Richard, Josh, Dan, Cahner, Orla) with existing session tracking, delivery recording, and finance tracking, the recommended MVP prioritisation is:

### Must-Have for MVP (Phase 1)

1. **Area Segmentation** - Divide delivery zones into 800-1200 door chunks
2. **Reservation System** - Claim and release chunks to prevent duplicate work
3. **Basic Progress Tracking** - Show completion percentage per chunk
4. **OS Names API Integration** - Accurate UK street data
5. **Chunk Availability Display** - See which areas are available

### Differentiators for Post-MVP (Phase 2+)

1. **Census 2021 Demographic Filtering** - Target specific demographics
2. **Real-time Team Progress** - See all team members' progress
3. **Completion Rate Analytics** - Historical performance
4. **Reservation Expiry** - Auto-release stale reservations

### Defer Indefinitely

- Real-time GPS tracking
- Customer-facing tracking
- Complex vehicle routing
- Multi-campaign support
- White-label capabilities

## Sources

- DistributionDesk product documentation
- NGP VAN/MiniVAN turf cutting documentation
- Onfleet feature documentation
- Knockbase canvassing software features
- Industry analysis of delivery management platforms
- UK Census 2021 data documentation

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Table Stakes | HIGH | Based on multiple competing products |
| Differentiators | MEDIUM | Researched from market leaders, some inference |
| Anti-Features | MEDIUM | Based on common domain pitfalls |
| Dependencies | HIGH | Logical feature ordering |
| MVP Recommendations | MEDIUM | Adapted to specific 5-person context |
