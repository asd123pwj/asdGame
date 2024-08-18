using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;
using Unity.VisualScripting;

public class UIResizeScaleConstrait : UIResizeScale {
    public UIResizeScaleConstrait(GameObject self): base(self){ }

    public override Vector2 _constrait_scale(PointerEventData eventData, Vector2 scale){
        float scale_max = Mathf.Max(scale.x, scale.y);
        Vector2 scale_final = new(scale_max, scale_max);
        return scale_final;
    }
}

// public class UIResizeScaleConstrait: UIInteractBase{
//     public UIResizeScaleConstrait(GameObject self): base(self){
//         _set_trigger(0);
//     }
    
//     public override void _PointerDown(PointerEventData eventData){
//         if (!_isAvailable(eventData)) return;
//         _update_mouseDown_mousePos_parent(eventData);
//         _update_mouseDown_size_parent(eventData);
//         _update_mouseDown_scale_parent(eventData);
//     }

//     public override void _Drag(PointerEventData eventData){
//         if (!_isAvailable(eventData)) return;
//         _update_mouseHold_mousePos_parent(eventData);
//         resize(eventData);
//     }
    
//     void resize(PointerEventData eventData){ 
//         Vector2 newSize_world = new(
//             mouseDown_size_parent_world.x + mouseHold_mousePos_world_parent.x - mouseDown_mousePos_world_parent.x,
//             mouseDown_size_parent_world.y - mouseHold_mousePos_world_parent.y + mouseDown_mousePos_world_parent.y
//         );
//         Vector2 scale_new = newSize_world / mouseDown_size_parent_world * mouseDown_scale_parent;
//         float maxScale = Mathf.Max(scale_new.x, scale_new.y);
//         _rt_parent.localScale = new Vector3(maxScale, maxScale, 1);
//     }

// }
