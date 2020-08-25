using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;

namespace wcf
{
    // NOTE: You can use the "Rename" command on the "Refactor" menu to change the class name "WCF" in code, svc and config file together.
    // NOTE: In order to launch WCF Test Client for testing this service, please select WCF.svc or WCF.svc.cs at the Solution Explorer and start debugging.
    public class WCF : Data02
    {

        private string[] DataArray02 = new[]
        {
            "Data02-0001", "Data02-0002", "Data02-0003", "Data02-0004", "Data02-0005" , "Data02-0006"
        };
         
        
        public string[] GetDataWCF()
        {
            return DataArray02;
        }


    }
}
