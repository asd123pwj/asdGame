using TMPro;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections.Generic;

public class UIEvent {
    // ---------- Sub Tools ----------
    UIBase Base;
    // ---------- Config ----------
    // ----- Event
    public List<_UIInteraction> _event_PointerEnter = new();
    public List<_UIInteraction> _event_PointerExit = new();
    public List<_UIInteraction> _event_PointerDown = new();
    public List<_UIInteraction> _event_PointerUp = new();
    public List<_UIInteraction> _event_PointerClick = new();
    public List<_UIInteraction> _event_Drag = new();
    public List<_UIInteraction> _event_Drop = new();
    public List<_UIInteraction> _event_Scroll = new();
    public List<_UIInteraction> _event_UpdateSelected = new();
    public List<_UIInteraction> _event_Select = new();
    public List<_UIInteraction> _event_Deselect = new();
    public List<_UIInteraction> _event_Move = new();
    public List<_UIInteraction> _event_InitializePotentialDrag = new();
    public List<_UIInteraction> _event_BeginDrag = new();
    public List<_UIInteraction> _event_EndDrag = new();
    public List<_UIInteraction> _event_Submit = new();
    public List<_UIInteraction> _event_Cancel = new();

    public UIEvent(UIBase UIBase){
        Base = UIBase;
    }

    public void _action_pointer_enter(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_PointerEnter)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_pointer_exit(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_PointerExit)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_pointer_down(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_PointerDown)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_pointer_up(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_PointerUp)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_pointer_click(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_PointerClick)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_drag(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_Drag)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_drop(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_Drop)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_scroll(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_Scroll)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_update_selected(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_UpdateSelected)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_select(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_Select)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_deselect(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_Deselect)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_move(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_Move)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_initialize_potential_drag(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_InitializePotentialDrag)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_begin_drag(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_BeginDrag)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_end_drag(PointerEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_EndDrag)
            UIInteraction(eventData, isBuildIn);
    }
    
    // public void _action_submit(PointerEventData eventData){
    public void _action_submit(BaseEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_Submit)
            UIInteraction(eventData, isBuildIn);
    }
    public void _action_cancel(BaseEventData eventData, bool isBuildIn=true){
        foreach (var UIInteraction in _event_Cancel)
            UIInteraction(eventData, isBuildIn);
    }


}
