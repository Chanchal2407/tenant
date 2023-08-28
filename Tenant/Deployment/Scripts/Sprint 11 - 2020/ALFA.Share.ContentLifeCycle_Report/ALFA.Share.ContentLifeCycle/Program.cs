using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ALFA.Share.ContentLifeCycle.Entities;
using Microsoft.Azure.Cosmos.Table;

namespace ALFA.Share.ContentLifeCycle
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("--- Start CLC app execution ---");


           // read app config
            string clientID = ConfigurationManager.AppSettings["clientId"];
            string clientSecret = ConfigurationManager.AppSettings["clientSecret"];
            string adminSiteUrl = ConfigurationManager.AppSettings["adminSiteUrl"];
            string configSiteUrl = ConfigurationManager.AppSettings["configSiteUrl"];
            string inclusionListTitle = ConfigurationManager.AppSettings["clcInclusionListTitle"];
            string emailTemplatesListTitle = ConfigurationManager.AppSettings["emailTemplatesListTitle"];

            // initialize reminder list
            List<PageReminderEntity> reminderList = new List<PageReminderEntity>();
                        
            // read sites included in CLC from sharepoint list
            var sitesConfigured = SharepointUtils.ReadInclusionList(configSiteUrl, adminSiteUrl, clientID, clientSecret, inclusionListTitle);
            Console.WriteLine("{0} sites are under CLC", sitesConfigured.Count());

            // read e-mail templates from sharepoint list
            var emailTemplates = SharepointUtils.ReadEmailTemplatesList(configSiteUrl, clientID, clientSecret, emailTemplatesListTitle);
            Console.WriteLine("{0} e-mail templates are found", emailTemplates.Count());
            var csv = new StringBuilder();
            var outdatedPagecount = 0;
            var TotalPagecount = 0;

            //Get All the sites with outdated and total site pages with txt file
            using (System.IO.StreamWriter file =
            new System.IO.StreamWriter(@"C:/Temp/SiteDetails.txt", true))
             {
            // get pages for each site
            foreach (var siteConfig in sitesConfigured)
            {
                
                Console.WriteLine("Processing site: {0}", siteConfig.SiteUrl);
                try
                {
                    
                    
                    var AllpagesFormShare = SharepointUtils.GetAllSitePagesCaml(siteConfig.SiteUrl, clientID, clientSecret, siteConfig.FirstNotificationDays);
                    var pagesFormShare = SharepointUtils.GetSiteOutdatedPagesCaml(siteConfig.SiteUrl, clientID, clientSecret, siteConfig.FirstNotificationDays);

                    foreach(var pages in pagesFormShare)
                    {
                        var SiteUrl = pages.SiteUrl;
                        var PageUrl = pages.PageUrl;
                        var Modified = pages.Modified;
                        var PageEditorEmail = pages.PageEditorEmail;
                        var PageOwnerEmail = pages.PageOwnerEmail;

                        //Appending  all site outdated page details in CSV
                        var newLine = string.Format("{0}*{1}*{2}*{3}*{4}", SiteUrl, PageUrl, Modified, PageEditorEmail, PageOwnerEmail);
                        csv.AppendLine(newLine);

                    }
                      
                    file.WriteLine( "Processing site: {0}", siteConfig.SiteUrl);
                    file.WriteLine("Pages out of date: {0}", pagesFormShare.Count());
                    file.WriteLine("Pages in the storage: {0}", AllpagesFormShare.Count());
                    //var pagesFromStorage = AzureStorageUtils.GetSitePages(siteConfig.SiteUrl);
                    outdatedPagecount = outdatedPagecount+pagesFormShare.Count();
                    TotalPagecount = TotalPagecount+ AllpagesFormShare.Count();

                    Console.WriteLine("Pages out of date: {0}", pagesFormShare.Count());
                    Console.WriteLine("Pages in the storage: {0}", AllpagesFormShare.Count());

                } catch (Exception e)
                {
                    Console.WriteLine("ERROR processing site! Site is skipped!");
                }
            }
             //Last line of the CSV file with Total outdated pages count and Total number of page count
             var LastLine = string.Format("{0}*{1}*{2}*{3}*{4}", " ", " ", " ", outdatedPagecount, TotalPagecount );
             csv.AppendLine(LastLine);
 
             File.WriteAllText("C:/Temp/Report.csv", csv.ToString());
            
             }

            Console.WriteLine("--- Press any key to close app ---");
            Console.ReadKey();
        }
    }
}
