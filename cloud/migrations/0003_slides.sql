-- Notes, custom decks and own slides (CUSTOM_DECKS_PLAN.md §3.5). Everything a user writes lives here,
-- never in the repository or the site files. Times are milliseconds since 1970.

-- A note on a workshop slide. "slide" is "<workshop>/<deck>#<slide id>" (stable IDs: slides.lock.json).
create table "note" (
  "userId" text not null references "user" ("id") on delete cascade,
  "slide" text not null,
  "text" text not null,
  "updatedAt" integer not null,
  primary key ("userId", "slide")
);

-- A custom deck: an ordered list of items, each {"type":"slide","ref":"<workshop>/<deck>#<id>"} or {"type":"own","id":"<own slide id>"}.
-- "share" is a random token; anyone with the link can view (read-only), with their own access to paid slides.
create table "custom_deck" (
  "id" text not null primary key,
  "userId" text not null references "user" ("id") on delete cascade,
  "title" text not null,
  "items" text not null,
  "share" text unique,
  "createdAt" integer not null,
  "updatedAt" integer not null
);
create index "custom_deck_user" on "custom_deck" ("userId");

-- A slide the user made (JSON description, §5.2). "anchor" places it after a workshop slide in that deck,
-- for that user only; null when it is used only in custom decks.
create table "own_slide" (
  "id" text not null primary key,
  "userId" text not null references "user" ("id") on delete cascade,
  "body" text not null,
  "anchor" text,
  "createdAt" integer not null,
  "updatedAt" integer not null
);
create index "own_slide_user" on "own_slide" ("userId");
