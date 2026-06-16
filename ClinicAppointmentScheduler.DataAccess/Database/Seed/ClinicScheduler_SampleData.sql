/* ============================================================
   Clinic Appointment Scheduler (CAS)
   Seed data only
   ------------------------------------------------------------
   Target : Microsoft SQL Server (2017+ recommended)
   Run    : Execute after creating the ClinicScheduler schema.

   Notes:
   - Idempotent: uses natural keys and NOT EXISTS checks.
   - Integrity-safe: all foreign keys are resolved from existing/seeded rows.
   - Semantic consistency: appointments are placed on days and times that match
     the seeded doctors' weekly availability and avoid overlapping patients/doctors.
   ============================================================ */

IF DB_ID(N'ClinicScheduler') IS NULL
BEGIN
    THROW 51000, N'Database ClinicScheduler does not exist. Run the schema script first.', 1;
END
GO

USE ClinicScheduler;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    /* ------------------------------------------------------------
       Required lookup/reference data
       ------------------------------------------------------------ */
    IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'Administrator')
        INSERT INTO dbo.Roles (RoleName) VALUES (N'Administrator');

    IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'Receptionist')
        INSERT INTO dbo.Roles (RoleName) VALUES (N'Receptionist');

    IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'Doctor')
        INSERT INTO dbo.Roles (RoleName) VALUES (N'Doctor');

    IF NOT EXISTS (SELECT 1 FROM dbo.AppointmentStatuses WHERE StatusName = N'Scheduled')
        INSERT INTO dbo.AppointmentStatuses (StatusName) VALUES (N'Scheduled');

    IF NOT EXISTS (SELECT 1 FROM dbo.AppointmentStatuses WHERE StatusName = N'CheckedIn')
        INSERT INTO dbo.AppointmentStatuses (StatusName) VALUES (N'CheckedIn');

    IF NOT EXISTS (SELECT 1 FROM dbo.AppointmentStatuses WHERE StatusName = N'Completed')
        INSERT INTO dbo.AppointmentStatuses (StatusName) VALUES (N'Completed');

    IF NOT EXISTS (SELECT 1 FROM dbo.AppointmentStatuses WHERE StatusName = N'Cancelled')
        INSERT INTO dbo.AppointmentStatuses (StatusName) VALUES (N'Cancelled');

    IF NOT EXISTS (SELECT 1 FROM dbo.AppointmentStatuses WHERE StatusName = N'NoShow')
        INSERT INTO dbo.AppointmentStatuses (StatusName) VALUES (N'NoShow');

    INSERT INTO dbo.Specialties (Name)
    SELECT v.Name
    FROM (VALUES
        (N'General Practice'),
        (N'Pediatrics'),
        (N'Cardiology'),
        (N'Dermatology'),
        (N'Orthopedics')
    ) AS v(Name)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Specialties s WHERE s.Name = v.Name
    );

    INSERT INTO dbo.Rooms (Name, IsActive)
    SELECT v.Name, v.IsActive
    FROM (VALUES
        (N'Exam Room 1', 1),
        (N'Exam Room 2', 1),
        (N'Pediatrics Room', 1),
        (N'Cardiology Room', 1),
        (N'Procedure Room', 1)
    ) AS v(Name, IsActive)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Rooms r WHERE r.Name = v.Name
    );

    /* ------------------------------------------------------------
       Users
       Demo password for seeded users: DemoPassword!23
       PasswordHash values are illustrative SHA2_256 hashes for seed/demo data.
       ------------------------------------------------------------ */
    INSERT INTO dbo.Users (Username, PasswordHash, Salt, RoleID, IsActive)
    SELECT v.Username,
           HASHBYTES('SHA2_256', v.HashInput),
           HASHBYTES('SHA2_256', v.SaltText),
           r.RoleID,
           1
    FROM (VALUES
        (N'admin.cas',       N'Administrator', N'clinic-demo-salt-admin',     N'DemoPassword!23:admin.cas'),
        (N'reception.anna',  N'Receptionist',  N'clinic-demo-salt-anna',      N'DemoPassword!23:reception.anna'),
        (N'reception.omar',  N'Receptionist',  N'clinic-demo-salt-omar',      N'DemoPassword!23:reception.omar'),
        (N'doctor.carter',   N'Doctor',        N'clinic-demo-salt-carter',    N'DemoPassword!23:doctor.carter'),
        (N'doctor.bennett',  N'Doctor',        N'clinic-demo-salt-bennett',   N'DemoPassword!23:doctor.bennett'),
        (N'doctor.nguyen',   N'Doctor',        N'clinic-demo-salt-nguyen',    N'DemoPassword!23:doctor.nguyen'),
        (N'doctor.moreno',   N'Doctor',        N'clinic-demo-salt-moreno',    N'DemoPassword!23:doctor.moreno'),
        (N'doctor.wilson',   N'Doctor',        N'clinic-demo-salt-wilson',    N'DemoPassword!23:doctor.wilson')
    ) AS v(Username, RoleName, SaltText, HashInput)
    JOIN dbo.Roles r ON r.RoleName = v.RoleName
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Users u WHERE u.Username = v.Username
    );

    /* ------------------------------------------------------------
       Patients
       Phone is used as the natural seed key.
       ------------------------------------------------------------ */
    INSERT INTO dbo.Patients
        (FirstName, LastName, DOB, Gender, Phone, Email, Address, IsActive)
    SELECT v.FirstName,
           v.LastName,
           v.DOB,
           v.Gender,
           v.Phone,
           v.Email,
           v.Address,
           1
    FROM (VALUES
        (N'John',   N'Miller',  CONVERT(date, '1984-03-12'), N'Male',   N'+40-721-555-0101', N'john.miller@example.com',   N'12 Linden Street, Bucharest'),
        (N'Maria',  N'Garcia',  CONVERT(date, '1991-07-25'), N'Female', N'+40-721-555-0102', N'maria.garcia@example.com',  N'8 Carol Avenue, Bucharest'),
        (N'Olivia', N'Brown',   CONVERT(date, '2016-11-03'), N'Female', N'+40-721-555-0103', N'olivia.brown@example.com',  N'21 School Road, Bucharest'),
        (N'Ahmed',  N'Khan',    CONVERT(date, '1978-01-30'), N'Male',   N'+40-721-555-0104', N'ahmed.khan@example.com',    N'4 Oak Lane, Bucharest'),
        (N'Chen',   N'Wei',     CONVERT(date, '1989-09-18'), N'Male',   N'+40-721-555-0105', N'chen.wei@example.com',      N'17 Park View, Bucharest'),
        (N'Grace',  N'Johnson', CONVERT(date, '1965-05-09'), N'Female', N'+40-721-555-0106', N'grace.johnson@example.com', N'33 Central Square, Bucharest'),
        (N'Daniel', N'Smith',   CONVERT(date, '2009-02-14'), N'Male',   N'+40-721-555-0107', N'daniel.smith@example.com',  N'5 River Walk, Bucharest'),
        (N'Fatima', N'Ali',     CONVERT(date, '1995-12-02'), N'Female', N'+40-721-555-0108', N'fatima.ali@example.com',    N'19 Maple Court, Bucharest')
    ) AS v(FirstName, LastName, DOB, Gender, Phone, Email, Address)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Patients p WHERE p.Phone = v.Phone
    );

    /* ------------------------------------------------------------
       Doctors
       Email is used as the natural seed key.
       ------------------------------------------------------------ */
    INSERT INTO dbo.Doctors
        (FirstName, LastName, SpecialtyID, Phone, Email, IsActive)
    SELECT v.FirstName,
           v.LastName,
           s.SpecialtyID,
           v.Phone,
           v.Email,
           1
    FROM (VALUES
        (N'Amelia', N'Carter',  N'General Practice', N'+40-731-555-0201', N'amelia.carter@clinic.example'),
        (N'Noah',   N'Bennett', N'Pediatrics',       N'+40-731-555-0202', N'noah.bennett@clinic.example'),
        (N'Sophia', N'Nguyen',  N'Cardiology',       N'+40-731-555-0203', N'sophia.nguyen@clinic.example'),
        (N'Lucas',  N'Moreno',  N'Dermatology',      N'+40-731-555-0204', N'lucas.moreno@clinic.example'),
        (N'Emma',   N'Wilson',  N'Orthopedics',      N'+40-731-555-0205', N'emma.wilson@clinic.example')
    ) AS v(FirstName, LastName, SpecialtyName, Phone, Email)
    JOIN dbo.Specialties s ON s.Name = v.SpecialtyName
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Doctors d WHERE d.Email = v.Email
    );

    /* ------------------------------------------------------------
       Doctor weekly availability
       DayOfWeek: 1 = Monday ... 7 = Sunday
       ------------------------------------------------------------ */
    INSERT INTO dbo.DoctorAvailability
        (DoctorID, DayOfWeek, StartTime, EndTime, SlotMinutes)
    SELECT d.DoctorID,
           v.DayOfWeek,
           CONVERT(time(0), v.StartTime),
           CONVERT(time(0), v.EndTime),
           v.SlotMinutes
    FROM (VALUES
        (N'amelia.carter@clinic.example', CONVERT(tinyint, 1), '09:00', '13:00', 30),
        (N'amelia.carter@clinic.example', CONVERT(tinyint, 3), '09:00', '13:00', 30),
        (N'noah.bennett@clinic.example',  CONVERT(tinyint, 2), '10:00', '15:00', 30),
        (N'noah.bennett@clinic.example',  CONVERT(tinyint, 4), '10:00', '15:00', 30),
        (N'sophia.nguyen@clinic.example', CONVERT(tinyint, 1), '14:00', '17:00', 30),
        (N'sophia.nguyen@clinic.example', CONVERT(tinyint, 5), '09:00', '12:00', 30),
        (N'lucas.moreno@clinic.example',  CONVERT(tinyint, 3), '13:00', '17:00', 30),
        (N'emma.wilson@clinic.example',   CONVERT(tinyint, 2), '09:00', '12:00', 30),
        (N'emma.wilson@clinic.example',   CONVERT(tinyint, 5), '13:00', '16:00', 30)
    ) AS v(DoctorEmail, DayOfWeek, StartTime, EndTime, SlotMinutes)
    JOIN dbo.Doctors d ON d.Email = v.DoctorEmail
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.DoctorAvailability da
        WHERE da.DoctorID = d.DoctorID
          AND da.DayOfWeek = v.DayOfWeek
          AND da.StartTime = CONVERT(time(0), v.StartTime)
          AND da.EndTime = CONVERT(time(0), v.EndTime)
    );

    /* ------------------------------------------------------------
       Appointment dates
       1900-01-01 was a Monday in SQL Server's date system.
       The calculations below find the next future weekday independent of DATEFIRST.
       ------------------------------------------------------------ */
    DECLARE @Today date = CAST(SYSUTCDATETIME() AS date);
    DECLARE @DayIndex int = DATEDIFF(day, CONVERT(date, '19000101'), @Today) % 7; -- 0=Monday ... 6=Sunday

    DECLARE @NextMonday date = DATEADD(day, CASE WHEN (0 - @DayIndex + 7) % 7 = 0 THEN 7 ELSE (0 - @DayIndex + 7) % 7 END, @Today);
    DECLARE @NextTuesday date = DATEADD(day, CASE WHEN (1 - @DayIndex + 7) % 7 = 0 THEN 7 ELSE (1 - @DayIndex + 7) % 7 END, @Today);
    DECLARE @NextWednesday date = DATEADD(day, CASE WHEN (2 - @DayIndex + 7) % 7 = 0 THEN 7 ELSE (2 - @DayIndex + 7) % 7 END, @Today);
    DECLARE @NextThursday date = DATEADD(day, CASE WHEN (3 - @DayIndex + 7) % 7 = 0 THEN 7 ELSE (3 - @DayIndex + 7) % 7 END, @Today);
    DECLARE @NextFriday date = DATEADD(day, CASE WHEN (4 - @DayIndex + 7) % 7 = 0 THEN 7 ELSE (4 - @DayIndex + 7) % 7 END, @Today);

    /* ------------------------------------------------------------
       Appointments
       All appointments below:
       - reference existing/seeded patients, doctors, rooms, statuses, and users;
       - fit inside the doctor's availability window;
       - avoid overlapping appointments for the same doctor and patient.
       ------------------------------------------------------------ */
    ;WITH AppointmentSeed AS (
        SELECT *
        FROM (VALUES
            (N'+40-721-555-0101', N'amelia.carter@clinic.example', N'Exam Room 1',      @NextMonday,    '09:00', '09:30', N'Scheduled', N'Annual wellness visit',      N'First visit with the clinic.',       N'reception.anna'),
            (N'+40-721-555-0102', N'sophia.nguyen@clinic.example', N'Cardiology Room',  @NextMonday,    '14:00', '14:30', N'Scheduled', N'Blood pressure follow-up',    N'Bring home BP readings.',           N'reception.anna'),
            (N'+40-721-555-0108', N'sophia.nguyen@clinic.example', N'Cardiology Room',  @NextMonday,    '14:30', '15:00', N'CheckedIn', N'Palpitations consultation',   N'ECG may be required.',              N'reception.omar'),
            (N'+40-721-555-0103', N'noah.bennett@clinic.example',  N'Pediatrics Room',  @NextTuesday,   '10:00', '10:30', N'Scheduled', N'Pediatric check-up',          N'Routine growth and vaccination review.', N'reception.anna'),
            (N'+40-721-555-0104', N'emma.wilson@clinic.example',   N'Exam Room 2',      @NextTuesday,   '09:00', '09:30', N'Scheduled', N'Knee pain consultation',      N'Possible sports injury.',           N'reception.omar'),
            (N'+40-721-555-0105', N'lucas.moreno@clinic.example',  N'Procedure Room',   @NextWednesday, '13:00', '13:30', N'Scheduled', N'Skin rash evaluation',        N'Rash on forearm for one week.',     N'reception.anna'),
            (N'+40-721-555-0106', N'amelia.carter@clinic.example', N'Exam Room 1',      @NextWednesday, '09:30', '10:00', N'Scheduled', N'Diabetes follow-up',          N'Review recent lab results.',        N'reception.omar'),
            (N'+40-721-555-0107', N'noah.bennett@clinic.example',  N'Pediatrics Room',  @NextThursday,  '11:00', '11:30', N'Scheduled', N'School physical examination', N'Patient needs school medical form.', N'reception.anna'),
            (N'+40-721-555-0108', N'sophia.nguyen@clinic.example', N'Cardiology Room',  @NextFriday,    '09:30', '10:00', N'Scheduled', N'Cardiology follow-up',        N'Follow-up after initial consultation.', N'reception.omar'),
            (N'+40-721-555-0104', N'emma.wilson@clinic.example',   N'Exam Room 2',      @NextFriday,    '13:00', '13:30', N'Cancelled', N'Orthopedic follow-up',        N'Patient cancelled and will reschedule.', N'reception.anna')
        ) AS v(PatientPhone, DoctorEmail, RoomName, AppointmentDate, StartTime, EndTime, StatusName, Reason, Notes, CreatedByUsername)
    )
    INSERT INTO dbo.Appointments
        (PatientID, DoctorID, RoomID, AppointmentDate, StartTime, EndTime,
         StatusID, Reason, Notes, CreatedBy, CreatedAt)
    SELECT p.PatientID,
           d.DoctorID,
           r.RoomID,
           a.AppointmentDate,
           CONVERT(time(0), a.StartTime),
           CONVERT(time(0), a.EndTime),
           s.StatusID,
           a.Reason,
           a.Notes,
           u.UserID,
           SYSUTCDATETIME()
    FROM AppointmentSeed a
    JOIN dbo.Patients p ON p.Phone = a.PatientPhone
    JOIN dbo.Doctors d ON d.Email = a.DoctorEmail
    JOIN dbo.Rooms r ON r.Name = a.RoomName
    JOIN dbo.AppointmentStatuses s ON s.StatusName = a.StatusName
    JOIN dbo.Users u ON u.Username = a.CreatedByUsername
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.Appointments existing
        WHERE existing.PatientID = p.PatientID
          AND existing.DoctorID = d.DoctorID
          AND existing.AppointmentDate = a.AppointmentDate
          AND existing.StartTime = CONVERT(time(0), a.StartTime)
          AND existing.EndTime = CONVERT(time(0), a.EndTime)
    )
      AND EXISTS (
        SELECT 1
        FROM dbo.DoctorAvailability da
        WHERE da.DoctorID = d.DoctorID
          AND da.DayOfWeek = CONVERT(tinyint, (DATEDIFF(day, CONVERT(date, '19000101'), a.AppointmentDate) % 7) + 1)
          AND da.StartTime <= CONVERT(time(0), a.StartTime)
          AND CONVERT(time(0), a.EndTime) <= da.EndTime
    )
      AND (
        a.StatusName = N'Cancelled'
        OR NOT EXISTS (
            SELECT 1
            FROM dbo.Appointments existingDoctor
            JOIN dbo.AppointmentStatuses existingStatus
              ON existingStatus.StatusID = existingDoctor.StatusID
            WHERE existingDoctor.DoctorID = d.DoctorID
              AND existingDoctor.AppointmentDate = a.AppointmentDate
              AND existingStatus.StatusName <> N'Cancelled'
              AND existingDoctor.StartTime < CONVERT(time(0), a.EndTime)
              AND CONVERT(time(0), a.StartTime) < existingDoctor.EndTime
        )
    )
      AND (
        a.StatusName = N'Cancelled'
        OR NOT EXISTS (
            SELECT 1
            FROM dbo.Appointments existingPatient
            JOIN dbo.AppointmentStatuses existingStatus
              ON existingStatus.StatusID = existingPatient.StatusID
            WHERE existingPatient.PatientID = p.PatientID
              AND existingPatient.AppointmentDate = a.AppointmentDate
              AND existingStatus.StatusName <> N'Cancelled'
              AND existingPatient.StartTime < CONVERT(time(0), a.EndTime)
              AND CONVERT(time(0), a.StartTime) < existingPatient.EndTime
        )
    );

    /* ------------------------------------------------------------
       Audit log entries for seeded appointments
       ------------------------------------------------------------ */
    ;WITH AppointmentSeed AS (
        SELECT *
        FROM (VALUES
            (N'+40-721-555-0101', N'amelia.carter@clinic.example', @NextMonday,    '09:00', N'reception.anna'),
            (N'+40-721-555-0102', N'sophia.nguyen@clinic.example', @NextMonday,    '14:00', N'reception.anna'),
            (N'+40-721-555-0108', N'sophia.nguyen@clinic.example', @NextMonday,    '14:30', N'reception.omar'),
            (N'+40-721-555-0103', N'noah.bennett@clinic.example',  @NextTuesday,   '10:00', N'reception.anna'),
            (N'+40-721-555-0104', N'emma.wilson@clinic.example',   @NextTuesday,   '09:00', N'reception.omar'),
            (N'+40-721-555-0105', N'lucas.moreno@clinic.example',  @NextWednesday, '13:00', N'reception.anna'),
            (N'+40-721-555-0106', N'amelia.carter@clinic.example', @NextWednesday, '09:30', N'reception.omar'),
            (N'+40-721-555-0107', N'noah.bennett@clinic.example',  @NextThursday,  '11:00', N'reception.anna'),
            (N'+40-721-555-0108', N'sophia.nguyen@clinic.example', @NextFriday,    '09:30', N'reception.omar'),
            (N'+40-721-555-0104', N'emma.wilson@clinic.example',   @NextFriday,    '13:00', N'reception.anna')
        ) AS v(PatientPhone, DoctorEmail, AppointmentDate, StartTime, CreatedByUsername)
    )
    INSERT INTO dbo.AuditLog (UserID, Action, EntityType, EntityID, Details)
    SELECT u.UserID,
           N'Create',
           N'Appointment',
           ap.AppointmentID,
           CONCAT(N'Seeded appointment: Doctor=', d.DoctorID,
                  N', Patient=', p.PatientID,
                  N', ', CONVERT(nvarchar(10), ap.AppointmentDate, 120),
                  N' ', CONVERT(nvarchar(5), ap.StartTime, 108))
    FROM AppointmentSeed seed
    JOIN dbo.Patients p ON p.Phone = seed.PatientPhone
    JOIN dbo.Doctors d ON d.Email = seed.DoctorEmail
    JOIN dbo.Users u ON u.Username = seed.CreatedByUsername
    JOIN dbo.Appointments ap
      ON ap.PatientID = p.PatientID
     AND ap.DoctorID = d.DoctorID
     AND ap.AppointmentDate = seed.AppointmentDate
     AND ap.StartTime = CONVERT(time(0), seed.StartTime)
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.AuditLog log
        WHERE log.Action = N'Create'
          AND log.EntityType = N'Appointment'
          AND log.EntityID = ap.AppointmentID
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO

/* Optional verification summary */
SELECT N'Roles' AS Entity, COUNT(*) AS TotalRows FROM dbo.Roles
UNION ALL SELECT N'AppointmentStatuses', COUNT(*) FROM dbo.AppointmentStatuses
UNION ALL SELECT N'Specialties', COUNT(*) FROM dbo.Specialties
UNION ALL SELECT N'Rooms', COUNT(*) FROM dbo.Rooms
UNION ALL SELECT N'Users', COUNT(*) FROM dbo.Users
UNION ALL SELECT N'Patients', COUNT(*) FROM dbo.Patients
UNION ALL SELECT N'Doctors', COUNT(*) FROM dbo.Doctors
UNION ALL SELECT N'DoctorAvailability', COUNT(*) FROM dbo.DoctorAvailability
UNION ALL SELECT N'Appointments', COUNT(*) FROM dbo.Appointments
UNION ALL SELECT N'AuditLog', COUNT(*) FROM dbo.AuditLog;
GO
