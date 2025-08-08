using System.ComponentModel.Composition;
using Microsoft.Crm.Sdk.Messages;
using XrmToolBox.Extensibility;

namespace DS.XrmToolBox.DynamicsMap
{
    [Export(typeof(PluginControlBase))]
    [ExportMetadata("Name", "Dynamics Map")]
    [ExportMetadata(
        "Description",
        "Explore Dataverse locations on a map (scaffold)"
    )]
    [ExportMetadata("BackgroundColor", "#ffffff")]
    [ExportMetadata("PrimaryFontColor", "#000000")]
    public class DynamicsMapPlugin : PluginControlBase
    {
        private Button btnWhoAmI = null!;
        private TextBox txtLog = null!;

        public DynamicsMapPlugin()
        {
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            btnWhoAmI = new Button
            {
                Text = "WhoAmI",
                AutoSize = true,
                Location = new Point(10, 10)
            };
            btnWhoAmI.Click += BtnWhoAmI_Click;

            txtLog = new TextBox
            {
                Location = new Point(10, 45),
                Multiline = true,
                ScrollBars = ScrollBars.Vertical,
                Anchor = AnchorStyles.Top
                    | AnchorStyles.Bottom
                    | AnchorStyles.Left
                    | AnchorStyles.Right,
                Size = new Size(500, 300)
            };

            Controls.Add(btnWhoAmI);
            Controls.Add(txtLog);

            Dock = DockStyle.Fill;
        }

        private void BtnWhoAmI_Click(object sender, EventArgs e)
        {
            if (Service == null)
            {
                MessageBox.Show(
                    "No Dataverse connection. Connect first in XrmToolBox.",
                    "Connection required",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                );
                return;
            }

            WorkAsync(new WorkAsyncInfo
            {
                Message = "Calling WhoAmI...",
                Work = (worker, args) =>
                {
                    var response = (WhoAmIResponse)Service.Execute(
                        new WhoAmIRequest()
                    );
                    args.Result = response.UserId;
                },
                PostWorkCallBack = args =>
                {
                    if (args.Error != null)
                    {
                        MessageBox.Show(
                            args.Error.Message,
                            "Error",
                            MessageBoxButtons.OK,
                            MessageBoxIcon.Error
                        );
                        return;
                    }
                    txtLog.AppendText($"UserId: {args.Result}\r\n");
                }
            });
        }
    }
}
