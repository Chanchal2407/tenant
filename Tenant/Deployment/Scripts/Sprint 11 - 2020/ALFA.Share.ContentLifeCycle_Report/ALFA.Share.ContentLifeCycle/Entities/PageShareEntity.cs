using Microsoft.Azure.Cosmos.Table;
using System;

namespace ALFA.Share.ContentLifeCycle.Entities
{
    public class PageShareEntity
    {
        public PageShareEntity() { }

        public string SiteUrl { get; set; }
        public string PageUrl { get; set; }
        public DateTime Modified { get; set; }
        public string PageOwnerEmail { get; set; }
        public string PageEditorEmail { get; set; }
    }
}
