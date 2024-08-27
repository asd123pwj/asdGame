using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UIResizeScale: UIInteractBase{
    public UIResizeScale(UIBase Base): base(Base){
        _set_trigger(0);
    }
    
    public override void _PointerDown(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        _update_mouseDown_mousePos_parent(eventData);
        _update_mouseDown_size_parent(eventData);
        _update_mouseDown_scale_parent(eventData);
    }

    public override void _Drag(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        _update_mouseHold_mousePos_parent(eventData);
        resize(eventData);
    }

    public virtual Vector2 _constrait_scale(PointerEventData eventData, Vector2 scale){
        return scale;
    }
    
    void resize(PointerEventData eventData){ 
        Vector2 newSize_world = new(
            mouseDown_size_parent_world.x + mouseHold_mousePos_world_parent.x - mouseDown_mousePos_world_parent.x,
            mouseDown_size_parent_world.y - mouseHold_mousePos_world_parent.y + mouseDown_mousePos_world_parent.y
        );
        Vector2 scale_new = newSize_world / mouseDown_size_parent_world * mouseDown_scale_parent;
        Vector2 scale_final = _constrait_scale(eventData, scale_new);
        _rt_parent.localScale = new Vector3(scale_final.x, scale_final.y, 1);
    }

}
