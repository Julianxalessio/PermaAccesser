using System;

namespace PermaAccesser.Designer;

public class ScriptModel
{
    public string Name { get; set; } = string.Empty;
    public string CommandCode { get; set; } = string.Empty;
    public string Status { get; set; } = "Stopped";
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime LastModified { get; set; } = DateTime.Now;
}
