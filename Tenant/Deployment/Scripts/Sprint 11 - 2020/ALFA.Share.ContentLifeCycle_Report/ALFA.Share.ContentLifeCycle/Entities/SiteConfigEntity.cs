using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ALFA.Share.ContentLifeCycle.Entities
{
    class SiteConfigEntity
    {
        public SiteConfigEntity() { }
        
        public string SiteUrl { get; set; }
        public int FirstNotificationDays { get; set; }
        public int SecondNotificationDays { get; set; }
    }
}
