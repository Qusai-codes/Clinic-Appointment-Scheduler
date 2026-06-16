using System;
using System.Collections.Generic;
using System.Text;

namespace ClinicAppointmentScheduler.DataAccess
{
    public class UserData
    {
        public static int AddNewUser(string userName, byte[] passwordHashm, 
            byte[] salt, int roleID, bool isActive, DateTime createdAt)
        {
            int userId = -1;

            const string query = @"
            INSERT  INTO dbo.Users (Username, PasswordHash, Salt, RoleID, IsActive, CreatedAt)
            VALUES                (@Username, @PasswordHash, @Salt, @RoleID, @IsActive, @CreatedAt);

            SELECT SCOPE_IDENTITY();
            ";




            return userId;
        }
    }
}
