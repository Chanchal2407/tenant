using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ALFA.Share.ContentLifeCycle.Entities
{
    class PageReminderEntity
    {
        public PageReminderEntity() { }
        public PageReminderEntity(string pageUrl, string pageOwnerEmail, string pageEditorEmail, int reminderNr) {
            this.PageUrl = pageUrl;
            this.PageOwnerEmail = pageOwnerEmail;
            this.PageEditorEmail = pageEditorEmail;
            this.ReminderNumber = reminderNr;
        }

        public string PageUrl { get; set; }
        public string PageOwnerEmail { get; set; }
        public string PageEditorEmail { get; set; }
        public int ReminderNumber { get; set; }
    }
}
