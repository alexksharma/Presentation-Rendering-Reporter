<%@ Page Language="C#" AutoEventWireup="true" %>

<%@ Import Namespace="Sitecore.Collections" %>
<%@ Import Namespace="Sitecore.Globalization" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Data.Managers" %>
<%@ Import Namespace="Sitecore.Collections" %>

<!doctype html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />

    <link href="modulefiles/style.css" rel="stylesheet" type="text/css" />
    <script src="http://code.jquery.com/jquery-1.11.3.min.js"></script>
    <script src="modulefiles/tab.js"></script>

    <title>Presentation Rendering Reporter</title>

    <style type="text/css">
        body {
            background-color: #fff;
            color: #000;
            font-family: Consolas, monospace;
        }

        a:link {
            color: #03d;
        }

        a:visited {
            color: #039;
        }

        a:hover {
            color: #09f;
        }

        #ddlLimitChildren, #chkChildren {
            display: inline-block;
            border: 1px solid #ccc;
            border-radius: 5px;
            box-sizing: border-box;
        }

        table {
            border-collapse: collapse;
            width: 100%;
        }

            table caption {
                color: #666;
                text-align: right;
                font-size: 65%;
                margin-bottom: .5ex;
            }

            table td, table th {
                border: solid 1px #666;
                border-collapse: collapse;
                padding: .3ex .5ex;
                vertical-align: top;
            }

            table tbody tr:hover {
                background-color: #ffc;
            }

            table tr:nth-child(odd) {
                background: silver;
            }

            table thead th {
                text-align: center;
                background-color: lightblue;
            }

            table tbody th {
                text-align: center;
                white-space: nowrap;
                background: lightblue none repeat scroll 0 0;
            }

        .table {
            page-break-inside: avoid;
        }

        .pk {
            float: right;
            cursor: arrow;
            color: #999;
        }

        .type {
            white-space: nowrap;
        }

        .null {
            text-align: center;
        }

        .flag {
            white-space: nowrap;
            font-size: 70%;
            display: inline-block;
            border: solid 1px #ccc;
            padding: .25ex .5ex;
            background-color: #ddd;
            margin-right: 1ex;
        }

        .tocref {
            float: right;
            text-decoration: none;
            font-weight: normal;
        }

        .footer {
            text-align: center;
            margin-top: 1em;
            font-size: 80%;
        }

        li.view:before {
            content: "VIEW";
            font-size: 70%;
            display: inline-block;
            border: solid 1px #ccc;
            padding: .25ex .5ex;
            background-color: #ddd;
            margin-right: 1ex;
        }

        @media print {
            body {
                font-size: .8em;
            }

            #toc, .tocref {
                display: none;
            }

            a:link, a:visited {
                color: #000;
                text-decoration: none;
            }
        }

        .main {
            width: 65%;
            margin: 10px auto;
            padding: 20px;
            border-radius: 5px;
        }

        #txtGuid {
            display: inline-block;
            border: 1px solid #ccc;
            border-radius: 5px;
            box-sizing: border-box;
        }



        #btnShowRenderingDetail {
            background-color: #81c784;
            border-radius: 8px;
            color: white;
            padding: 10px 20px;
            text-align: center;
            text-decoration: none;
            display: inline-block;
            font-size: 13px;
            font-family: comic sans ms;
        }

            #btnShowRenderingDetail:hover {
                background-color: #66bb6a;
            }

        h1 {
            color: maroon;
            font-size: 40px;
            text-align: center;
        }

        #contents {
            margin: 15%;
            margin-top: 1%;
            padding: 1px 16px;
            background-size: cover;
            background-repeat: no-repeat;
        }

        fieldset {
            display: block;
            border-radius: 8px;
            margin: 2px;
            padding-top: 0.35em;
            padding-bottom: 0.625em;
            padding-left: 1em;
            padding-right: 1em;
            border: 4px groove;
        }

        legend {
            font-family: Monotype corsiva;
            color: #731791;
            font-size: 45px;
        }


        .subtitle {
            margin: 0 0 2em 0;
        }

        .fancy {
            line-height: 0.1;
            text-align: center;
        }

            .fancy span {
                display: inline-block;
                position: relative;
            }

                .fancy span:before,
                .fancy span:after {
                    content: "";
                    position: absolute;
                    height: 5px;
                    border-bottom: 2px solid #1E2F94;
                    border-top: 2px solid #1E2F94;
                    top: 0;
                    width: 600px;
                }

                .fancy span:before {
                    right: 100%;
                    margin-right: 15px;
                }

                .fancy span:after {
                    left: 100%;
                    margin-left: 15px;
                }
    </style>

    <script language="c#" runat="server">

        LanguageCollection languages = null;
        Sitecore.Data.Database masterDb = null;
        int i = 0;
        bool ShowResult = false;
        List<PresentationItem> lstPresentation = null;
        List<string> lstProcessedItemsId = new List<string>();
        int ChildVerticalTabCounter = 1;
        string ChildVerticalTabNames = string.Empty;
        int number = 0;
        int RecordCounter = 0;

        /// <summary>
        /// Create query string and redirect to page itself
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        protected void btnShowRenderingDetail_Click(object sender, EventArgs e)
        {
            string queryString = string.Empty;
            if (chkChildren.Checked)
            {
                queryString = string.Format("&children=1&number={0}", ddlLimitChildren.SelectedItem.Value);
            }

            Response.Redirect(Request.Url.AbsolutePath + "?guid=" + txtGuid.Text + queryString);
        }

        /// <summary>
        /// Show Items Rendering Detail
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                try
                {
                    if (Request.QueryString["guid"] != null)
                    {
                        Guid result;
                        if (Guid.TryParse(Request.QueryString["guid"], out result))
                        {
                            StartProcess(new Sitecore.Data.ID(result));
                        }
                    }
                }
                catch (Exception ex)
                {
                    ltMessage.Text = "Error Occurred while getting data. Detail error - " + ex.Message;
                    ltMessage.ForeColor = System.Drawing.Color.Red;
                }
            }
        }

        /// <summary>
        /// Collect all items presentation details
        /// </summary>
        /// <param name="itemGuid"></param>
        private void StartProcess(Sitecore.Data.ID itemGuid)
        {

            Sitecore.Data.Items.Item rootItem = Sitecore.Data.Database.GetDatabase("master").GetItem(itemGuid);

            masterDb = Sitecore.Configuration.Factory.GetDatabase("master");

            languages = LanguageManager.GetLanguages(masterDb);

            lstPresentation = new List<PresentationItem>();
            ShowResult = true;
            hdnReportFlag.Value = "1";
            AppendRootItems(rootItem);

            if (Request.QueryString["children"] != null && Request.QueryString["children"].Equals("1") && Request.QueryString["number"] != null)
            {
                number = int.Parse(Request.QueryString["number"]);
                if (number > 0 && number <= 1000)
                {
                    AppendItems(rootItem);
                }
            }
        }

        /// <summary>
        /// Collect root items rendering details
        /// </summary>
        /// <param name="childItem"></param>
        public void AppendRootItems(Sitecore.Data.Items.Item childItem)
        {
            //foreach (Sitecore.Data.Items.Item childItem in item.GetChildren( ChildListOptions.AllowReuse))
            {


                int ShareCounter = 1;
                PresentationItem currentItemPresentation = null;
                //var LanguageSpecificItem = childItem.Languages.Select(x => masterDb.GetItem(childItem.ID, x)).SingleOrDefault<Item>();


                //.SingleOrDefault<Item>(x => x != null && !x.IsFallback && x.Versions.Count > 0)
                //.Where(x=> masterDb.GetItem(childItem.ID, x) != null).
                //DoesSitecoreItemHavePeresentation(item)
                RenderingDetail shared = new RenderingDetail();

                List<PresentationItemLanguage> ListFinalPresentationItemLanguage = new List<PresentationItemLanguage>();

                foreach (Language language in languages)
                {
                    //ltMessage.Text += "4";
                    Item languageSpecificItem = masterDb.GetItem(childItem.ID, language);
                    if (languageSpecificItem != null && !languageSpecificItem.IsFallback && languageSpecificItem.Versions.Count > 0)
                    {
                        //var SharedRendering = languageSpecificItem.Versions.GetVersions().Where(x => DoesSitecoreItemHavePeresentation(x)).SingleOrDefault();
                        //if(SharedRendering != null)
                        //{
                        //    RenderingLanguage sharedRenderingLanguage = new RenderingLanguage();
                        //    sharedRenderingLanguage.LanguageName = SharedRendering.Language.Name;
                        //    sharedRenderingLanguage.VersionNumber = SharedRendering.Version.Number;

                        //    sharedRenderingLanguage.VersionRenderingDetail = CountRenderings(SharedRendering, Sitecore.FieldIDs.LayoutField);
                        //}

                        List<PresentationItemLanguage> lstRenderingLanguage = new List<PresentationItemLanguage>();
                        List<RenderingDetail> lstCurrentLanguageVersionRenderingDetail = new List<RenderingDetail>();

                        List<RenderingLanguageVersion> ListRenderingLanguageVersion = new List<RenderingLanguageVersion>();

                        foreach (var versionItem in languageSpecificItem.Versions.GetVersions())
                        {
                            //i++;
                            //itemList.Add(childItem);
                            if (DoesSitecoreItemHavePeresentation(versionItem))
                            {
                                if (ShareCounter == 1)
                                {

                                    RenderingLanguageVersion sharedRenderingLanguageVersion = new RenderingLanguageVersion();
                                    sharedRenderingLanguageVersion.ListRenderingDetail = CountRenderings(versionItem, Sitecore.FieldIDs.LayoutField);
                                    sharedRenderingLanguageVersion.VersionNumber = versionItem.Version.Number;

                                    List<RenderingLanguageVersion> tempListRenderingLanguageVersion = new List<RenderingLanguageVersion>();
                                    tempListRenderingLanguageVersion.Add(sharedRenderingLanguageVersion);

                                    PresentationItemLanguage sharedRenderingLanguage = new PresentationItemLanguage();
                                    sharedRenderingLanguage.LanguageName = versionItem.Language.Name;
                                    sharedRenderingLanguage.ListRenderingLanguageVersion = tempListRenderingLanguageVersion;

                                    List<RenderingLanguageVersion> lstRenderingLanguageVersion = new List<RenderingLanguageVersion>();
                                    lstRenderingLanguageVersion.Add(sharedRenderingLanguageVersion);

                                    if (currentItemPresentation == null)
                                    {
                                        currentItemPresentation = new PresentationItem();
                                    }

                                    currentItemPresentation.ItemId = childItem.ID.Guid.ToString();
                                    currentItemPresentation.ItemName = childItem.Name;
                                    currentItemPresentation.SharedPresentationItemLanguage = sharedRenderingLanguage;
                                    //currentItemPresentation.SharedPresentationItemLanguage = sharedRenderingLanguage;

                                    //lstProcessedItemsId.Add(versionItem.ID.Guid.ToString());

                                    ShareCounter++;
                                    //ltMessage.Text += "8";
                                }

                                currentItemPresentation = currentItemPresentation == null ? new PresentationItem() : currentItemPresentation;

                                RenderingLanguageVersion finalRenderingLanguageVersion = new RenderingLanguageVersion();
                                finalRenderingLanguageVersion.VersionNumber = versionItem.Version.Number;
                                finalRenderingLanguageVersion.ListRenderingDetail = CountRenderings(versionItem, Sitecore.FieldIDs.FinalLayoutField);

                                ListRenderingLanguageVersion.Add(finalRenderingLanguageVersion);
                            }

                        }   //End of  foreach (var versionItem in languageSpecificItem.Versions.GetVersions())

                        PresentationItemLanguage finalRenderingLanguage = new PresentationItemLanguage();
                        finalRenderingLanguage.LanguageName = language.Name;
                        finalRenderingLanguage.ListRenderingLanguageVersion = ListRenderingLanguageVersion;
                        ListFinalPresentationItemLanguage.Add(finalRenderingLanguage);
                    }
                }
                if (currentItemPresentation != null)
                {
                    currentItemPresentation.ListFinalPresentationItemLanguage = ListFinalPresentationItemLanguage;

                    lstPresentation.Add(currentItemPresentation);

                    RecordCounter++;

                    //ltMessage.Text += "6";
                }

                //AppendItems(childItem);
            }
        }
        
        /// <summary>
        /// Collect child items rendering details
        /// </summary>
        /// <param name="item"></param>
        public void AppendItems(Sitecore.Data.Items.Item item)
        {
            foreach (Sitecore.Data.Items.Item childItem in item.GetChildren(ChildListOptions.AllowReuse))
            {
                if (RecordCounter >= number)
                {
                    return;
                }

                int ShareCounter = 1;
                PresentationItem currentItemPresentation = null;

                RenderingDetail shared = new RenderingDetail();

                List<PresentationItemLanguage> ListFinalPresentationItemLanguage = new List<PresentationItemLanguage>();

                foreach (Language language in languages)
                {
                    Item languageSpecificItem = masterDb.GetItem(childItem.ID, language);
                    if (languageSpecificItem != null && !languageSpecificItem.IsFallback && languageSpecificItem.Versions.Count > 0)
                    {
                        List<PresentationItemLanguage> lstRenderingLanguage = new List<PresentationItemLanguage>();
                        List<RenderingDetail> lstCurrentLanguageVersionRenderingDetail = new List<RenderingDetail>();

                        List<RenderingLanguageVersion> ListRenderingLanguageVersion = new List<RenderingLanguageVersion>();

                        foreach (var versionItem in languageSpecificItem.Versions.GetVersions())
                        {
                            i++;
                            if (DoesSitecoreItemHavePeresentation(versionItem))
                            {
                                if (ShareCounter == 1)
                                {

                                    RenderingLanguageVersion sharedRenderingLanguageVersion = new RenderingLanguageVersion();
                                    sharedRenderingLanguageVersion.ListRenderingDetail = CountRenderings(versionItem, Sitecore.FieldIDs.LayoutField);
                                    sharedRenderingLanguageVersion.VersionNumber = versionItem.Version.Number;

                                    List<RenderingLanguageVersion> tempListRenderingLanguageVersion = new List<RenderingLanguageVersion>();
                                    tempListRenderingLanguageVersion.Add(sharedRenderingLanguageVersion);

                                    PresentationItemLanguage sharedRenderingLanguage = new PresentationItemLanguage();
                                    sharedRenderingLanguage.LanguageName = versionItem.Language.Name;
                                    sharedRenderingLanguage.ListRenderingLanguageVersion = tempListRenderingLanguageVersion;

                                    List<RenderingLanguageVersion> lstRenderingLanguageVersion = new List<RenderingLanguageVersion>();
                                    lstRenderingLanguageVersion.Add(sharedRenderingLanguageVersion);

                                    if (currentItemPresentation == null)
                                    {
                                        currentItemPresentation = new PresentationItem();
                                    }

                                    currentItemPresentation.ItemId = childItem.ID.Guid.ToString();
                                    currentItemPresentation.ItemName = childItem.Name;
                                    currentItemPresentation.SharedPresentationItemLanguage = sharedRenderingLanguage;
                                    ShareCounter++;
                                }

                                currentItemPresentation = currentItemPresentation == null ? new PresentationItem() : currentItemPresentation;

                                RenderingLanguageVersion finalRenderingLanguageVersion = new RenderingLanguageVersion();
                                finalRenderingLanguageVersion.VersionNumber = versionItem.Version.Number;
                                finalRenderingLanguageVersion.ListRenderingDetail = CountRenderings(versionItem, Sitecore.FieldIDs.FinalLayoutField);

                                ListRenderingLanguageVersion.Add(finalRenderingLanguageVersion);
                            }

                        }   //End of  foreach (var versionItem in languageSpecificItem.Versions.GetVersions())

                        PresentationItemLanguage finalRenderingLanguage = new PresentationItemLanguage();
                        finalRenderingLanguage.LanguageName = language.Name;
                        finalRenderingLanguage.ListRenderingLanguageVersion = ListRenderingLanguageVersion;
                        ListFinalPresentationItemLanguage.Add(finalRenderingLanguage);
                    }
                }
                if (currentItemPresentation != null)
                {
                    currentItemPresentation.ListFinalPresentationItemLanguage = ListFinalPresentationItemLanguage;

                    lstPresentation.Add(currentItemPresentation);
                    RecordCounter++;
                }

                AppendItems(childItem);
            }
        }

        /// <summary>
        /// Check for presentation
        /// </summary>
        /// <param name="item"></param>
        /// <returns></returns>
        public bool DoesSitecoreItemHavePeresentation(Sitecore.Data.Items.Item item)
        {
            return item.Fields[Sitecore.FieldIDs.LayoutField] != null
                   && item.Fields[Sitecore.FieldIDs.LayoutField].Value
                   != String.Empty;
        }

        /// <summary>
        /// Get rendering details for current item
        /// </summary>
        /// <param name="item"></param>
        /// <param name="renderingFieldId"></param>
        /// <returns></returns>
        private List<RenderingDetail> CountRenderings(Sitecore.Data.Items.Item item, Sitecore.Data.ID renderingFieldId)
        {
            var field = item.Fields[renderingFieldId];
            var layoutXml = Sitecore.Data.Fields.LayoutField.GetFieldValue(field);
            var layout = Sitecore.Layouts.LayoutDefinition.Parse(layoutXml);
            var deviceLayout = layout.Devices[0] as Sitecore.Layouts.DeviceDefinition;
            var list = deviceLayout.Renderings;

            List<RenderingDetail> lstRenderingDetail = deviceLayout.Renderings.Cast<Sitecore.Layouts.RenderingDefinition>()
                .Where(x => x != null && x.ItemID != null).Select(x => new RenderingDetail()
                {
                    Name = Sitecore.Data.Database.GetDatabase("master").GetItem(x.ItemID).Name,
                    Placeholder = x.Placeholder,
                    Datasource = x.Datasource,
                    Path = string.IsNullOrEmpty(item.Paths.Path) ? "" : item.Paths.Path
                }).ToList();

            return lstRenderingDetail;
        }

        /// <summary>
        /// Create vertical tabs
        /// </summary>
        /// <param name="lstPresentationItemLanguage"></param>
        /// <returns></returns>
        private string CreateTab(List<PresentationItemLanguage> lstPresentationItemLanguage)
        {
            StringBuilder sb = new StringBuilder();

            if (lstPresentationItemLanguage != null)
            {
                int childCounter = 1;
                string itemPath = string.Empty;
                foreach (PresentationItemLanguage presentationItemLanguage in lstPresentationItemLanguage)
                {
                    string tempVerticalTabName = "#ChildVerticalTab_" + childCounter; // ChildVerticalTabCounter;

                    sb.AppendLine(@"
                                    <div>
                                    <p>
                                    
                                    <div id='ChildVerticalTab_" + childCounter + "'><ul class='resp-tabs-list ver_1'>"); //, tempVerticalTabName);
                    ChildVerticalTabNames += tempVerticalTabName + ",";

                    ChildVerticalTabCounter++;
                    childCounter++;

                    foreach (RenderingLanguageVersion renderingLanguageVersion in presentationItemLanguage.ListRenderingLanguageVersion)
                    {
                        sb.AppendLine(string.Format(" <li>Version {0}</li>", renderingLanguageVersion.VersionNumber));
                    }

                    sb.AppendLine(@"</ul>");
                    sb.AppendLine(@"<div class='resp-tabs-container ver_1'>");

                    foreach (RenderingLanguageVersion renderingLanguageVersion in presentationItemLanguage.ListRenderingLanguageVersion)
                    {


                        sb.AppendLine(@"<div><table><tr>
                                        <th>Name</th>
                                        <th>Placeholder</th>
                                        <th>Datasource</th>
                                        </tr>");
                        foreach (RenderingDetail currentRenderingDetails in renderingLanguageVersion.ListRenderingDetail)
                        {
                            itemPath = string.IsNullOrEmpty(currentRenderingDetails.Path) ? itemPath : currentRenderingDetails.Path;
                            string path = currentRenderingDetails.Datasource;
                            if (!string.IsNullOrEmpty(currentRenderingDetails.Datasource))
                            {
                                var dataSourceID = new Sitecore.Data.ID(currentRenderingDetails.Datasource);
                                if (!Sitecore.Data.ID.IsNullOrEmpty(dataSourceID))
                                {
                                    var dataSourceItem = Sitecore.Data.Database.GetDatabase("master").GetItem(dataSourceID);
                                    if (dataSourceItem != null && dataSourceItem.Paths != null && !string.IsNullOrEmpty(dataSourceItem.Paths.Path))
                                    {
                                        path = dataSourceItem.Paths.Path;
                                    }
                                }
                            }

                            sb.AppendLine(string.Format(@"<tr>
                                                            <td>{0}</td>
                                                            <td>{1}</td>
                                                            <td>{2}</td>
                                                          </tr>", currentRenderingDetails.Name, currentRenderingDetails.Placeholder, path));
                        }
                        sb.AppendLine(@"</table></div>");
                    }

                    sb.AppendLine(@"</div>
                                        </div>
                                        </p><br>
                                        <p style='color: red'>Item Path : " + itemPath + "</p></div>");

                }
            }
            return sb.ToString();
        }

        /// <summary>
        /// Represent one item as a entity
        /// </summary>
        public class PresentationItem
        {
            public string ItemId { get; set; }
            public string ItemName { get; set; }
            public PresentationItemLanguage SharedPresentationItemLanguage { get; set; }
            public List<PresentationItemLanguage> ListFinalPresentationItemLanguage { get; set; }
        }

        /// <summary>
        /// Keep item's all languages
        /// </summary>
        public class PresentationItemLanguage
        {
            public string LanguageName { get; set; }
            public List<RenderingLanguageVersion> ListRenderingLanguageVersion { get; set; }
        }

        /// <summary>
        /// Keep item's language all versions
        /// </summary>
        public class RenderingLanguageVersion
        {
            public int VersionNumber { get; set; }
            public List<RenderingDetail> ListRenderingDetail { get; set; }
        }

        /// <summary>
        /// Keep all rendering of current item's language versions
        /// </summary>
        public class RenderingDetail
        {
            public string Id { get; set; }
            public string Name { get; set; }
            public string Placeholder { get; set; }
            public string Datasource { get; set; }
            public string Language { get; set; }
            public string VersionNumber { get; set; }
            public bool IsShared { get; set; }
            public string Path { get; set; }
        }
    </script>
</head>

<body>
    <form id="form1" runat="server">
        <asp:HiddenField ID="hdnReportFlag" runat="server" />
        <div class="main">
            <fieldset>
                <legend>Presentation Rendering Reporter</legend>

                Enter GUID: &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<asp:TextBox ID="txtGuid" ViewStateMode="Enabled" runat="server" Width="290px" autocomplete="off"></asp:TextBox>
                <br />
                <asp:RequiredFieldValidator ID="RequiredFieldValidator1" runat="server" SetFocusOnError="true" ControlToValidate="txtGuid" Display="none" ErrorMessage="Please enter item GUID." ForeColor="Red">
                </asp:RequiredFieldValidator>

                <asp:ValidationSummary runat="server" ShowMessageBox="true" ShowSummary="false" />

                <br />
                Show Children: &nbsp;&nbsp;<asp:CheckBox ID="chkChildren" runat="server" />
                <br />
                <br />
                Limit Children: &nbsp;<asp:DropDownList ID="ddlLimitChildren" runat="server" Height="18px" Width="135px">
                    <asp:ListItem Value="5" Text="5" Selected="True"> </asp:ListItem>
                    <asp:ListItem Value="10" Text="10"> </asp:ListItem>
                    <asp:ListItem Value="20" Text="20"> </asp:ListItem>
                    <asp:ListItem Value="25" Text="25"> </asp:ListItem>
                    <asp:ListItem Value="50" Text="50"> </asp:ListItem>
                    <asp:ListItem Value="100" Text="100"> </asp:ListItem>
                    <asp:ListItem Value="All" Text="All"> </asp:ListItem>
                </asp:DropDownList>
                <br />
                <br />
                <asp:Button ID="btnShowRenderingDetail" Visible="true" runat="server" Text="Show Rendering Detail" OnClick="btnShowRenderingDetail_Click" />
                <br />
                <br />
                <asp:Label ID="ltMessage" runat="server"></asp:Label>
            </fieldset>
        </div>
        <div>
            <table>
                <% 
                    string ParentDiv = "";
                    string currentParentDiv = "";
                    int iCounter = 0;
                    if (lstPresentation != null && lstPresentation.Count > 0)
                    {
                        foreach (PresentationItem currentItem in lstPresentation)
                        {
                            iCounter++;
                            currentParentDiv = "parentHorizontalTab" + iCounter.ToString();
                            ParentDiv += "#parentHorizontalTab" + iCounter.ToString() + ",";
                %>
                <tr align="left">
                    <th colspan="2">#<%=iCounter.ToString() %> - Item ID : <%=currentItem.ItemId
                    %>
                    </th>
                </tr>
                <tr>
                    <td colspan="2">Item Name : <%=currentItem.ItemName
                    %>
                    </td>
                </tr>

                <tr>
                    <th style="background-color: palegoldenrod">Shared Layout Details
                    </th>
                    <th>Final Layout Details
                    </th>
                </tr>

                <tr>
                    <td style="background-color: palegoldenrod">

                        <% string sharedRows = "<br><br><br><table>";
                            if (currentItem.SharedPresentationItemLanguage != null && currentItem.SharedPresentationItemLanguage.ListRenderingLanguageVersion != null)
                            {
                                sharedRows += string.Format("<tr><td>Language : {0}</td></tr>", currentItem.SharedPresentationItemLanguage.LanguageName);
                                RenderingLanguageVersion renderingLanguageVersion = currentItem.SharedPresentationItemLanguage.ListRenderingLanguageVersion[0];

                                sharedRows += string.Format("<tr><td>Version : {0}</td></tr>", renderingLanguageVersion.VersionNumber);

                                sharedRows += string.Format("<tr><th>Name</th></tr>");

                                foreach (RenderingDetail renderingDetail in renderingLanguageVersion.ListRenderingDetail)
                                {
                                    sharedRows += string.Format("<tr><td>{0}</td></tr>", renderingDetail.Name);
                                }
                            }
                            sharedRows += "</table>";
                        %>
                        <%=sharedRows %>
                           
                    </td>
                    <td>
                        <!--Final Layout Details Start -->

                        <div id="nested-tabInfo">
                            Selected tab: <span class="tabName"></span>
                        </div>
                        <div id="<%=currentParentDiv %>">
                            <ul class="resp-tabs-list hor_1">


                                <% StringBuilder currentItemLanguage = new StringBuilder();
                                    if (currentItem.ListFinalPresentationItemLanguage != null)
                                    {
                                        foreach (PresentationItemLanguage presentationItemLanguage in currentItem.ListFinalPresentationItemLanguage)
                                        {
                                            currentItemLanguage.AppendLine(string.Format("<li>{0}</li>", presentationItemLanguage.LanguageName));
                                        }
                                    }
                                %>

                                <%=currentItemLanguage.ToString() %>
                            </ul>
                            <div class="resp-tabs-container hor_1">

                                <%=CreateTab(currentItem.ListFinalPresentationItemLanguage) %>
                            </div>
                        </div>
                        <!--Final Layout Details End -->
                    </td>
                </tr>
                <%   }
                    }
                %>
            </table>

        </div>

        <script type="text/javascript">
            $(document).ready(function () {
                $('<%= string.IsNullOrEmpty(ParentDiv) ? "#parentHorizontalTab1" : ParentDiv.Substring(0, ParentDiv.Length - 1)%>').easyResponsiveTabs({
                    type: 'default', //Types: default, vertical, accordion
                    width: 'auto', //auto or any width like 600px
                    fit: true, // 100% fit in a container
                    closed: 'accordion', // Start closed if in accordion view
                    tabidentify: 'hor_1', // The tab groups identifier
                    activate: function (event) { // Callback function if tab is switched
                        var $tab = $(this);
                        var $info = $('#nested-tabInfo');
                        var $name = $('span', $info);

                        $name.text($tab.text());

                        $info.show();
                    }
                });

                $('<%= string.IsNullOrEmpty(ChildVerticalTabNames) ? "#ChildVerticalTab_1,#ChildVerticalTab_2,#ChildVerticalTab_3" : ChildVerticalTabNames.Substring(0, ChildVerticalTabNames.Length - 1)%>').easyResponsiveTabs({
                    type: 'vertical',
                    width: 'auto',
                    fit: true,
                    tabidentify: 'ver_1', // The tab groups identifier
                    activetab_bg: '#fff', // background color for active tabs in this group
                    inactive_bg: '#F5F5F5', // background color for inactive tabs in this group
                    active_border_color: '#c1c1c1', // border color for active tabs heads in this group
                    active_content_border_color: '#5AB1D0' // border color for active tabs contect in this group so that it matches the tab head border
                });
            });
        </script>
    </form>
</body>
</html>
