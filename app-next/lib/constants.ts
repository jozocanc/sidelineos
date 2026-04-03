export const ROLES = {
  DOC: "doc",
  COACH: "coach",
  PARENT: "parent",
} as const;

export type Role = (typeof ROLES)[keyof typeof ROLES];

export const AGE_GROUPS = [
  "U8", "U9", "U10", "U11", "U12", "U13",
  "U14", "U15", "U16", "U17", "U18", "U19",
] as const;

export type AgeGroup = (typeof AGE_GROUPS)[number];

export const EVENT_TYPES = [
  'practice', 'game', 'tournament', 'camp', 'tryout', 'meeting', 'custom',
] as const

export type EventType = (typeof EVENT_TYPES)[number]

export const EVENT_TYPE_LABELS: Record<EventType, string> = {
  practice: 'Practice',
  game: 'Game',
  tournament: 'Tournament',
  camp: 'Camp',
  tryout: 'Tryout',
  meeting: 'Meeting',
  custom: 'Custom',
}

export const EVENT_STATUSES = ['scheduled', 'cancelled'] as const
export type EventStatus = (typeof EVENT_STATUSES)[number]

export const DAYS_OF_WEEK = [
  { value: 0, label: 'Sun' },
  { value: 1, label: 'Mon' },
  { value: 2, label: 'Tue' },
  { value: 3, label: 'Wed' },
  { value: 4, label: 'Thu' },
  { value: 5, label: 'Fri' },
  { value: 6, label: 'Sat' },
] as const
