import { pgTable, serial, text, integer, boolean, timestamp, jsonb, real } from "drizzle-orm/pg-core";

export const minigames = pgTable("minigames", {
  id: text("id").primaryKey(),
  displayName: text("display_name").notNull(),
  description: text("description").notNull(),
  category: text("category").notNull(),
  secondaryCategory: text("secondary_category"),
  minPlayers: integer("min_players").notNull(),
  maxPlayers: integer("max_players").notNull(),
  duration: integer("duration").notNull(),
  cooldownRounds: integer("cooldown_rounds").notNull(),
  supportsTeams: boolean("supports_teams").notNull().default(false),
  hidesInformation: boolean("hides_information").notNull().default(false),
  maps: jsonb("maps").$type<string[]>().notNull(),
  allowedModifiers: jsonb("allowed_modifiers").$type<string[]>().notNull(),
  movement: jsonb("movement").$type<Record<string, boolean | number>>().notNull(),
  status: text("status").notNull().default("implemented"),
  syncedAt: timestamp("synced_at").notNull().defaultNow(),
});

export const simulationRuns = pgTable("simulation_runs", {
  id: serial("id").primaryKey(),
  kind: text("kind").notNull(), // voting | roundloop
  cycles: integer("cycles").notNull(),
  seed: integer("seed").notNull(),
  params: jsonb("params").$type<Record<string, unknown>>().notNull(),
  metrics: jsonb("metrics").$type<Record<string, unknown>>().notNull(),
  violations: jsonb("violations").$type<string[]>().notNull(),
  passed: boolean("passed").notNull(),
  durationMs: real("duration_ms").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const testRuns = pgTable("test_runs", {
  id: serial("id").primaryKey(),
  suite: text("suite").notNull(),
  runner: text("runner").notNull(),
  passed: integer("passed").notNull(),
  failed: integer("failed").notNull(),
  output: text("output").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const decisions = pgTable("decisions", {
  id: serial("id").primaryKey(),
  title: text("title").notNull(),
  context: text("context").notNull(),
  decision: text("decision").notNull(),
  consequences: text("consequences").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});
