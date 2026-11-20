-- The site's own tables (LAUNCH_PLAN.md §4). Times are milliseconds since 1970 (Date.now()).

-- Which paid products a user holds. One row per user and product.
-- expiresAt NULL = does not expire. source says where it came from: 'manual', 'razorpay:<payment id>', 'seat:<code>'.
create table "entitlement" (
  "userId" text not null references "user" ("id") on delete cascade,
  "product" text not null,
  "expiresAt" integer,
  "source" text not null,
  "createdAt" integer not null,
  primary key ("userId", "product")
);

-- Saved progress: one JSON document per user and key, e.g. key 'rq:v1' is the game's state,
-- 'ws-plan:basic' the ticks on the Basic study plan, 'quiz:...' a deck's quiz score.
create table "progress" (
  "userId" text not null references "user" ("id") on delete cascade,
  "key" text not null,
  "value" text not null,
  "updatedAt" integer not null,
  primary key ("userId", "key")
);

-- The last page a user opened, for "Continue where you left off".
create table "visit" (
  "userId" text not null primary key references "user" ("id") on delete cascade,
  "path" text not null,
  "title" text not null,
  "seenAt" integer not null
);
