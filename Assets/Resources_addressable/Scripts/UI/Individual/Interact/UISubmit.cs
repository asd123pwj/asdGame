using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UISubmit: UIInteractBase{
    public UISubmit(UIBase Base): base(Base){}

    public override void _Submit(BaseEventData eventData, bool isBuildIn=true){
        if (isBuildIn) return; // Submit event is trigger from InputField.OnSubmit instead, so skip the build-in event
        if (!_isAvailable(eventData)) return;
        log(eventData);
    }
    
    void log(BaseEventData eventData){
        if (_Base is UIInputField inputField){
            Debug.Log(inputField._text);
        }
        else{
            Debug.Log("No inputField");
        }
    }



}
