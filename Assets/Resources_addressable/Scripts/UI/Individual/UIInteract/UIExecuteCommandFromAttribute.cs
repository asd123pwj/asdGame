public class UIExecuteCommandFromAttribute: UIExecuteCommand{
    public UIExecuteCommandFromAttribute(UIBase Base): base(Base){ }
    public override string _get_command() => _Base._info.attributes["COMMAND"].get<string>();
    
}
