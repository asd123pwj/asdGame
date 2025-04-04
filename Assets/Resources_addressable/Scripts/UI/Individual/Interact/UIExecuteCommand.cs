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
    
    void execute_command(BaseEventData eventData){
        string cmd = _Base._Msg._get_message(_Base._messageID);
        if (cmd == "") return;
        cmd = $"{cmd} --asItsChild {_Base._runtimeID}";
        CommandSystem._execute(cmd);
    }
}
