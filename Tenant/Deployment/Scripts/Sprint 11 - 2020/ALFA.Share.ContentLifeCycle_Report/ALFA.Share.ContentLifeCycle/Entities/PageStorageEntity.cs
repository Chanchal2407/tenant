using Microsoft.Azure.Cosmos.Table;
using System;

namespace ALFA.Share.ContentLifeCycle.Entities
{
    public class PageStorageEntity : TableEntity
    {
        public PageStorageEntity()
        {
            this.PartitionKey = "PortalPage";
            // this.RowKey = Guid.NewGuid().ToString();
        }

        public string SiteUrl { get; set; }
        public string PageUrl { get; set; }
        public int NumberOfReminderSent { get; set; }
        public DateTime LastReminderSentDate { get; set; }
    }
}
