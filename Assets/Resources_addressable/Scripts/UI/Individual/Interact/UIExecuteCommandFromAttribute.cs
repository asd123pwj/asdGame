using System;
using UnityEngine;
using UnityEngine.EventSystems;


public class UIExecuteCommandFromAttribute: UIExecuteCommand{
    public UIExecuteCommandFromAttribute(UIBase Base): base(Base){ }
    public override string _get_command() => _Base._attributes["command"].get<string>();
    
}
