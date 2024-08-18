using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UIClickClose: UIInteractBase{
    public UIClickClose(GameObject self): base(self){
        _set_trigger(0);
    }

    // public override void _register_interaction(){
    //     _Cfg._Event._event_PointerDown.Add(interaction_PointerDown);
    // }
    
    public override void _PointerDown(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        close(eventData);
    }
    
    void close(PointerEventData eventData){
        _Base._parent.SetActive(false);
    }



}
