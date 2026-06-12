# Clinic Appointment Scheduler (CAS) - Entity Relationship Diagram

```mermaid
erDiagram

    Roles {
        INT RoleID PK
        NVARCHAR RoleName
    }

    Users {
        INT UserID PK
        NVARCHAR Username
        VARBINARY PasswordHash
        VARBINARY Salt
        INT RoleID FK
        BIT IsActive
        DATETIME2 CreatedAt
    }

    Patients {
        INT PatientID PK
        NVARCHAR FirstName
        NVARCHAR LastName
        DATE DOB
        NVARCHAR Gender
        NVARCHAR Phone
        NVARCHAR Email
        NVARCHAR Address
        BIT IsActive
        DATETIME2 CreatedAt
    }

    Specialties {
        INT SpecialtyID PK
        NVARCHAR Name
    }

    Doctors {
        INT DoctorID PK
        NVARCHAR FirstName
        NVARCHAR LastName
        INT SpecialtyID FK
        NVARCHAR Phone
        NVARCHAR Email
        BIT IsActive
    }

    DoctorAvailability {
        INT AvailabilityID PK
        INT DoctorID FK
        TINYINT DayOfWeek
        TIME StartTime
        TIME EndTime
        INT SlotMinutes
    }

    Rooms {
        INT RoomID PK
        NVARCHAR Name
        BIT IsActive
    }

    AppointmentStatuses {
        INT StatusID PK
        NVARCHAR StatusName
    }

    Appointments {
        INT AppointmentID PK
        INT PatientID FK
        INT DoctorID FK
        INT RoomID FK
        DATE AppointmentDate
        TIME StartTime
        TIME EndTime
        INT StatusID FK
        NVARCHAR Reason
        NVARCHAR Notes
        INT CreatedBy FK
        DATETIME2 CreatedAt
        INT ModifiedBy FK
        DATETIME2 ModifiedAt
    }

    AuditLog {
        BIGINT LogID PK
        INT UserID FK
        NVARCHAR Action
        NVARCHAR EntityType
        INT EntityID
        DATETIME2 Timestamp
        NVARCHAR Details
    }

    %% Relationships

    Roles ||--o{ Users : assigns

    Specialties ||--o{ Doctors : categorizes

    Doctors ||--o{ DoctorAvailability : has

    Patients ||--o{ Appointments : books
    Doctors ||--o{ Appointments : attends
    Rooms ||--o{ Appointments : hosts
    AppointmentStatuses ||--o{ Appointments : status

    Users ||--o{ Appointments : creates
    Users ||--o{ Appointments : modifies

    Users ||--o{ AuditLog : generates
```

---

## Relationship Summary

| Parent Entity | Child Entity | Relationship |
|--------------|-------------|--------------|
| Roles | Users | 1-to-Many |
| Specialties | Doctors | 1-to-Many |
| Doctors | DoctorAvailability | 1-to-Many |
| Patients | Appointments | 1-to-Many |
| Doctors | Appointments | 1-to-Many |
| Rooms | Appointments | 1-to-Many |
| AppointmentStatuses | Appointments | 1-to-Many |
| Users | Appointments (CreatedBy) | 1-to-Many |
| Users | Appointments (ModifiedBy) | 1-to-Many |
| Users | AuditLog | 1-to-Many |

---

## Core Business Flow

1. A **User** (Administrator, Receptionist, or Doctor) logs into the system.
2. A **Patient** books an appointment with a **Doctor**.
3. Each doctor belongs to a **Specialty**.
4. Doctors define their weekly availability in **DoctorAvailability**.
5. An **Appointment**:
   - belongs to one Patient,
   - belongs to one Doctor,
   - may use one Room,
   - has one Appointment Status.
6. All important actions are recorded in **AuditLog**.