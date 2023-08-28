using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ALFA.Share.ContentLifeCycle.Entities;
using Microsoft.Azure.Cosmos.Table;

namespace ALFA.Share.ContentLifeCycle
{
    class AzureStorageUtils
    {
        private const string STORAGE_TABLE_NAME = "AlfaCLCPagesProvisioned";

        public static CloudStorageAccount GetStorageAccount(string connectionString)
        {
            CloudStorageAccount storageAccount;
            try
            {
                storageAccount = CloudStorageAccount.Parse(connectionString);
            }
            catch (FormatException)
            {
                Console.WriteLine("Invalid storage account information provided. Please confirm the AccountName and AccountKey are valid in the app.config file.");
                throw;
            }
            catch (ArgumentException)
            {
                Console.WriteLine("Invalid storage account information provided. Please confirm the AccountName and AccountKey are valid in the app.config file.");
                throw;
            }

            return storageAccount;
        }

        public static CloudTable GetStorageTable()
        {
            string storageConnectionString = ConfigurationManager.AppSettings["storageConnectionString"];

            // Retrieve storage account
            CloudStorageAccount storageAccount = GetStorageAccount(storageConnectionString);

            // Create a table client
            CloudTableClient tableClient = storageAccount.CreateCloudTableClient(new TableClientConfiguration());
                        
            // Get or Create a table
            CloudTable table = tableClient.GetTableReference(STORAGE_TABLE_NAME);
            table.CreateIfNotExists();

            return table;
        }

        public static void InsertStorageEntity(string siteUrl, string pageUrl, int reminderNr, DateTime reminderDate)
        {
            var pageEntity = new PageStorageEntity()
            {
                RowKey = Guid.NewGuid().ToString(),
                SiteUrl = siteUrl,
                PageUrl = pageUrl,
                NumberOfReminderSent = reminderNr,
                LastReminderSentDate = reminderDate
            };
            var storageTable = GetStorageTable();
            TableOperation insertOperation = TableOperation.Insert(pageEntity);
            storageTable.Execute(insertOperation);
        }

        public static void MergeStorageEntity(PageStorageEntity pageEntity)
        {
            var storageTable = GetStorageTable();
            TableOperation insertOperation = TableOperation.Merge(pageEntity);
            storageTable.Execute(insertOperation);
        }

        public static List<PageStorageEntity> GetSitePages(string siteUrl)
        {
            var storageTable = GetStorageTable();
            var condition = TableQuery.GenerateFilterCondition("SiteUrl", QueryComparisons.Equal, siteUrl);
            var query = new TableQuery<PageStorageEntity>().Where(condition);
            var sitePages = storageTable.ExecuteQuery(query);

            return sitePages.ToList();
        }

        public static void DeleteSitePage(PageStorageEntity pageToDelete)
        {
           // var storageTable = GetStorageTable();
            //TableOperation deleteOperation = TableOperation.Delete(pageToDelete);
            //TableResult result = storageTable.Execute(deleteOperation);
        }

        
    }
}
