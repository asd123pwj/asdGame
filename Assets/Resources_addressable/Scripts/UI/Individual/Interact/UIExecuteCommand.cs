using UnityEngine;
using UnityEngine.EventSystems;


public class UIExecuteCommand: UIInteractBase{
    public UIExecuteCommand(UIBase Base): base(Base){
        _set_trigger(0);
    }

    public override void _PointerDown(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        execute_command(eventData);
    }

    public virtual string _get_command() => "";
    
    void execute_command(BaseEventData eventData){
        string cmd = _get_command();
        if (cmd == "") return;
        CommandSystem._execute(cmd);
    }
}
