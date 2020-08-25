using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace webAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class Data01Controller : ControllerBase
    {
        private static readonly string[] DataArray = new[]
        {
            "Data01-0001", "Data01-0002", "Data01-0003", "Data01-0004", "Data01-0005" , "Data01-0006"
        };

        private readonly ILogger<Data01Controller> _logger;

        public Data01Controller(ILogger<Data01Controller> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public string[] Get()
        {
            return DataArray;             
        }
    }
}
