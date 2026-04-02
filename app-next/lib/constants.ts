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
