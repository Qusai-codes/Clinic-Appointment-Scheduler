**Software Requirements Specification**

Clinic Appointment Scheduler (CAS)

*A Windows Forms desktop application built on a three-tier architecture*

| Field | Value |
| :---- | :---- |
| Document | Software Requirements Specification (SRS) |
| Project | Clinic Appointment Scheduler (CAS) |
| Version | 1.0 |
| UI Technology | Windows Forms (C\# / .NET) |
| Data Access | ADO.NET (parameterized commands, stored procedures) |
| Database | Microsoft SQL Server |
| Architecture | Three-Tier (Presentation → Business Logic → Data Access) |
| Audience | Portfolio reviewers, hiring managers, the developer |

**Table of Contents**

# **1\. Introduction**

## **1.1 Purpose**

This document defines the functional and non-functional requirements for the Clinic Appointment Scheduler (CAS), a desktop application that enables clinic staff to manage patients, doctors, schedules, and appointments. It is intended to fully specify the system before implementation and to serve as a reference for the developer building the project as a portfolio piece.

## **1.2 Scope**

CAS is a single-clinic, multi-user Windows desktop application. Receptionists book and manage appointments; administrators manage doctors, rooms, and system users; doctors view their own schedules. The following are explicitly out of scope for version 1.0:

* Billing, payments, and insurance processing.

* Electronic medical records and clinical documentation.

* Online patient self-booking.

* SMS or email gateways (modeled only as a logging interface stub).

## **1.3 Definitions, Acronyms, and Abbreviations**

| Term | Definition |
| :---- | :---- |
| Slot | A bookable time block for a doctor (for example, 30 minutes). |
| Appointment | A slot reserved for a specific patient. |
| No-show | A patient who did not arrive for a confirmed appointment. |
| CAS | Clinic Appointment Scheduler (this system). |
| BLL | Business Logic Layer. |
| DAL | Data Access Layer. |
| POCO | Plain Old CLR Object — a simple data-carrying class. |

## **1.4 Technology Constraints**

* **User interface:** Windows Forms (C\#, .NET).

* **Data access:** ADO.NET using SqlConnection and SqlCommand with parameterized queries and stored procedures.

* **Database:** Microsoft SQL Server.

* **Architecture:** Strict three-tier separation, with each tier implemented as a distinct project / class library.

# **2\. Architecture Overview**

CAS follows a strict three-tier architecture. Each tier is a separate project so that dependencies flow in one direction only. The diagram below shows the project structure and the references between layers.

ClinicScheduler.UI        (WinForms)        \-\> references BLL only  
ClinicScheduler.BLL       (Business Logic)  \-\> references DAL \+ Entities  
ClinicScheduler.DAL       (Data Access)     \-\> references Entities, uses ADO.NET  
ClinicScheduler.Entities  (POCOs / DTOs)    \-\> referenced by all layers

## **2.1 Separation Rules**

The following rules keep the tiers cleanly separated. Reviewers specifically look for these:

* The UI never opens a SqlConnection and never references System.Data.SqlClient.

* The BLL contains all validation and business rules and contains no SQL.

* The DAL contains all SQL and ADO.NET code and makes no business decisions.

* Entities are plain C\# objects passed between layers.

* The connection string lives in App.config and is read only by the DAL.

# **3\. User Roles**

| Role | Capabilities |
| :---- | :---- |
| Administrator | Manage users, doctors, specialties, and rooms; view all appointments; run reports. |
| Receptionist | Manage patients; book, reschedule, cancel, and check in appointments; view all schedules. |
| Doctor | View own schedule; mark appointments as completed or no-show. |

# **4\. Functional Requirements**

## **4.1 Authentication (FR-1)**

| ID | Requirement |
| :---- | :---- |
| FR-1.1 | Users log in with a username and password. |
| FR-1.2 | Passwords are stored as salted hashes; plaintext is never persisted. |
| FR-1.3 | A failed login shows a generic error message. Lock the UI after 5 consecutive failures (optional stretch). |
| FR-1.4 | The user's role determines which menus and forms are enabled. |

## **4.2 Patient Management (FR-2)**

| ID | Requirement |
| :---- | :---- |
| FR-2.1 | Create a patient with first name, last name, date of birth, gender, phone, email, and address. First name, last name, and phone are required. |
| FR-2.2 | Search patients by name or phone using partial matching. |
| FR-2.3 | Edit and soft-delete (deactivate) patients. A patient with existing appointments is never hard-deleted. |
| FR-2.4 | Validate phone format, email format, and that the date of birth is not in the future. |

## **4.3 Doctor & Resource Management (FR-3) — Administrator only**

| ID | Requirement |
| :---- | :---- |
| FR-3.1 | Create, read, update, and delete doctors, each with one assigned specialty. |
| FR-3.2 | Define each doctor's weekly availability: day of week, start time, end time, and slot length. |
| FR-3.3 | Create, read, update, and delete specialties and consultation rooms. |

## **4.4 Appointment Scheduling (FR-4) — Core feature**

| ID | Requirement |
| :---- | :---- |
| FR-4.1 | After selecting a doctor and date, the system generates available slots from the doctor's availability minus already-booked appointments. |
| FR-4.2 | Book a slot for a patient and capture a reason or notes. |
| FR-4.3 | No double-booking: a doctor cannot have two appointments that overlap in time. Enforced in the BLL and by a transaction in the DAL to avoid race conditions between two receptionists. |
| FR-4.4 | Reschedule: move an existing appointment to another open slot. |
| FR-4.5 | Cancel an appointment with a reason; its status becomes Cancelled. |
| FR-4.6 | Status lifecycle: Scheduled → CheckedIn → Completed; or Scheduled → Cancelled; or Scheduled → NoShow. |
| FR-4.7 | Appointments cannot be booked in the past. |
| FR-4.8 | A patient cannot be booked into two overlapping appointments, even with different doctors. |

## **4.5 Daily View / Dashboard (FR-5)**

| ID | Requirement |
| :---- | :---- |
| FR-5.1 | Display a selected day's appointments in a grid or calendar, grouped by doctor. |
| FR-5.2 | Color-code appointments by status. |
| FR-5.3 | Allow quick check-in or mark no-show directly from the grid. |

## **4.6 Reporting (FR-6)**

| ID | Requirement |
| :---- | :---- |
| FR-6.1 | Appointments per doctor over a chosen date range. |
| FR-6.2 | No-show count and rate per doctor. |
| FR-6.3 | Daily appointment list, printable or exportable to CSV. |

## **4.7 Audit Log (FR-7) — Stretch**

| ID | Requirement |
| :---- | :---- |
| FR-7.1 | Record who created, modified, or cancelled each appointment, and when. |

# **5\. Non-Functional Requirements**

| ID | Category | Requirement |
| :---- | :---- | :---- |
| NFR-1 | Security | All SQL is parameterized; no string concatenation. This prevents SQL injection and should be stated explicitly in the README. |
| NFR-2 | Performance | Common queries (slot lookup, daily view) return in under 1 second on a few thousand rows. Index foreign keys and the (DoctorID, AppointmentDate) pair. |
| NFR-3 | Reliability | Booking uses a transaction with an appropriate isolation level (for example SERIALIZABLE) or a unique constraint, so concurrent bookings cannot both succeed. |
| NFR-4 | Usability | Forms are keyboard-navigable, show inline validation messages, and present confirmation dialogs on cancel or delete. |
| NFR-5 | Maintainability | Layer boundaries are clear; no business logic lives in UI event handlers. |
| NFR-6 | Configurability | The connection string and slot defaults are stored in App.config. |

# **6\. Data Model (Logical)**

## **6.1 Tables**

| Table | Key Columns |
| :---- | :---- |
| Users | UserID (PK), Username (unique), PasswordHash, Salt, RoleID (FK), IsActive |
| Roles | RoleID (PK), RoleName |
| Patients | PatientID (PK), FirstName, LastName, DOB, Gender, Phone, Email, Address, IsActive |
| Specialties | SpecialtyID (PK), Name |
| Doctors | DoctorID (PK), FirstName, LastName, SpecialtyID (FK), Phone, Email, IsActive |
| DoctorAvailability | AvailabilityID (PK), DoctorID (FK), DayOfWeek, StartTime, EndTime, SlotMinutes |
| Rooms | RoomID (PK), Name, IsActive |
| Appointments | AppointmentID (PK), PatientID (FK), DoctorID (FK), RoomID (FK, nullable), AppointmentDate, StartTime, EndTime, StatusID (FK), Reason, Notes, CreatedBy, CreatedAt, ModifiedBy, ModifiedAt |
| AppointmentStatuses | StatusID (PK), StatusName (Scheduled, CheckedIn, Completed, Cancelled, NoShow) |
| AuditLog | LogID (PK), UserID, Action, EntityType, EntityID, Timestamp, Details |

## **6.2 Key Constraints**

* A uniqueness / overlap guard on (DoctorID, AppointmentDate, time range) for all non-cancelled appointments.

* Foreign keys use NO ACTION on delete, forcing soft-deletes in application logic.

# **7\. Stored Procedures (DAL Targets)**

These stored procedures form the contract between the DAL and the database. The booking procedure is transactional and re-checks for overlap immediately before inserting.

| Procedure | Purpose |
| :---- | :---- |
| usp\_Login | Authenticate a user and return role information. |
| usp\_GetAvailableSlots(@DoctorID, @Date) | Return open slots for a doctor on a date. |
| usp\_BookAppointment | Transactionally re-check for overlap, then insert the appointment. |
| usp\_RescheduleAppointment | Move an appointment to a new slot, re-checking availability. |
| usp\_CancelAppointment | Set an appointment's status to Cancelled with a reason. |
| usp\_GetDailySchedule(@Date) | Return all appointments for a day, grouped by doctor. |
| usp\_GetNoShowReport(@From, @To) | Return no-show counts and rates per doctor for a range. |

# **8\. Assumptions**

* The system serves a single clinic in a single time zone.

* Recurring appointments are not supported in version 1.0 (stretch goal).

* No payment or insurance handling is included.