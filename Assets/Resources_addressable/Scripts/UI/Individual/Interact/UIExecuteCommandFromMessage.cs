using UnityEngine;
using UnityEngine.EventSystems;


public class UIExecuteCommandFromMessage: UIExecuteCommand{
    public UIExecuteCommandFromMessage(UIBase Base): base(Base){ }
    public override string _get_command() => _Base._Msg._get_message(_Base._messageID);
}
