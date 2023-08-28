using ALFA.Share.ContentLifeCycle.Entities;
using Microsoft.SharePoint.Client;
using Microsoft.SharePoint.Client.Search.Query;
using Microsoft.SharePoint.Client.Utilities;
using Microsoft.Online.SharePoint.TenantAdministration;
using OfficeDevPnP.Core;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace ALFA.Share.ContentLifeCycle
{
    
    class SharepointUtils
    {
        private const string SITEPAGES_LIST_NAME = "Site Pages";
       
        public static List<SiteConfigEntity> ReadInclusionList(string configSiteUrl, string adminSiteUrl, string clientId, string clientSecret, string listTitle)
        {
            try
            {
                using (ClientContext ctx = new AuthenticationManager().GetAppOnlyAuthenticatedContext(configSiteUrl, clientId, clientSecret))
                {
                    // get list
                    ctx.Load(ctx.Web, w => w.Lists);
                    List inclusionList = ctx.Web.Lists.GetByTitle(listTitle);
                    // read all items included in CLC
                    CamlQuery camlQuery = new CamlQuery();
                    camlQuery.ViewXml = "<View><Query><Where><Eq><FieldRef Name='ALFA_ADM_CLC_Needed'/><Value Type='Boolean'>1</Value></Eq></Where></Query></View>";
                    ListItemCollection allListItems = inclusionList.GetItems(camlQuery);
                    ctx.Load(allListItems);
                    ctx.ExecuteQuery();
                    // list items to list objects
                    List<SiteConfigEntity> siteConfigEntities = new List<SiteConfigEntity>();
                    foreach (var listItem in allListItems)
                    {
                        var siteUrlField = (FieldUrlValue)listItem["ALFA_ADM_SiteUrl"];

                        // if wildcard, then get all filtered sites
                        if (siteUrlField.Url.EndsWith("*"))
                        {
                            Console.WriteLine(string.Format("Getting all sites for the wildcard '{0}'", siteUrlField.Url));
                            var allFilteredSites = GetTenantSitesFilteredByUrl(adminSiteUrl, clientId, clientSecret, "URL -like '" + siteUrlField.Url.TrimEnd('*') + "'");
                            allFilteredSites.ForEach(r => {
                                var siteEntity = new SiteConfigEntity()
                                {
                                    SiteUrl = r,
                                    FirstNotificationDays = int.Parse(listItem["ALFA_ADM_FirstNotificationDays"].ToString()),
                                    SecondNotificationDays = int.Parse(listItem["ALFA_ADM_SecondNotificationDays"].ToString())
                                };
                                siteConfigEntities.Add(siteEntity);
                            });
                        }
                        else
                        {
                            var siteEntity = new SiteConfigEntity()
                            {
                                SiteUrl = siteUrlField.Url,
                                FirstNotificationDays = int.Parse(listItem["ALFA_ADM_FirstNotificationDays"].ToString()),
                                SecondNotificationDays = int.Parse(listItem["ALFA_ADM_SecondNotificationDays"].ToString())
                            };
                            siteConfigEntities.Add(siteEntity);
                        }
                    }

                    return siteConfigEntities;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("ERROR! ReadInclusionList: " + e.Message);
                throw;
            }
        }


        public static List<string> GetTenantSitesFilteredByUrl(string adminSiteUrl, string clientId, string clientSecret, string filterUrl)
        {
            try
            {
                // returned list
                List<string> allTenantSites = new List<string>();

                // connect to the tenant
                ClientContext ctx = new AuthenticationManager().GetAppOnlyAuthenticatedContext(adminSiteUrl, clientId, clientSecret);
                Tenant tenant = new Tenant(ctx);

                // get filtered sites
                SPOSitePropertiesEnumerable returnedSites = null;
                string startInx = "0";
                do
                {
                    returnedSites = tenant.GetSitePropertiesFromSharePointByFilter(filterUrl, startInx, false);
                    ctx.Load(returnedSites);
                    ctx.ExecuteQuery();

                    allTenantSites.AddRange(returnedSites.Select(r => r.Url).ToList<string>());
                    startInx = returnedSites.NextStartIndexFromSharePoint;
                } while (!string.IsNullOrWhiteSpace(returnedSites.NextStartIndexFromSharePoint));

                // return filtered sites URLs
                return allTenantSites;
            }
            catch (Exception e)
            {
                Console.WriteLine("ERROR! GetTenantSitesFilteredByUrl: " + e.Message);
                throw;
            }
        }


        public static List<EMailTemplateEntity> ReadEmailTemplatesList(string configSiteUrl, string clientId, string clientSecret, string listTitle)
        {
            try
            {
                using (ClientContext ctx = new AuthenticationManager().GetAppOnlyAuthenticatedContext(configSiteUrl, clientId, clientSecret))
                {
                    // get list
                    ctx.Load(ctx.Web, w => w.Lists);
                    List templatesList = ctx.Web.Lists.GetByTitle(listTitle);
                    // read all items included in CLC
                    CamlQuery camlQuery = new CamlQuery();
                    camlQuery.ViewXml = "";
                    ListItemCollection allListItems = templatesList.GetItems(camlQuery);
                    ctx.Load(allListItems);
                    ctx.ExecuteQuery();
                    // list items to list objects
                    List<EMailTemplateEntity> emailEntities = new List<EMailTemplateEntity>();
                    foreach (var listItem in allListItems)
                    {
                        var emailEntity = new EMailTemplateEntity()
                        {
                            EMailType = listItem["ALFA_ADM_EMailType"].ToString(),
                            EMailSubject = listItem["ALFA_ADM_EMailSubject"].ToString(),
                            EMailBody = listItem["ALFA_ADM_EMailBody"].ToString()
                        };
                        emailEntities.Add(emailEntity);
                    }

                    return emailEntities;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("ERROR! ReadEMailTemplatesList: " + e.Message);
                throw;
            }
        }

        // --- NOT USED ---
        public static void GetSiteOutdatedPagesSearch(string siteUrl, string clientId, string clientSecret)
        {            
            // connect to the sharepoint
            using (ClientContext ctx = new AuthenticationManager().GetAppOnlyAuthenticatedContext(siteUrl, clientId, clientSecret))
            {
                // run search query
                ClientResult<ResultTableCollection> results = new ClientResult<ResultTableCollection>();
                KeywordQuery keywordQuery = new KeywordQuery(ctx)
                {
                    QueryText = "IsDocument:True AND FileExtension:aspx AND Path:https://fordemo.sharepoint.com/sites/Organizations",
                    TrimDuplicates = true
                };
                SearchExecutor searchExecutor = new SearchExecutor(ctx);
                results = searchExecutor.ExecuteQuery(keywordQuery);
                ctx.ExecuteQuery();

                ResultTable resultTable = results.Value.FirstOrDefault();
                Console.WriteLine("Search completed");
                // return pages list
            }
            
        }
       
        public static List<PageShareEntity> GetSiteOutdatedPagesCaml(string siteUrl, string clientId, string clientSecret, int daysToExpire)
        {
            try
            {
                // connect to the sharepoint
                using (ClientContext ctx = new AuthenticationManager().GetAppOnlyAuthenticatedContext(siteUrl, clientId, clientSecret))
                {
                    List<PageShareEntity> pagesEntities = new List<PageShareEntity>();

                    // get list
                    ctx.Load(ctx.Web, w => w.Lists);
                    List sitepagesList = ctx.Web.Lists.GetByTitle(SITEPAGES_LIST_NAME);

                    // Check if responsible field exists
                    bool ownerFieldExists = sitepagesList.Fields.GetFieldByInternalName("ALFA_PageOwners") != null;
                    bool editorFieldExists = sitepagesList.Fields.GetFieldByInternalName("ALFA_PageEditors") != null;
                    ctx.Load(sitepagesList.Fields);
                    ctx.ExecuteQuery();

                    // get all pages
                    CamlQuery camlQuery = new CamlQuery();
                    camlQuery.ViewXml = "<View><ViewFields><FieldRef Name='Title'/><FieldRef Name='FileRef'/><FieldRef Name='Modified'/><FieldRef Name='ALFA_PageOwners'/><FieldRef Name='ALFA_PageEditors'/></ViewFields>"
                        + "<Query><Where><Leq><FieldRef Name='Modified'/><Value Type='DateTime' IncludeTimeValue='false'>" + DateTime.Now.AddDays(-1*daysToExpire).ToString("yyyy-MM-ddTHH:mm:ssZ") + "</Value></Leq></Where></Query>"
                        + "<QueryOptions><ViewAttributes Scope='RecursiveAll'/></QueryOptions></View>";
                    ListItemCollection allListItems = sitepagesList.GetItems(camlQuery);
                    ctx.Load(allListItems);
                    ctx.ExecuteQuery();

                    // list items to list objects
                    foreach (var listItem in allListItems)
                    {
                        var pageOwnerField = ownerFieldExists ? listItem["ALFA_PageOwners"] as FieldUserValue[] : null;
                        var pageEditorField = editorFieldExists ? listItem["ALFA_PageEditors"] as FieldUserValue[] : null;
                        var pageEntity = new PageShareEntity()
                        {
                            SiteUrl = siteUrl,
                            PageUrl = new Uri(siteUrl).GetLeftPart(UriPartial.Authority) + listItem["FileRef"].ToString(),
                            Modified = (DateTime)listItem["Modified"],
                            PageOwnerEmail = pageOwnerField != null ? string.Format("{0};#{1}", pageOwnerField[0].LookupValue, pageOwnerField[0].Email) : string.Empty,
                            PageEditorEmail = pageEditorField != null ? string.Format("{0};#{1}", pageEditorField[0].LookupValue, pageEditorField[0].Email) : string.Empty
                        };
                        pagesEntities.Add(pageEntity);
                    }

                    return pagesEntities;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("ERROR! GetSiteOutdatedPagesCaml: " + e.Message);
                throw;
            }

        }



        
        public static List<PageShareEntity> GetAllSitePagesCaml(string siteUrl, string clientId, string clientSecret, int daysToExpire)
        {
            try
            {
                // connect to the sharepoint
                using (ClientContext ctx = new AuthenticationManager().GetAppOnlyAuthenticatedContext(siteUrl, clientId, clientSecret))
                {
                    List<PageShareEntity> pagesEntities = new List<PageShareEntity>();

                    // get list
                    ctx.Load(ctx.Web, w => w.Lists);
                    List sitepagesList = ctx.Web.Lists.GetByTitle(SITEPAGES_LIST_NAME);

                    // Check if responsible field exists
                    bool ownerFieldExists = sitepagesList.Fields.GetFieldByInternalName("ALFA_PageOwners") != null;
                    bool editorFieldExists = sitepagesList.Fields.GetFieldByInternalName("ALFA_PageEditors") != null;
                    ctx.Load(sitepagesList.Fields);
                    ctx.ExecuteQuery();

                    // get all pages
                    CamlQuery camlQuery = new CamlQuery();
                    camlQuery.ViewXml = "<View><ViewFields><FieldRef Name='Title'/><FieldRef Name='FileRef'/><FieldRef Name='Modified'/><FieldRef Name='ALFA_PageOwners'/><FieldRef Name='ALFA_PageEditors'/></ViewFields>"
                        +"<QueryOptions><ViewAttributes Scope='RecursiveAll'/></QueryOptions></View>";
                    ListItemCollection allListItems = sitepagesList.GetItems(camlQuery);
                    ctx.Load(allListItems);
                    ctx.ExecuteQuery();

                    // list items to list objects
                    foreach (var listItem in allListItems)
                    {
                        var pageOwnerField = ownerFieldExists ? listItem["ALFA_PageOwners"] as FieldUserValue[] : null;
                        var pageEditorField = editorFieldExists ? listItem["ALFA_PageEditors"] as FieldUserValue[] : null;
                        var pageEntity = new PageShareEntity()
                        {
                            SiteUrl = siteUrl,
                            PageUrl = new Uri(siteUrl).GetLeftPart(UriPartial.Authority) + listItem["FileRef"].ToString(),
                            Modified = (DateTime)listItem["Modified"],
                            PageOwnerEmail = pageOwnerField != null ? string.Format("{0};#{1}", pageOwnerField[0].LookupValue, pageOwnerField[0].Email) : string.Empty,
                            PageEditorEmail = pageEditorField != null ? string.Format("{0};#{1}", pageEditorField[0].LookupValue, pageEditorField[0].Email) : string.Empty
                        };
                        pagesEntities.Add(pageEntity);
                    }

                    return pagesEntities;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("ERROR! GetAllSitePagesCaml: " + e.Message);
                throw;
            }

        }


        public static void ProvisionReminders(string siteUrl, string clientId, string clientSecret, List<PageReminderEntity> remindersList, List<EMailTemplateEntity> emailTemplatesList)
        {
            try
            {
                // get uniq responsible persons
                var respPersons = remindersList.Select(u => u.PageEditorEmail).Union(remindersList.Select(u => u.PageOwnerEmail)).Distinct().Where(p => !string.IsNullOrWhiteSpace(p));
                // get first email template
                var firstEmailTemplate = emailTemplatesList.FirstOrDefault(e => e.EMailType == "Page First reminder");
                // get second email template
                var secondEmailTemplate = emailTemplatesList.FirstOrDefault(e => e.EMailType == "Page Second reminder");
                // get context
                ClientContext ctx = new AuthenticationManager().GetAppOnlyAuthenticatedContext(siteUrl, clientId, clientSecret);

                // send e-mails to persons
                foreach (var respPerson in respPersons)
                {
                    // first reminder
                    var pagesFirstReminder = remindersList.Where(r => (r.PageEditorEmail == respPerson || r.PageOwnerEmail == respPerson) && r.ReminderNumber == 1).Select(r => r.PageUrl).ToList();
                    if (pagesFirstReminder.Count > 0)
                    {
                        Console.WriteLine("First E-Mail to: {0}, pages count: {1}", respPerson, pagesFirstReminder.Count());
                        //SendReminder(ctx, respPerson, pagesFirstReminder, firstEmailTemplate);
                    }
                    // second reminder
                    var pagesSecondReminder = remindersList.Where(r => (r.PageEditorEmail == respPerson || r.PageOwnerEmail == respPerson) && r.ReminderNumber == 2).Select(r => r.PageUrl).ToList();
                    if (pagesSecondReminder.Count > 0)
                    {
                        Console.WriteLine("Second E-Mail to: {0}, pages count: {1}", respPerson, pagesSecondReminder.Count());
                      //  SendReminder(ctx, respPerson, pagesSecondReminder, secondEmailTemplate);
                    }
                }

                // send e-mail about pages without owner and editor (only for first reminder)
                var supportTeam = "Support Team;#share@alfalaval.com";
                firstEmailTemplate.EMailSubject = "There are outdated pages without owner and editor";
                var pagesWithoutResponsibles = remindersList.Where(r => string.IsNullOrWhiteSpace(r.PageEditorEmail) && string.IsNullOrWhiteSpace(r.PageOwnerEmail) && r.ReminderNumber == 1).Select(r => r.PageUrl).ToList();
                if (pagesWithoutResponsibles.Count > 0)
                {
                    Console.WriteLine("Abandoned pages E-Mail to: {0}, pages count: {1}", supportTeam, pagesWithoutResponsibles.Count());
                   // SendReminder(ctx, supportTeam, pagesWithoutResponsibles, firstEmailTemplate);
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("ERROR! EmailReminders: " + e.Message);
                throw;
            }
        }


        private static void SendReminder(ClientContext ctx, string responsiblePersonStr, List<string> outdatedPages, EMailTemplateEntity emailTemplate)
        {
            // split responsible name and e-mail
            string[] responsiblePersonArr = responsiblePersonStr.Split(";#".ToArray(), StringSplitOptions.RemoveEmptyEntries);
            string responsiblePersonName = responsiblePersonArr[0];
            string responsiblePersonEmail = (responsiblePersonArr.Length > 1 ? responsiblePersonArr[1] : responsiblePersonArr[0]);
            
            // prepare e-mail body
            var emailBody = emailTemplate.EMailBody
                        .Replace("&#123;UserName&#125;", responsiblePersonName)
                        .Replace("&#123;PagesCount&#125;", outdatedPages.Count().ToString())
                        .Replace("/&#123;TenantUrl&#125;", new Uri(ctx.Url).GetLeftPart(UriPartial.Authority))
                        .Replace("&#123;PagesList&#125;", string.Join("", outdatedPages.Select(p => string.Format("<a href=\"{0}\" >{1}</a><br>", p, p.Substring(p.LastIndexOf('/') + 1)))));
            
            // set e-mail properties
            var emailprpoperties = new EmailProperties
            {
                From = "no-reply@sharepointonline.com",
                To = new string[] { responsiblePersonEmail },
                Subject = emailTemplate.EMailSubject,
                Body = emailBody
            };

            // send e-mail
            try
            {
                var usr = ctx.Web.EnsureUser(responsiblePersonEmail);
                Utility.SendEmail(ctx, emailprpoperties);
                ctx.ExecuteQuery();
            }
            catch (Exception e)
            {
                Console.WriteLine("ERROR! E-mail not sent!" + e.Message);
            }
        }

    }
}
