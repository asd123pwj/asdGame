using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UIDragInstantiate: UIDrag{
    Transform parent;
    public UIDragInstantiate(GameObject self): base(self){
        _set_trigger(0);
    }
    
    public override void _BeginDrag(PointerEventData eventData){
        var canvasGroup = _self.GetComponent<CanvasGroup>();
        if (canvasGroup == null) 
            canvasGroup = _self.AddComponent<CanvasGroup>();
        canvasGroup.blocksRaycasts = false;
        // save checkpoint
        parent = _self.transform.parent;    
        _rt_self.SetParent(_Base._UISys._foreground.transform);
    }

    public override void _EndDrag(PointerEventData eventData){
        // EndDrag of base
        base._EndDrag(eventData);
        // Recovery checkpoint    
        _rt_self.SetParent(parent);
        _Base._set_UIPos_MiddleMiddle();
        _Base._apply_UIPosition();
        // instantiate object
        if (_Base is UIThumbnail Thumb_base){
            Thumb_base._instantiate(_get_mousePosWorld(eventData));
        }
        else{
            Debug.LogWarning(GetType().Name + " should be attached into " + typeof(UIThumbnail).Name + ", but attached into " + _Base.GetType().Name);
        }
    }

}
