using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UISetTop: UIInteractBase{
    public UISetTop(GameObject self): base(self){}

    public override void _PointerDown(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        _set_top(eventData);
    }
    
    public void _set_top(PointerEventData eventData) {
        GameObject obj = _self;
        while(obj.transform.parent.gameObject != _Base._UISys._foreground){
            obj = obj.transform.parent.gameObject;
        }
        _Base._enable();
    }
}
