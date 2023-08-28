using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ALFA.Share.ContentLifeCycle.Entities
{
    class EMailTemplateEntity
    {
        public EMailTemplateEntity() { }
        
        public string EMailType { get; set; }
        public string EMailSubject { get; set; }
        public string EMailBody { get; set; }
    }
}
