# RaceDay
## Section A — Entity Relationship Diagram

The ERD (`/docs/raceday-erd.png`) models the full RaceDay data structure using seven entities:

| Entity | Purpose |
|---|---|
|ROLE| Defines user roles (e.g. Organiser, Participant, Admin) |
| USERACCOUNT | Stores registered users; role determines their permissions |
| EVENT | An event created by an organiser (name, date, location) |
| ROUTE | The route associated with an event (distance, elevation gain) |
| CATEGORY | A distance category offered within an event (e.g. 5km, 10km, 21km) |
| ENTRY | Links a participant to a category they've entered |
| RESULT | The finish time/position produced by a completed entry |

Relationships

- ROLE (1) — USERACCOUNT (many): one role applies to many users.
- USERACCOUNT (1) — EVENT (many):an organiser creates many events.
- SERACCOUNT (1) — ENTRY (many):
-  a participant submits many entries.
- EVENT (1) — ROUTE (1):* each event has exactly one route.
- EVENT (1) — CATEGORY (many):an event offers multiple categories.
- CATEGORY (1) — ENTRY (many):a category receives many entries.
- ]ENTRY (1) — RESULT (1):each entry produces exactly one result.

 Design Notes

- A single `USERACCOUNT` table serves both organisers and participants; `ROLE` distinguishes between them and allows for future roles (e.g. Admin).
- `ROUTE` is modelled as its own entity rather than as columns on `EVENT`, so it can later support additional route metadata (e.g. GPX file, elevation profile) without altering the `EVENT` table.
- `ENTRY` sits between `USERACCOUNT` and `CATEGORY` as the many-to-many resolver, and is itself the parent of `RESULT`.

Section B — API Endpoint Plan

The full endpoint specification table is provided in `/docs/api-endpoint-plan.pdf`. It covers endpoints for:

- Authentication (register, login)
- User Profile
- Events
- Categories
- Event Enrolments (Entries)
- Results

Each endpoint entry specifies the HTTP method, route, description, required role, request body, and expected response. The implemented API in Part 2 will closely follow this plan; any deviations will be documented.

 Section C — SQL Database Script

`/docs/raceday-schema.sql` contains the full `CREATE TABLE` script for the RaceDay database, written for SQL Server Management Studio (SSMS). It matches the ERD exactly, including all primary keys, foreign keys, and constraints.

To run it:
1. Open SQL Server Management Studio.
2. Connect to your local or Azure SQL instance.
3. Open `raceday-schema.sql` and execute against a new database.



