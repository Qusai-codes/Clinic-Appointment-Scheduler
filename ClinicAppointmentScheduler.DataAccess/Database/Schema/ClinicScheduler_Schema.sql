/* ============================================================
   Clinic Appointment Scheduler (CAS)
   SQL Server schema and seed data
   ------------------------------------------------------------
   Version : 1.0
   Target  : Microsoft SQL Server (2017+ recommended)
   Run     : Execute top-to-bottom in SSMS or sqlcmd.
   ============================================================ */

/* ------------------------------------------------------------
   Database
   ------------------------------------------------------------ */
IF DB_ID(N'ClinicScheduler') IS NULL
    CREATE DATABASE ClinicScheduler;
GO
USE ClinicScheduler;
GO

/* ============================================================
   Lookup / reference tables
   ============================================================ */

IF OBJECT_ID(N'dbo.Roles', N'U') IS NULL
CREATE TABLE dbo.Roles (
    RoleID   INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE
);
GO

IF OBJECT_ID(N'dbo.AppointmentStatuses', N'U') IS NULL
CREATE TABLE dbo.AppointmentStatuses (
    StatusID   INT IDENTITY(1,1) PRIMARY KEY,
    StatusName NVARCHAR(30) NOT NULL UNIQUE
);
GO

IF OBJECT_ID(N'dbo.Specialties', N'U') IS NULL
CREATE TABLE dbo.Specialties (
    SpecialtyID INT IDENTITY(1,1) PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL UNIQUE
);
GO

IF OBJECT_ID(N'dbo.Rooms', N'U') IS NULL
CREATE TABLE dbo.Rooms (
    RoomID   INT IDENTITY(1,1) PRIMARY KEY,
    Name     NVARCHAR(50) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1
);
GO

/* ============================================================
   Users
   ============================================================ */

IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
CREATE TABLE dbo.Users (
    UserID       INT IDENTITY(1,1) PRIMARY KEY,
    Username     NVARCHAR(50)  NOT NULL UNIQUE,
    PasswordHash VARBINARY(64) NOT NULL,   -- e.g. SHA-256/512 of (salt + password)
    Salt         VARBINARY(32) NOT NULL,
    RoleID       INT NOT NULL,
    IsActive     BIT NOT NULL DEFAULT 1,
    CreatedAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleID)
        REFERENCES dbo.Roles(RoleID)
);
GO

/* ============================================================
   Patients
   ============================================================ */

IF OBJECT_ID(N'dbo.Patients', N'U') IS NULL
CREATE TABLE dbo.Patients (
    PatientID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50)  NOT NULL,
    LastName  NVARCHAR(50)  NOT NULL,
    DOB       DATE          NULL,
    Gender    NVARCHAR(10)  NULL,
    Phone     NVARCHAR(20)  NOT NULL,
    Email     NVARCHAR(100) NULL,
    Address   NVARCHAR(200) NULL,
    IsActive  BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Patients_DOB CHECK (DOB IS NULL OR DOB <= CAST(SYSUTCDATETIME() AS DATE))
);
GO

/* ============================================================
   Doctors
   ============================================================ */

IF OBJECT_ID(N'dbo.Doctors', N'U') IS NULL
CREATE TABLE dbo.Doctors (
    DoctorID    INT IDENTITY(1,1) PRIMARY KEY,
    FirstName   NVARCHAR(50)  NOT NULL,
    LastName    NVARCHAR(50)  NOT NULL,
    SpecialtyID INT NOT NULL,
    Phone       NVARCHAR(20)  NULL,
    Email       NVARCHAR(100) NULL,
    IsActive    BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Doctors_Specialties FOREIGN KEY (SpecialtyID)
        REFERENCES dbo.Specialties(SpecialtyID)
);
GO

/* ============================================================
   Doctor weekly availability
   DayOfWeek: 1 = Monday ... 7 = Sunday
   ============================================================ */

IF OBJECT_ID(N'dbo.DoctorAvailability', N'U') IS NULL
CREATE TABLE dbo.DoctorAvailability (
    AvailabilityID INT IDENTITY(1,1) PRIMARY KEY,
    DoctorID    INT  NOT NULL,
    DayOfWeek   TINYINT NOT NULL,
    StartTime   TIME(0) NOT NULL,
    EndTime     TIME(0) NOT NULL,
    SlotMinutes INT NOT NULL DEFAULT 30,
    CONSTRAINT FK_Avail_Doctors FOREIGN KEY (DoctorID)
        REFERENCES dbo.Doctors(DoctorID),
    CONSTRAINT CK_Avail_Day  CHECK (DayOfWeek BETWEEN 1 AND 7),
    CONSTRAINT CK_Avail_Time CHECK (EndTime > StartTime),
    CONSTRAINT CK_Avail_Slot CHECK (SlotMinutes BETWEEN 5 AND 240)
);
GO

/* ============================================================
   Appointments
   ============================================================ */

IF OBJECT_ID(N'dbo.Appointments', N'U') IS NULL
CREATE TABLE dbo.Appointments (
    AppointmentID   INT IDENTITY(1,1) PRIMARY KEY,
    PatientID       INT NOT NULL,
    DoctorID        INT NOT NULL,
    RoomID          INT NULL,
    AppointmentDate DATE    NOT NULL,
    StartTime       TIME(0) NOT NULL,
    EndTime         TIME(0) NOT NULL,
    StatusID        INT NOT NULL,
    Reason          NVARCHAR(200) NULL,
    Notes           NVARCHAR(1000) NULL,
    CreatedBy       INT NOT NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ModifiedBy      INT NULL,
    ModifiedAt      DATETIME2 NULL,
    CONSTRAINT FK_Appt_Patients  FOREIGN KEY (PatientID)  REFERENCES dbo.Patients(PatientID),
    CONSTRAINT FK_Appt_Doctors   FOREIGN KEY (DoctorID)   REFERENCES dbo.Doctors(DoctorID),
    CONSTRAINT FK_Appt_Rooms     FOREIGN KEY (RoomID)     REFERENCES dbo.Rooms(RoomID),
    CONSTRAINT FK_Appt_Status    FOREIGN KEY (StatusID)   REFERENCES dbo.AppointmentStatuses(StatusID),
    CONSTRAINT FK_Appt_CreatedBy FOREIGN KEY (CreatedBy)  REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_Appt_ModBy     FOREIGN KEY (ModifiedBy) REFERENCES dbo.Users(UserID),
    CONSTRAINT CK_Appt_Time CHECK (EndTime > StartTime)
);
GO

/* ============================================================
   Audit log
   ============================================================ */

IF OBJECT_ID(N'dbo.AuditLog', N'U') IS NULL
CREATE TABLE dbo.AuditLog (
    LogID      BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID     INT NULL,
    Action     NVARCHAR(50)  NOT NULL,
    EntityType NVARCHAR(50)  NOT NULL,
    EntityID   INT NULL,
    Timestamp  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Details    NVARCHAR(1000) NULL,
    CONSTRAINT FK_Audit_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID)
);
GO

/* ============================================================
   Seed reference data (idempotent)
   ============================================================ */

IF NOT EXISTS (SELECT 1 FROM dbo.Roles)
    INSERT INTO dbo.Roles (RoleName)
    VALUES (N'Administrator'), (N'Receptionist'), (N'Doctor');

IF NOT EXISTS (SELECT 1 FROM dbo.AppointmentStatuses)
    INSERT INTO dbo.AppointmentStatuses (StatusName)
    VALUES (N'Scheduled'), (N'CheckedIn'), (N'Completed'), (N'Cancelled'), (N'NoShow');
GO
