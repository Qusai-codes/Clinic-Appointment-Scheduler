using System;
using System.Collections.Generic;
using Microsoft.Data.SqlClient;
using System.Data;
using System.Text;

namespace ClinicAppointmentScheduler.DataAccess
{
    public class UserData
    {
        public static bool GetUserInfoByID(
            int userID,
            out string userName,
            out int roleID,
            out bool isActive,
            out DateTime createdAt)
        {
            bool isFound = false;

            userName = string.Empty;
            roleID = -1;
            isActive = false;
            createdAt = DateTime.MinValue;

            const string query = @"
                SELECT 
                    Username,
                    RoleID,
                    IsActive,
                    CreatedAt
                FROM dbo.Users
                WHERE UserID = @UserID;
            ";

            using (SqlConnection connection = new SqlConnection(DataAccessSettings.ConnectionString))
            using (SqlCommand command = new SqlCommand(query, connection))
            {
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userID;

                try
                {
                    connection.Open();

                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            userName = (string)reader["Username"];
                            roleID = (int)reader["RoleID"];
                            isActive = (bool)reader["IsActive"];
                            createdAt = (DateTime)reader["CreatedAt"];

                            isFound = true;
                        }
                    }
                }
                catch
                {
                    isFound = false;
                }
            }

            return isFound;
        }

        public static int AddNewUser(
            string userName, byte[] passwordHash, 
            byte[] salt, int roleID, bool isActive, DateTime createdAt)
        {
            int userId = -1;

            const string query = @"
            INSERT  INTO dbo.Users (Username, PasswordHash, Salt, RoleID, IsActive, CreatedAt)
            VALUES                (@Username, @PasswordHash, @Salt, @RoleID, @IsActive, @CreatedAt);

            SELECT CAST(SCOPE_IDENTITY() AS INT);
            ";

            using (SqlConnection connection = new SqlConnection(DataAccessSettings.ConnectionString))
            using (SqlCommand command = new SqlCommand(query, connection))
            {
                command.Parameters.Add("@Username", SqlDbType.NVarChar, 50).Value = userName;
                command.Parameters.Add("@PasswordHash", SqlDbType.VarBinary, 64).Value = passwordHash;
                command.Parameters.Add("@Salt", SqlDbType.VarBinary, 32).Value = salt;
                command.Parameters.Add("@RoleID", SqlDbType.Int).Value = roleID;
                command.Parameters.Add("@IsActive", SqlDbType.Bit).Value = isActive;
                command.Parameters.Add("@CreatedAt", SqlDbType.DateTime2, 7).Value = createdAt;

                try
                {
                    connection.Open();

                    object result = command.ExecuteScalar();

                    if (result != null && result != DBNull.Value)
                    {
                        userId = Convert.ToInt32(result);
                    }
                }
                catch
                {

                    userId = -1;
                }
            }

            return userId;
        }

        public static bool UpdateUser(
            int userID,
            string userName,
            int roleID,
            bool isActive)
        {
            int rowsAffected = 0;

            const string query = @"
                UPDATE dbo.Users
                SET
                    Username = @Username,
                    RoleID = @RoleID,
                    IsActive = @IsActive
                WHERE UserID = @UserID;
            ";

            using (SqlConnection connection = new SqlConnection(DataAccessSettings.ConnectionString))
            using (SqlCommand command = new SqlCommand(query, connection))
            {
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userID;
                command.Parameters.Add("@Username", SqlDbType.NVarChar, 50).Value = userName;
                command.Parameters.Add("@RoleID", SqlDbType.Int).Value = roleID;
                command.Parameters.Add("@IsActive", SqlDbType.Bit).Value = isActive;

                try
                {
                    connection.Open();
                    rowsAffected = command.ExecuteNonQuery();
                }
                catch
                {
                    rowsAffected = 0;
                }
            }

            return rowsAffected > 0;
        }

        public static bool UpdatePassword(
            int userID,
            byte[] passwordHash,
            byte[] salt)
        {
            int rowsAffected = 0;

            const string query = @"
                UPDATE dbo.Users
                SET
                    PasswordHash = @PasswordHash,
                    Salt = @Salt
                WHERE UserID = @UserID;
            ";

            using (SqlConnection connection = new SqlConnection(DataAccessSettings.ConnectionString))
            using (SqlCommand command = new SqlCommand(query, connection))
            {
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userID;
                command.Parameters.Add("@PasswordHash", SqlDbType.VarBinary, 64).Value = passwordHash;
                command.Parameters.Add("@Salt", SqlDbType.VarBinary, 32).Value = salt;

                try
                {
                    connection.Open();
                    rowsAffected = command.ExecuteNonQuery();
                }
                catch
                {
                    rowsAffected = 0;
                }
            }

            return rowsAffected > 0;
        }


        // A soft delete of the user, deactivating instead of deletion.
        public static bool DeleteUser(int userID)
        {
            int rowsAffected = 0;

            const string query = @"
                UPDATE dbo.Users
                SET IsActive = 0
                WHERE UserID = @UserID
                  AND IsActive = 1;
            ";

            using (SqlConnection connection = new SqlConnection(DataAccessSettings.ConnectionString))
            using (SqlCommand command = new SqlCommand(query, connection))
            {
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userID;

                try
                {
                    connection.Open();

                    rowsAffected = command.ExecuteNonQuery();
                }
                catch
                {
                    rowsAffected = 0;
                }
            }

            return rowsAffected > 0;
        }
    }
}
