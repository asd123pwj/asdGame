using UnityEngine;
using UnityEngine.EventSystems;


public class UIReceiver: UIInteractBase{
    public UIReceiver(UIBase Base): base(Base){}

    public override void _Submit(BaseEventData eventData, bool isBuildIn=true){
        if (isBuildIn) return; // Submit event is trigger from InputField.OnSubmit instead, so skip the build-in event
        if (!_isAvailable(eventData)) return;
        log(eventData);
    }
    
    void log(BaseEventData eventData){
        if (_Base is UIInputField inputField){
            MessageBus._send(_Base._messageID, inputField._text);
        // if (_Base is UIInputField inputField){
            Debug.Log(inputField._text);
        }
        else{
            Debug.Log("No inputField");
        }
    }
}
