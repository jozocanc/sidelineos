# SidelineOS Scheduling — Design Spec

## Overview

The scheduling sub-project adds event management to SidelineOS — the core daily-use feature for DOCs and coaches. It covers creating, editing, and cancelling events (practices, games, tournaments, camps, tryouts, meetings, custom), recurring schedules, saved venues, and in-app notifications.

## Approach

**Event-based with smart recurrence.** Individual events are stored as rows in the database. Recurring patterns (e.g., "U14 practices every Tue/Thu 6pm, Sep–Nov") expand into individual event rows sharing a `recurrence_group` UUID. This keeps queries simple, makes single-event edits trivial, and sets up future voice-driven changes cleanly.

No RRULE parsing. No calendar library dependency. Agenda view is a sorted query; calendar view renders from the same data.

## Database Schema

### `venues`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | default gen_random_uuid() |
| club_id | uuid FK → clubs.id | |
| name | text NOT NULL | e.g., "Riverside Field" |
| address | text | Full address for future maps integration |
| created_at | timestamptz | default now() |

### `events`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | default gen_random_uuid() |
| club_id | uuid FK → clubs.id | |
| team_id | uuid FK → teams.id | |
| type | text NOT NULL | practice, game, tournament, camp, tryout, meeting, custom |
| title | text NOT NULL | Auto-generated or custom (e.g., "U14 Practice") |
| start_time | timestamptz NOT NULL | |
| end_time | timestamptz NOT NULL | |
| venue_id | uuid FK → venues.id | nullable |
| recurrence_group | uuid | nullable — links events from the same recurring pattern |
| notes | text | nullable |
| status | text NOT NULL | scheduled, cancelled (default: scheduled) |
| created_by | uuid FK → profiles.id | |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | default now(), auto-updated via trigger |

**Indexes:**
- events.club_id
- events.team_id
- events.start_time
- events.recurrence_group (where not null)
- events.status

### `notifications`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | default gen_random_uuid() |
| profile_id | uuid FK → profiles.id | recipient |
| event_id | uuid FK → events.id | related event |
| type | text NOT NULL | event_created, event_updated, event_cancelled |
| message | text NOT NULL | human-readable |
| read | boolean NOT NULL | default false |
| created_at | timestamptz | default now() |

**Indexes:**
- notifications.profile_id
- notifications.read (where false)
- notifications.event_id

## Row-Level Security

### `venues`
- **DOC:** full CRUD for venues in their club
- **Coach/Parent:** read-only for venues in their club

### `events`
- **DOC:** full CRUD for all events in their club
- **Coach:** full CRUD for events on teams they belong to, read-only for other events in their club
- **Parent:** read-only for events on teams they belong to

### `notifications`
- **All users:** read and update (mark read) their own notifications only

## Pages & UI

### `/dashboard/schedule` — Main Schedule Page

Two views with a toggle, agenda as default.

**Agenda view (default):**
- Events grouped by date, today first
- Each event card: time, team name (color-coded), type badge, venue, status
- "Today" section pinned at top
- Past events faded/collapsed
- Filters: team, event type
- "Add Event" button top-right

**Calendar view:**
- Weekly grid
- Events as colored blocks by team
- Click event → view/edit
- Click empty slot → create new event

### Add/Edit Event Modal

Fields:
- Team (dropdown)
- Type (practice, game, tournament, camp, tryout, meeting, custom)
- Date + start time + end time
- Venue (dropdown of saved venues + "Add new venue" inline option)
- Recurring toggle:
  - If on: pick days of week + end date
  - System generates individual event rows with shared recurrence_group
- Notes (optional text)

For edits on recurring events:
- "Edit this event only" — updates the single row
- "Edit all future events in this series" — updates all events in the recurrence_group with start_time >= this event's start_time

### Venue Management

Accessible from Settings page as a new section (not a separate page).
- List saved venues (name + address)
- Add / edit / delete via modal
- Simple CRUD

### Notification Bell

In the sidebar header area:
- Bell icon with unread count badge
- Click → dropdown of recent notifications
- Each notification: message + timestamp + read/unread indicator
- Click notification → mark as read + navigate to the event
- No separate notifications page

## Access Control

| Action | DOC | Coach | Parent |
|--------|-----|-------|--------|
| Create/edit/delete events (any team) | Yes | No | No |
| Create/edit/delete events (own teams) | Yes | Yes | No |
| View events (own teams) | Yes | Yes | Yes |
| Manage venues | Yes | No | No |
| Cancel events (any team) | Yes | No | No |
| Cancel events (own teams) | Yes | Yes | No |

## Notification Triggers

| Event Action | Recipients | Notification Type |
|-------------|-----------|-------------------|
| Event created | All coaches + parents on team | event_created |
| Event time or venue changed | All coaches + parents on team | event_updated |
| Event cancelled | All coaches + parents on team | event_cancelled |

Notifications are created as rows when the triggering action occurs. Delivery is in-app only for this phase. Push notifications and email are future additions — the trigger logic and data model stay the same.

## What's NOT in This Phase

- Voice-driven schedule changes (future — builds on top of this)
- Push notifications / email delivery (future — notification records are created now)
- Google Maps integration for venues (future — addresses stored now)
- Drag-and-drop rescheduling in calendar view
- Multi-team events (an event belongs to one team)
- Opponent tracking for games
- Attendance tracking

## File Structure

```
app-next/app/dashboard/schedule/
├── page.tsx                    # Main schedule page (agenda + calendar toggle)
├── agenda-view.tsx             # Agenda/list view component
├── calendar-view.tsx           # Weekly calendar grid component
├── event-card.tsx              # Single event card for agenda view
├── event-modal.tsx             # Add/edit event modal
├── actions.ts                  # Server actions (CRUD events, generate recurring)
└── filters.tsx                 # Team/type filter controls

app-next/app/dashboard/settings/
└── venues-section.tsx          # Venue CRUD section added to settings

app-next/components/
├── notification-bell.tsx       # Bell icon + dropdown
└── sidebar.tsx                 # (existing — add notification bell)

supabase/migrations/
└── 006_scheduling.sql          # venues, events, notifications tables + RLS
```
