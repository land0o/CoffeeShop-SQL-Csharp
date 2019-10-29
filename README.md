# CoffeeShop-SQL-Csharp
practice setting up files in vs 2019 for a coffee shop
You can read the [Handle requests with controllers in ASP.NET Core MVC](https://docs.microsoft.com/en-us/aspnet/core/mvc/controllers/actions?view=aspnetcore-2.1) article to learn more about using controllers.

## HTTP Verbs Overview

### Create a new Web API via the command line

```sh
mkdir -p ~/workspace/csharp/webapi/coffee
cd ~/workspace/csharp/webapi/coffee
dotnet new sln -n CoffeeShop -o .
dotnet new webapi -n CoffeeShop
dotnet sln add CoffeeShop/CoffeeShop.csproj
cd CoffeeShop
dotnet add package System.Data.SqlClient
dotnet restore
cd ..
start CoffeeShop.sln
```

### Create a new Web API via Visual Studio

1. Click the File menu > New > Project...
1. Type in "api" into the search bar
1. Choose the _ASP .NET Core Web Application_ option
1. Click _Next_
1. Project name: CoffeeShop
1. Choose where you want to create the project
1. Click _Create_
1. Choose _API_ on the next screen
1. Uncheck the _Configure for HTTS_ checkbox
1. Once the project is loaded click the Tools menu > NuGet Package Manager > Manage NuGet Packages for Solution
1. Click the Browse tab at the top
1. Enter "system.data.sqlclient" in the search bar
1. Click that package in the search results
1. Make sure you check the box for your project on the right
1. Click the _Install_ button on the right of the screen
1. Click _Ok_ in the preview window that appears
1. Then you can close the NuGet Package Manager window


The default scaffolding provides you with a `ValuesController`. It's very basic, and your instruction team will discuss HTTP verbs of GET, POST, PUT, DELETE. Then you will construct a simple coffee shop database, some data models, and a more complex controller that handles CRUD actions for coffee.

### The Database

1. Create a new SQL Server databased called `CoffeeShop`.
1. Use this script to create a table and populate it with some starter data.

```sql
DROP TABLE IF EXISTS Coffee;

CREATE TABLE Coffee (
    Id INTEGER NOT NULL PRIMARY KEY IDENTITY,
    Title VARCHAR(50) NOT NULL,
    BeanType VARCHAR(50) NOT NULL
);

INSERT INTO Coffee (Title, BeanType)
VALUES ('Espresso', 'Brazilian');

INSERT INTO Coffee (Title, BeanType)
VALUES ('Cafe Con Leche', 'Costa Rican');

INSERT INTO Coffee (Title, BeanType)
VALUES ('Cappuccino', 'Guatemalan');
```

Now you have a new database with one table that contains three rows of data.

### App Settings

In order for your Web API to connect to this database, you are going to put the connection string in the `appsettings.json` file in your project. Open that file and replace the contents with the following configuration.

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost\\SQLEXPRESS;Database=CoffeeShop;Trusted_Connection=True;"
  }
}
```

### Coffee Model

Create a `Models` directory in your project and add a new class named `Coffee` in that directory. Put the following code in that file.

```cs
namespace CoffeeShop.Models
{
    public class Coffee
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string BeanType { get; set; }
    }
}
```

### Coffee Controller

Create a new controller file named `CoffeesController.cs` in the **`Controllers`** directory in your project. Replace the contents of that new file with the code below.

```cs
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System.Data;
using System.Data.SqlClient;
using CoffeeShop.Models;
using Microsoft.AspNetCore.Http;

namespace CoffeeShop.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CoffeesController : ControllerBase
    {
        private readonly IConfiguration _config;

        public CoffeesController(IConfiguration config)
        {
            _config = config;
        }

        public SqlConnection Connection
        {
            get
            {
                return new SqlConnection(_config.GetConnectionString("DefaultConnection"));
            }
        }

        [HttpGet]
        public async Task<IActionResult> Get()
        {
            using (SqlConnection conn = Connection)
            {
                conn.Open();
                using (SqlCommand cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "SELECT Id, Title, BeanType FROM Coffee";
                    SqlDataReader reader = cmd.ExecuteReader();
                    List<Coffee> coffees = new List<Coffee>();

                    while (reader.Read())
                    {
                        Coffee coffee = new Coffee
                        {
                            Id = reader.GetInt32(reader.GetOrdinal("Id")),
                            Title = reader.GetString(reader.GetOrdinal("Title")),
                            BeanType = reader.GetString(reader.GetOrdinal("BeanType"))
                        };

                        coffees.Add(coffee);
                    }
                    reader.Close();

                    return Ok(coffees);
                }
            }
        }

        [HttpGet("{id}", Name = "GetCoffee")]
        public async Task<IActionResult> Get([FromRoute] int id)
        {
            using (SqlConnection conn = Connection)
            {
                conn.Open();
                using (SqlCommand cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
                        SELECT
                            Id, Title, BeanType
                        FROM Coffee
                        WHERE Id = @id";
                    cmd.Parameters.Add(new SqlParameter("@id", id));
                    SqlDataReader reader = cmd.ExecuteReader();

                    Coffee coffee = null;

                    if (reader.Read())
                    {
                        coffee = new Coffee
                        {
                            Id = reader.GetInt32(reader.GetOrdinal("Id")),
                            Title = reader.GetString(reader.GetOrdinal("Title")),
                            BeanType = reader.GetString(reader.GetOrdinal("BeanType"))
                        };
                    }
                    reader.Close();

                    return Ok(coffee);
                }
            }
        }

        [HttpPost]
        public async Task<IActionResult> Post([FromBody] Coffee coffee)
        {
            using (SqlConnection conn = Connection)
            {
                conn.Open();
                using (SqlCommand cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"INSERT INTO Coffee (Title, BeanType)
                                        OUTPUT INSERTED.Id
                                        VALUES (@title, @beanType)";
                    cmd.Parameters.Add(new SqlParameter("@title", coffee.Title));
                    cmd.Parameters.Add(new SqlParameter("@beanType", coffee.BeanType));

                    int newId = (int) cmd.ExecuteScalar();
                    coffee.Id = newId;
                    return CreatedAtRoute("GetCoffee", new { id = newId }, coffee);
                }
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Put([FromRoute] int id, [FromBody] Coffee coffee)
        {
            try
            {
                using (SqlConnection conn = Connection)
                {
                    conn.Open();
                    using (SqlCommand cmd = conn.CreateCommand())
                    {
                        cmd.CommandText = @"UPDATE Coffee
                                            SET Title = @title,
                                                BeanType = @beanType
                                            WHERE Id = @id";
                        cmd.Parameters.Add(new SqlParameter("@title", coffee.Title));
                        cmd.Parameters.Add(new SqlParameter("@beanType", coffee.BeanType));
                        cmd.Parameters.Add(new SqlParameter("@id", id));

                        int rowsAffected = cmd.ExecuteNonQuery();
                        if (rowsAffected > 0)
                        {
                            return new StatusCodeResult(StatusCodes.Status204NoContent);
                        }
                        throw new Exception("No rows affected");
                    }
                }
            }
            catch (Exception)
            {
                if (!CoffeeExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete([FromRoute] int id)
        {
            try
            {
                using (SqlConnection conn = Connection)
                {
                    conn.Open();
                    using (SqlCommand cmd = conn.CreateCommand())
                    {
                        cmd.CommandText = @"DELETE FROM Coffee WHERE Id = @id";
                        cmd.Parameters.Add(new SqlParameter("@id", id));

                        int rowsAffected = cmd.ExecuteNonQuery();
                        if (rowsAffected > 0)
                        {
                            return new StatusCodeResult(StatusCodes.Status204NoContent);
                        }
                        throw new Exception("No rows affected");
                    }
                }
            }
            catch (Exception)
            {
                if (!CoffeeExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }
        }

        private bool CoffeeExists(int id)
        {
            using (SqlConnection conn = Connection)
            {
                conn.Open();
                using (SqlCommand cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
                        SELECT Id, Title, BeanType
                        FROM Coffee
                        WHERE Id = @id";
                    cmd.Parameters.Add(new SqlParameter("@id", id));

                    SqlDataReader reader = cmd.ExecuteReader();
                    return reader.Read();
                }
            }
        }
    }
}
