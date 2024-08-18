using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UIDeselectClose: UIInteractBase{
    public UIDeselectClose(GameObject self): base(self){}

    // public override void _register_interaction(){
    //     _Cfg._Event._event_Deselect.Add(interaction_Deselect);
    // }
    
    public override void _Deselect(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        close(eventData);
    }
    
    void close(PointerEventData eventData){
        _Base._self.SetActive(false);
    }



}
