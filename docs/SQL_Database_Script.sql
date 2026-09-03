--creating database--
CREATE DATABASE RaceDayDb;

--use of database--
use RaceDayDb;
--stores all system user--
--role of user table is organiser creates events participant joins--                           
CREATE TABLE Users (--this is user table--
    UserId INT IDENTITY(1,1) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(20) NULL,
    Role NVARCHAR(20) NOT NULL CHECK (Role IN ('Organiser', 'Participant')),
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Users PRIMARY KEY (UserId),
    CONSTRAINT UQ_Users_Email UNIQUE (Email)
);
--Table 2 RaceRoutes
--stores route location
CREATE TABLE RaceRoutes (
    RouteId INT IDENTITY(1,1) NOT NULL,
    RouteName NVARCHAR(50) NOT NULL,
    DistanceKm DECIMAL(5,2) NOT NULL,
    ElevationGainM INT NULL,
    MapUrl NVARCHAR(255) NULL,
    CONSTRAINT PK_RaceRoutes PRIMARY KEY (RouteId)
);
--table 3 events table

CREATE TABLE Events (
    EventId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    EventDate DATETIME2 NOT NULL,
    StartTime TIME NOT NULL,
    Location NVARCHAR(150) NOT NULL,
    OrganiserId INT NOT NULL,
    RouteId INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (OrganiserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (RouteId) REFERENCES RaceRoutes(RouteId) ON DELETE CASCADE
);
-- TABLE 4: Categories
-- PURPOSE: Different race categories per event
-- Example: 5km, 10km, 21km, Junior, Senior
-- MUST be BEFORE Enrolments (FK dependency!)

CREATE TABLE Categories (
    CategoryId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    EntryFee DECIMAL(10,2) NOT NULL,
    EventId INT NOT NULL,
    FOREIGN KEY (EventId) REFERENCES Events(EventId) ON DELETE CASCADE,
    CONSTRAINT UQ_Category_PerEvent UNIQUE (EventId, Name)
);
-- TABLE 5: Enrolments
-- PURPOSE: Participant entries — links User → Event → Category
-- One user can enter multiple events

CREATE TABLE Enrolments (
    EnrolmentId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    UserId INT NOT NULL,
    EventId INT NOT NULL,
    CategoryId INT NOT NULL,
    EnrolledAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    IsPaid BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (EventId) REFERENCES Events(EventId),
    FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),
    CONSTRAINT UQ_User_Event_Category UNIQUE (UserId, EventId, CategoryId)
);
-- TABLE 6: Results
-- PURPOSE: Final race results
-- Linked to Enrolments — one result per entry

CREATE TABLE Results (
    ResultId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EnrolmentId INT NOT NULL UNIQUE,
    FinishTime TIME NULL,
    Position INT NULL,
    Notes NVARCHAR(255) NULL,
    FOREIGN KEY (EnrolmentId) REFERENCES Enrolments(EnrolmentId) ON DELETE CASCADE
);