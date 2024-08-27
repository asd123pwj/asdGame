using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UIResizeSize: UIInteractBase{
    public UIResizeSize(UIBase Base): base(Base){
        _set_trigger(0);
    }
    
    public override void _PointerDown(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        _update_mouseDown_mousePos_parent(eventData);
        _update_mouseDown_size_parent(eventData);
    }

    public override void _Drag(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        _update_mouseHold_mousePos_parent(eventData);
        resize(eventData);
    }
    
    void resize(PointerEventData eventData){ 
        _rt_parent.sizeDelta = new(
            mouseDown_size_parent_local.x + mouseHold_mousePos_local_parent.x - mouseDown_mousePos_local_parent.x, 
            mouseDown_size_parent_local.y - mouseHold_mousePos_local_parent.y + mouseDown_mousePos_local_parent.y
        );
    }

}
