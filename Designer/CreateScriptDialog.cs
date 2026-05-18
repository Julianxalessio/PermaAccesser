using System;
using System.Drawing;
using System.Windows.Forms;

namespace PermaAccesser.Designer;

public partial class CreateScriptDialog : Form
{
    [System.ComponentModel.DesignerSerializationVisibility(System.ComponentModel.DesignerSerializationVisibility.Hidden)]
    public string ScriptName { get; set; } = string.Empty;

    [System.ComponentModel.DesignerSerializationVisibility(System.ComponentModel.DesignerSerializationVisibility.Hidden)]
    public string ScriptCode { get; set; } = string.Empty;

    public CreateScriptDialog()
    {
        InitializeComponent();
    }

    private void BtnOk_Click(object? sender, EventArgs e)
    {
        if (string.IsNullOrWhiteSpace(txtScriptName.Text))
        {
            MessageBox.Show("Please enter a script name.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        if (string.IsNullOrWhiteSpace(txtScriptCode.Text))
        {
            MessageBox.Show("Please enter script code.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        ScriptName = txtScriptName.Text.Trim();
        ScriptCode = txtScriptCode.Text;

        DialogResult = DialogResult.OK;
        Close();
    }

    private void BtnCancel_Click(object? sender, EventArgs e)
    {
        DialogResult = DialogResult.Cancel;
        Close();
    }

    #region Designer
    private TextBox txtScriptName = null!;
    private TextBox txtScriptCode = null!;
    private Button btnOk = null!;
    private Button btnCancel = null!;
    private Label lblName = null!;
    private Label lblCode = null!;

    private void InitializeComponent()
    {
        txtScriptName = new TextBox();
        txtScriptCode = new TextBox();
        btnOk = new Button();
        btnCancel = new Button();
        lblName = new Label();
        lblCode = new Label();

        SuspendLayout();

        lblName.AutoSize = true;
        lblName.Location = new Point(20, 20);
        lblName.Text = "Script Name:";
        lblName.Font = new Font("Segoe UI", 10F, FontStyle.Bold);

        txtScriptName.Location = new Point(20, 45);
        txtScriptName.Size = new Size(400, 25);
        txtScriptName.Font = new Font("Segoe UI", 10F);

        lblCode.AutoSize = true;
        lblCode.Location = new Point(20, 85);
        lblCode.Text = "Command Code:";
        lblCode.Font = new Font("Segoe UI", 10F, FontStyle.Bold);

        txtScriptCode.Location = new Point(20, 110);
        txtScriptCode.Size = new Size(400, 200);
        txtScriptCode.Multiline = true;
        txtScriptCode.ScrollBars = ScrollBars.Vertical;
        txtScriptCode.Font = new Font("Consolas", 10F);

        btnOk.Location = new Point(200, 330);
        btnOk.Size = new Size(100, 35);
        btnOk.Text = "Create";
        btnOk.BackColor = Color.FromArgb(22, 163, 74);
        btnOk.ForeColor = Color.White;
        btnOk.FlatStyle = FlatStyle.Flat;
        btnOk.Click += BtnOk_Click;

        btnCancel.Location = new Point(320, 330);
        btnCancel.Size = new Size(100, 35);
        btnCancel.Text = "Cancel";
        btnCancel.BackColor = Color.FromArgb(248, 81, 73);
        btnCancel.ForeColor = Color.White;
        btnCancel.FlatStyle = FlatStyle.Flat;
        btnCancel.Click += BtnCancel_Click;

        Controls.Add(lblName);
        Controls.Add(txtScriptName);
        Controls.Add(lblCode);
        Controls.Add(txtScriptCode);
        Controls.Add(btnOk);
        Controls.Add(btnCancel);

        AutoScaleDimensions = new SizeF(7F, 15F);
        AutoScaleMode = AutoScaleMode.Font;
        ClientSize = new Size(440, 380);
        ControlBox = true;
        MaximizeBox = false;
        MinimizeBox = false;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterParent;
        Text = "Create New Script";

        ResumeLayout(false);
        PerformLayout();
    }
    #endregion
}
