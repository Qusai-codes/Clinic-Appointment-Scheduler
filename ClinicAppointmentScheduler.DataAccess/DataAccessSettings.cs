using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;

namespace ClinicAppointmentScheduler.DataAccess
{
    internal class DataAccessSettings
    {
        public static string ConnectionString
        {
            get
            {
                string? connectionString =
                    ConfigurationManager.ConnectionStrings["DefaultConnection"]?.ConnectionString;

                if (string.IsNullOrWhiteSpace(connectionString))
                {
                    throw new InvalidOperationException(
                        "Connection string 'DefaultConnection' was not found in App.config.");
                }

                return connectionString;
            }
        }
    }
}
