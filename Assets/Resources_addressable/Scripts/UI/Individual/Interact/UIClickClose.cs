using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UIClickClose: UIInteractBase{
    public UIClickClose(UIBase Base): base(Base){
        _set_trigger(0);
    }

    // public override void _register_interaction(){
    //     _Cfg._Event._event_PointerDown.Add(interaction_PointerDown);
    // }
    
    public override void _PointerDown(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        close((PointerEventData)eventData);
    }
    
    void close(PointerEventData eventData){
        _Base._parent.SetActive(false);
    }



}
