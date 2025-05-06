using UnityEngine;
using System.Collections.Generic;
using UnityEngine.EventSystems;
using System.Linq;

public delegate void _UIInteraction(BaseEventData eventData, bool isBuildIn = true);

public class UIInteractBase: BaseClass{
    // ---------- Sub Tools ----------
    // public UIIndividual _ui { get { return _self.GetComponent<UIIndividual>(); } }
    // public UIBase _Base { get { return _ui._Base; } }
    public UIBase _Base;
    // ---------- Unity ----------
    public GameObject _self { get { return _Base._self; } }
    public GameObject _parent { get { return _Base._parent; } }
    public RectTransform _rt_self { get { return _Base._rt_self; } }
    public RectTransform _rt_parent { get { return _Base._rt_parent; } }
    // ---------- Config ----------
    // ----- Trigger
    List<int> _mouseTrigger;
    // ---------- Status ----------
    bool isEnable = true;
    // ----- Position
    public Vector2 mouseDown_mousePos_world_self, mouseDown_mousePos_local_self,
                   mouseHold_mousePos_world_self, mouseHold_mousePos_local_self,
                   mouseDown_pos_self, 
                   mouseDown_size_self, 
                   mouseDown_mousePos_world_parent, mouseDown_mousePos_local_parent,
                   mouseHold_mousePos_world_parent, mouseHold_mousePos_local_parent,
                   mouseDown_pos_parent, 
                   mouseDown_size_parent_local, mouseDown_size_parent_world,
                   mouseDown_scale_parent
                   ;

    public UIInteractBase(UIBase Base){
        _Base = Base;
        _set_mouseTrigger();
    }


    public void _set_mouseTrigger(){
        _mouseTrigger = new() { 0, 1, 2};
    }
    public void _set_trigger(int trigger){
        _mouseTrigger = new() { trigger };
    }
    public void _set_trigger(string trigger){
        if (new List<string> { "L", "l", "Left", "left", "LEFT" }.Contains(trigger)) 
            _mouseTrigger = new() { 0 };
        if (new List<string> { "R", "r", "Right", "right", "RIGHT" }.Contains(trigger)) 
            _mouseTrigger = new() { 1 };
        if (new List<string> { "M", "m", "Middle", "middle", "MIDDLE" }.Contains(trigger)) 
            _mouseTrigger = new() { 2 };
    }
    public void _set_trigger(List<int> trigger){
        _mouseTrigger = trigger;
    }
    public void _set_trigger(List<string> trigger){
        _mouseTrigger = new();
        if (trigger.Intersect(new List<string> { "L", "l", "Left", "left", "LEFT" }).Any()) 
            _mouseTrigger.Add(0);
        if (trigger.Intersect(new List<string> { "R", "r", "Right", "right", "RIGHT" }).Any()) 
            _mouseTrigger.Add(1);
        if (trigger.Intersect(new List<string> { "M", "m", "Middle", "middle", "MIDDLE" }).Any()) 
            _mouseTrigger.Add(2);
    }

    // ---------- Status ----------
    public void _update_mouseDown_pos_self(PointerEventData eventData){ 
        mouseDown_pos_self = _rt_self.position; 
    }
    public void _update_mouseDown_size_self(PointerEventData eventData){ 
        mouseDown_size_self = _rt_self.sizeDelta; 
    }
    public void _update_mouseDown_mousePos_self(PointerEventData eventData){ 
        mouseDown_mousePos_world_self = _get_mousePosWorld(eventData); 
        mouseDown_mousePos_local_self = _get_mousePosLocal(eventData); 
    }
    public void _update_mouseHold_mousePos_self(PointerEventData eventData){ 
        mouseHold_mousePos_local_self = _get_mousePosLocal(eventData);
        mouseHold_mousePos_world_self = _get_mousePosWorld(eventData);
    }


    public void _update_mouseDown_pos_parent(PointerEventData eventData){ 
        mouseDown_pos_parent = _rt_parent.position; 
    }
    public void _update_mouseDown_size_parent(PointerEventData eventData){ 
        mouseDown_size_parent_local = _rt_parent.sizeDelta;
        mouseDown_size_parent_world = _rt_parent.TransformVector(_rt_parent.sizeDelta) ;
    }
    public void _update_mouseDown_scale_parent(PointerEventData eventData){ 
        mouseDown_scale_parent = _rt_parent.localScale; 
    }
    public void _update_mouseDown_mousePos_parent(PointerEventData eventData){ 
        mouseDown_mousePos_world_parent = _get_mousePosWorld_parent(eventData); 
        mouseDown_mousePos_local_parent = _get_mousePosLocal_parent(eventData); 
    }
    public void _update_mouseHold_mousePos_parent(PointerEventData eventData){ 
        mouseHold_mousePos_local_parent = _get_mousePosLocal_parent(eventData);
        mouseHold_mousePos_world_parent = _get_mousePosWorld_parent(eventData);
    }

    // ---------- Converter ----------
    public Vector2 _get_mousePosLocal(PointerEventData eventData){ 
        RectTransformUtility.ScreenPointToLocalPointInRectangle(_rt_self, eventData.position, eventData.pressEventCamera, out Vector2 mousePosLocal); 
        return mousePosLocal; 
    }
    public Vector3 _get_mousePosWorld(PointerEventData eventData){ 
        RectTransformUtility.ScreenPointToWorldPointInRectangle(_rt_self, eventData.position, eventData.pressEventCamera, out Vector3 mousePosWorld); 
        return mousePosWorld; 
    }

    public Vector2 _get_mousePosLocal_parent(PointerEventData eventData){ 
        RectTransformUtility.ScreenPointToLocalPointInRectangle(_rt_parent, eventData.position, eventData.pressEventCamera, out Vector2 mousePosLocal);
        return mousePosLocal; 
    }
    public Vector3 _get_mousePosWorld_parent(PointerEventData eventData){ 
        RectTransformUtility.ScreenPointToWorldPointInRectangle(_rt_parent, eventData.position, eventData.pressEventCamera, out Vector3 mousePosWorld); 
        return mousePosWorld; 
    }

    // ---------- Available ----------
    public void _enable(){ isEnable = true;}
    public void _disable(){ isEnable = false;}
    public void _toggle(){ isEnable = !isEnable; }
    public bool _isAvailable(BaseEventData eventData){
        if (!isEnable) return false;
        if (eventData is PointerEventData pointerEventData){
            if (!_mouseTrigger.Contains((int)pointerEventData.button)) return false;
        }
        // if (!_mouseTrigger.Contains((int)eventData.button)) return false;
        return true;
    }

    // ---------- Interactions ----------
    public virtual bool _main(BaseEventData eventData){ return true; }
    public virtual void _PointerEnter(BaseEventData eventData, bool isBuildIn=true) {  }
    public virtual void _PointerExit(BaseEventData eventData, bool isBuildIn=true) {  }
    public virtual void _PointerDown(BaseEventData eventData, bool isBuildIn=true) {  }
    public virtual void _PointerUp(BaseEventData eventData, bool isBuildIn=true) {  } 
    public virtual void _PointerClick(BaseEventData eventData, bool isBuildIn=true){  }
    public virtual void _Drag(BaseEventData eventData, bool isBuildIn=true) { }
    public virtual void _Drop(BaseEventData eventData, bool isBuildIn=true) { }
    public virtual void _Scroll(BaseEventData eventData, bool isBuildIn=true) { }
    public virtual void _UpdateSelected(BaseEventData eventData, bool isBuildIn=true) { }
    public virtual void _Select(BaseEventData eventData, bool isBuildIn=true) { }
    public virtual void _Deselect(BaseEventData eventData, bool isBuildIn=true) { }
    public virtual void _Move(BaseEventData eventData, bool isBuildIn=true) { }
    public virtual void _InitializePotentialDrag(BaseEventData eventData, bool isBuildIn=true) { }
    public virtual void _BeginDrag(BaseEventData eventData, bool isBuildIn=true) { }
    public virtual void _EndDrag(BaseEventData eventData, bool isBuildIn=true) { }
    public virtual void _Submit(BaseEventData eventData, bool isBuildIn=true) { }   
    public virtual void _Cancel(BaseEventData eventData, bool isBuildIn=true) { }


}
