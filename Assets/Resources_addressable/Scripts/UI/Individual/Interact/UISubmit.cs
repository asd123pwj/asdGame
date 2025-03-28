using UnityEngine;
using UnityEngine.EventSystems;


public class UISubmit: UIInteractBase{
    public UISubmit(UIBase Base): base(Base){}

    public override void _Submit(BaseEventData eventData, bool isBuildIn=true){
        if (isBuildIn) return; // Submit event is trigger from InputField.OnSubmit instead, so skip the build-in event
        if (!_isAvailable(eventData)) return;
        submit(eventData);
    }
    
    void submit(BaseEventData eventData){
        if (_Base is UIInputField inputField){
            _Base._Msg._send(_Base._messageID, inputField._text);
        }
        else{
            Debug.Log("No inputField");
        }
    }
}
