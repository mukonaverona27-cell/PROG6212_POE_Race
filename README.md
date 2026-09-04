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
4. RaceDay - Section B: API Endpoint Plan

 Data Model Assumption
Entities: `Users` (base account + role), `Organisers`, `Participants`, `Events`, `Categories`, `Enrolments`, `Results`.
- A `User` is either an `Organiser` or a `Participant` (1:1 subtype tables).
- An `Organiser` owns many `Events`. An `Event` has many `Categories`.
- A `Participant` enrols in a `Category` via `Enrolments` (many-to-many resolved).
- Each `Enrolment` has at most one `Result`.

---

Authentication

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| POST | /api/auth/register | Registers a new user as either an Organiser or a Participant. | None (public) | { fullName, email, password, role } | 201 Created - user id and role. 400 Bad Request - validation failure. 409 Conflict - email already registered. |
| POST | /api/auth/login | Authenticates a user and issues a JWT access token. | None (public) | { email, password } | 200 OK - JWT token + role. 401 Unauthorized - invalid credentials. |

 User Profile

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| GET | /api/users/me | Returns the profile of the currently authenticated user. | Any (logged in) | None | 200 OK - user profile object. 401 Unauthorized. |
| PUT | /api/users/me | Updates the profile of the currently authenticated user. | Any (logged in) | { fullName, email, ...roleSpecificFields } | 200 OK - updated profile. 400 Bad Request. |

## Events

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| GET | /api/events | Lists all events, optionally filtered by date or search term. | None (public) | None | 200 OK - array of events. |
| GET | /api/events/{id} | Returns full details for a single event, including its categories. | None (public) | None | 200 OK - event object. 404 Not Found. |
| POST | /api/events | Creates a new event owned by the logged-in organiser. | Organiser | { name, eventDate, location, description } | 201 Created - new event. 400 Bad Request. |
| PUT | /api/events/{id} | Updates an event owned by the logged-in organiser. | Organiser | { name, eventDate, location, description } | 200 OK - updated event. 403 Forbidden - not the owning organiser. 404 Not Found. |
| DELETE | /api/events/{id} | Deletes an event owned by the logged-in organiser. | Organiser | None | 204 No Content. 403 Forbidden. 404 Not Found. |

## Categories

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| GET | /api/events/{eventId}/categories | Lists all categories belonging to a specific event. | None (public) | None | 200 OK - array of categories. 404 Not Found. |
| POST | /api/events/{eventId}/categories | Adds a new category to an event owned by the logged-in organiser. | Organiser | { name, distanceKm, maxParticipants, fee } | 201 Created - new category. 403 Forbidden. |
| PUT | /api/categories/{id} | Updates a category on an event owned by the logged-in organiser. | Organiser | { name, distanceKm, maxParticipants, fee } | 200 OK - updated category. 403 Forbidden. 404 Not Found. |
| DELETE | /api/categories/{id} | Deletes a category from an event owned by the logged-in organiser. | Organiser | None | 204 No Content. 403 Forbidden. 404 Not Found. |

 Event Enrolments

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| POST | /api/categories/{categoryId}/enrol | Enrols the logged-in participant into a category for an event. | Participant | { } (participant identified from token) | 201 Created - enrolment record. 409 Conflict - already enrolled or category full. 404 Not Found. |
| GET | /api/enrolments/me | Returns all enrolments belonging to the logged-in participant. | Participant | None | 200 OK - array of enrolments. |
| GET | /api/events/{eventId}/enrolments | Returns all enrolments for an event, for the owning organiser. | Organiser | None | 200 OK - array of enrolments with participant details. 403 Forbidden. |
| DELETE | /api/enrolments/{id} | Cancels the logged-in participant's own enrolment. | Participant | None | 204 No Content. 403 Forbidden - not the owner. 404 Not Found. |


 Results

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| POST | /api/enrolments/{id}/result | Captures a finish time and position for a participant's enrolment. | Organiser | { finishTime, position } | 201 Created - result record. 403 Forbidden. 404 Not Found. |
| PUT | /api/results/{id} | Corrects a previously captured result. | Organiser | { finishTime, position } | 200 OK - updated result. 403 Forbidden. 404 Not Found. |
| GET | /api/participants/me/results | Returns all results belonging to the logged-in participant. | Participant | None | 200 OK - array of results. |
| GET | /api/events/{eventId}/results | Returns all results for an event (leaderboard view). | None (public) | None | 200 OK - array of results ranked by category and position. |

/* =========================================================
   RaceDay System - Database Schema (Section C)
   Target: SQL Server (SSMS)
   Run on a clean database. Drops existing objects first so
   the script is re-runnable during testing.
   ========================================================= */

IF DB_ID('RaceDayDB') IS NULL
BEGIN
    CREATE DATABASE RaceDayDB;
END
GO

USE RaceDayDB;
GO

/* Drop in dependency order if re-running */
IF OBJECT_ID('dbo.Results', 'U') IS NOT NULL DROP TABLE dbo.Results;
IF OBJECT_ID('dbo.Enrolments', 'U') IS NOT NULL DROP TABLE dbo.Enrolments;
IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL DROP TABLE dbo.Categories;
IF OBJECT_ID('dbo.Events', 'U') IS NOT NULL DROP TABLE dbo.Events;
IF OBJECT_ID('dbo.Participants', 'U') IS NOT NULL DROP TABLE dbo.Participants;
IF OBJECT_ID('dbo.Organisers', 'U') IS NOT NULL DROP TABLE dbo.Organisers;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
GO

/* =========================================================
   1. Users - base account for both roles
   ========================================================= */
CREATE TABLE dbo.Users (
    UserId          INT IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(100)   NOT NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(255)   NOT NULL,
    Role            NVARCHAR(20)    NOT NULL
        CONSTRAINT CK_Users_Role CHECK (Role IN ('Organiser','Participant')),
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSDATETIME()
);
GO

/* =========================================================
   2. Organisers - 1:1 extension of Users
   ========================================================= */
CREATE TABLE dbo.Organisers (
    OrganiserId     INT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT NOT NULL UNIQUE
        CONSTRAINT FK_Organisers_Users FOREIGN KEY REFERENCES dbo.Users(UserId),
    OrganisationName NVARCHAR(150) NULL
);
GO

/* =========================================================
   3. Participants - 1:1 extension of Users
   ========================================================= */
CREATE TABLE dbo.Participants (
    ParticipantId   INT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT NOT NULL UNIQUE
        CONSTRAINT FK_Participants_Users FOREIGN KEY REFERENCES dbo.Users(UserId),
    DateOfBirth     DATE NULL,
    EmergencyContact NVARCHAR(50) NULL
);
GO

/* =========================================================
   4. Events - 1 Organiser : Many Events
   ========================================================= */
CREATE TABLE dbo.Events (
    EventId         INT IDENTITY(1,1) PRIMARY KEY,
    OrganiserId     INT NOT NULL
        CONSTRAINT FK_Events_Organisers FOREIGN KEY REFERENCES dbo.Organisers(OrganiserId),
    Name            NVARCHAR(150) NOT NULL,
    EventDate       DATE NOT NULL,
    Location        NVARCHAR(150) NOT NULL,
    Description     NVARCHAR(500) NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

/* =========================================================
   5. Categories - 1 Event : Many Categories
   ========================================================= */
CREATE TABLE dbo.Categories (
    CategoryId      INT IDENTITY(1,1) PRIMARY KEY,
    EventId         INT NOT NULL
        CONSTRAINT FK_Categories_Events FOREIGN KEY REFERENCES dbo.Events(EventId),
    Name            NVARCHAR(100) NOT NULL,
    DistanceKm      DECIMAL(5,2) NOT NULL,
    MaxParticipants INT NOT NULL DEFAULT 100,
    Fee             DECIMAL(8,2) NOT NULL DEFAULT 0
);
GO

/* =========================================================
   6. Enrolments - resolves Participants <-M:M-> Categories
   ========================================================= */
CREATE TABLE dbo.Enrolments (
    EnrolmentId     INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantId   INT NOT NULL
        CONSTRAINT FK_Enrolments_Participants FOREIGN KEY REFERENCES dbo.Participants(ParticipantId),
    CategoryId      INT NOT NULL
        CONSTRAINT FK_Enrolments_Categories FOREIGN KEY REFERENCES dbo.Categories(CategoryId),
    EnrolmentDate   DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Status          NVARCHAR(20) NOT NULL DEFAULT 'Confirmed'
        CONSTRAINT CK_Enrolments_Status CHECK (Status IN ('Confirmed','Cancelled')),
    CONSTRAINT UQ_Enrolments_Participant_Category UNIQUE (ParticipantId, CategoryId)
);
GO

/* =========================================================
   7. Results - 1:1 with Enrolments
   ========================================================= */
CREATE TABLE dbo.Results (
    ResultId        INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentId     INT NOT NULL UNIQUE
        CONSTRAINT FK_Results_Enrolments FOREIGN KEY REFERENCES dbo.Enrolments(EnrolmentId),
    FinishTime      TIME(0) NOT NULL,
    Position        INT NULL,
    CapturedByOrganiserId INT NOT NULL
        CONSTRAINT FK_Results_Organisers FOREIGN KEY REFERENCES dbo.Organisers(OrganiserId),
    CapturedAt      DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

/* =========================================================
   SAMPLE DATA
   ========================================================= */

-- Users: 2 Organisers + 2 Participants
INSERT INTO dbo.Users (FullName, Email, PasswordHash, Role) VALUES
('Sarah Nkosi',   'sarah.nkosi@raceday.co.za',   'HASH_PLACEHOLDER_1', 'Organiser'),
('Mike Botha',    'mike.botha@raceday.co.za',    'HASH_PLACEHOLDER_2', 'Organiser'),
('Thando Dlamini','thando.dlamini@example.com',  'HASH_PLACEHOLDER_3', 'Participant'),
('Jason Pillay',  'jason.pillay@example.com',    'HASH_PLACEHOLDER_4', 'Participant');
GO

INSERT INTO dbo.Organisers (UserId, OrganisationName) VALUES
(1, 'Joburg Road Running Club'),
(2, 'Cape Trail Series');
GO

INSERT INTO dbo.Participants (UserId, DateOfBirth, EmergencyContact) VALUES
(3, '1995-04-12', '0821234567'),
(4, '1990-09-01', '0839876543');
GO

-- Events: 3 events, one per organiser (plus a second for organiser 1)
INSERT INTO dbo.Events (OrganiserId, Name, EventDate, Location, Description) VALUES
(1, 'Joburg City 10K',      '2026-10-10', 'Sandton, Johannesburg', 'Annual city road race.'),
(1, 'Soweto Half Marathon', '2026-11-15', 'Soweto, Johannesburg',  'Half marathon through historic Soweto.'),
(2, 'Table Mountain Trail Run', '2026-09-20', 'Cape Town', 'Scenic trail run with multiple distances.');
GO

-- Categories: at least one per event
INSERT INTO dbo.Categories (EventId, Name, DistanceKm, MaxParticipants, Fee) VALUES
(1, '10km Open',    10.0, 500, 150.00),
(1, '5km Fun Run',   5.0, 300, 80.00),
(2, '21.1km Half',  21.1, 400, 250.00),
(3, '15km Trail',   15.0, 200, 200.00),
(3, '30km Trail',   30.0, 150, 350.00);
GO

-- Enrolments: sample enrolments across participants/categories
INSERT INTO dbo.Enrolments (ParticipantId, CategoryId, Status) VALUES
(1, 1, 'Confirmed'), -- Thando -> Joburg 10km Open
(1, 4, 'Confirmed'), -- Thando -> Table Mountain 15km Trail
(2, 3, 'Confirmed'); -- Jason  -> Soweto Half
GO

-- Results: sample results for completed enrolments
INSERT INTO dbo.Results (EnrolmentId, FinishTime, Position, CapturedByOrganiserId) VALUES
(1, '00:52:30', 3, 1),
(3, '01:48:15', 12, 1);
GO

