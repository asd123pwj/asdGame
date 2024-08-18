using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UIDrag: UIInteractBase{
    public UIDrag(GameObject self): base(self){
        _set_trigger(0);
    }
    
    public override void _PointerDown(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        _update_mouseDown_mousePos_self(eventData);
        _update_mouseDown_pos_self(eventData);
    }
    
    public override void _Drag(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        _update_mouseHold_mousePos_self(eventData);
        drag();
    }

    public override void _BeginDrag(PointerEventData eventData){
        var canvasGroup = _self.GetComponent<CanvasGroup>();
        if (canvasGroup == null) 
            canvasGroup = _self.AddComponent<CanvasGroup>();
        canvasGroup.blocksRaycasts = false;
        drag_from_container();
    }

    public override void _EndDrag(PointerEventData eventData){
        var canvasGroup = _self.GetComponent<CanvasGroup>();
        if (canvasGroup == null) 
            canvasGroup = _self.AddComponent<CanvasGroup>();
        canvasGroup.blocksRaycasts = true;
    }

    void drag(){ 
        _rt_self.position = mouseHold_mousePos_world_self -  mouseDown_mousePos_world_self + mouseDown_pos_self;        
    }

    GameObject get_parent_ScrollView(){
        // Item -> Container -> Content -> Viewport -> ScrollView
        return _self.transform.parent.parent.parent.parent.gameObject;
    }

    void drag_from_container(){
        // [EXIT] isn't item
        if (!_Base._info.isItem) return;
        // remove item from ScrollView.info
        GameObject ScrollView = get_parent_ScrollView();
        if (ScrollView.GetComponent<UIIndividual>()._Base is UIScrollView SV_base) {
            SV_base._remove_item(_Base);
        }
        // set item's parent to foreground
        _Base._set_parent(_Base._UISys._foreground);
    }

}
