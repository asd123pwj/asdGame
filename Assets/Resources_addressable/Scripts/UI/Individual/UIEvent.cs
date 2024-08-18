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

    public void _action_pointer_enter(PointerEventData eventData){
        foreach (var UIInteraction in _event_PointerEnter)
            UIInteraction(eventData);
    }
    public void _action_pointer_exit(PointerEventData eventData){
        foreach (var UIInteraction in _event_PointerExit)
            UIInteraction(eventData);
    }
    public void _action_pointer_down(PointerEventData eventData){
        foreach (var UIInteraction in _event_PointerDown)
            UIInteraction(eventData);
    }
    public void _action_pointer_up(PointerEventData eventData){
        foreach (var UIInteraction in _event_PointerUp)
            UIInteraction(eventData);
    }
    public void _action_pointer_click(PointerEventData eventData){
        foreach (var UIInteraction in _event_PointerClick)
            UIInteraction(eventData);
    }
    public void _action_drag(PointerEventData eventData){
        foreach (var UIInteraction in _event_Drag)
            UIInteraction(eventData);
    }
    public void _action_drop(PointerEventData eventData){
        foreach (var UIInteraction in _event_Drop)
            UIInteraction(eventData);
    }
    public void _action_scroll(PointerEventData eventData){
        foreach (var UIInteraction in _event_Scroll)
            UIInteraction(eventData);
    }
    public void _action_update_selected(PointerEventData eventData){
        foreach (var UIInteraction in _event_UpdateSelected)
            UIInteraction(eventData);
    }
    public void _action_select(PointerEventData eventData){
        foreach (var UIInteraction in _event_Select)
            UIInteraction(eventData);
    }
    public void _action_deselect(PointerEventData eventData){
        foreach (var UIInteraction in _event_Deselect)
            UIInteraction(eventData);
    }
    public void _action_move(PointerEventData eventData){
        foreach (var UIInteraction in _event_Move)
            UIInteraction(eventData);
    }
    public void _action_initialize_potential_drag(PointerEventData eventData){
        foreach (var UIInteraction in _event_InitializePotentialDrag)
            UIInteraction(eventData);
    }
    public void _action_begin_drag(PointerEventData eventData){
        foreach (var UIInteraction in _event_BeginDrag)
            UIInteraction(eventData);
    }
    public void _action_end_drag(PointerEventData eventData){
        foreach (var UIInteraction in _event_EndDrag)
            UIInteraction(eventData);
    }
    public void _action_submit(PointerEventData eventData){
        foreach (var UIInteraction in _event_Submit)
            UIInteraction(eventData);
    }
    public void _action_cancel(PointerEventData eventData){
        foreach (var UIInteraction in _event_Cancel)
            UIInteraction(eventData);
    }


}
