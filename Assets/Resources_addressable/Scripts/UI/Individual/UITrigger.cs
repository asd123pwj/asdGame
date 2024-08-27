using TMPro;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections.Generic;

public class UITrigger{
    UIBase Base;
    EventTrigger eventTrigger;

    public UITrigger(UIBase UIBase){
        this.Base = UIBase;
        // this.Cfg._Trigger = this;
        // _init_eventTrigger();
    }

    // public void _update(){
    // }

    public void _init_eventTrigger(){
        eventTrigger = Base._self.GetComponent<EventTrigger>();
        if (eventTrigger == null) 
            eventTrigger = Base._self.AddComponent<EventTrigger>();
        else 
            eventTrigger.triggers.Clear();
        init_eventTrigger_trigger();
    }

    void init_eventTrigger_trigger(){
        EventTrigger.Entry entry;

        if (Base._Event._event_PointerEnter.Count > 0) { 
            entry = new() { eventID = EventTriggerType.PointerEnter }; 
            entry.callback.AddListener((data) => Base._Event._action_pointer_enter((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_PointerExit.Count > 0) { 
            entry = new() { eventID = EventTriggerType.PointerExit }; 
            entry.callback.AddListener((data) => Base._Event._action_pointer_exit((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_PointerDown.Count > 0) { 
            entry = new() { eventID = EventTriggerType.PointerDown }; 
            entry.callback.AddListener((data) => Base._Event._action_pointer_down((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_PointerUp.Count > 0) { 
            entry = new() { eventID = EventTriggerType.PointerUp }; 
            entry.callback.AddListener((data) => Base._Event._action_pointer_up((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_PointerClick.Count > 0) { 
            entry = new() { eventID = EventTriggerType.PointerClick }; 
            entry.callback.AddListener((data) => Base._Event._action_pointer_click((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_Drag.Count > 0) { 
            entry = new() { eventID = EventTriggerType.Drag }; 
            entry.callback.AddListener((data) => Base._Event._action_drag((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_Drop.Count > 0) { 
            entry = new() { eventID = EventTriggerType.Drop }; 
            entry.callback.AddListener((data) => Base._Event._action_drop((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_Scroll.Count > 0) { 
            entry = new() { eventID = EventTriggerType.Scroll }; 
            entry.callback.AddListener((data) => Base._Event._action_scroll((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_UpdateSelected.Count > 0) { 
            entry = new() { eventID = EventTriggerType.UpdateSelected }; 
            entry.callback.AddListener((data) => Base._Event._action_update_selected((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_Select.Count > 0) { 
            entry = new() { eventID = EventTriggerType.Select }; 
            entry.callback.AddListener((data) => Base._Event._action_select((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_Deselect.Count > 0) { 
            entry = new() { eventID = EventTriggerType.Deselect }; 
            entry.callback.AddListener((data) => Base._Event._action_deselect((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_Move.Count > 0) { 
            entry = new() { eventID = EventTriggerType.Move }; 
            entry.callback.AddListener((data) => Base._Event._action_move((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_InitializePotentialDrag.Count > 0) { 
            entry = new() { eventID = EventTriggerType.InitializePotentialDrag }; 
            entry.callback.AddListener((data) => Base._Event._action_initialize_potential_drag((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_BeginDrag.Count > 0) { 
            entry = new() { eventID = EventTriggerType.BeginDrag }; 
            entry.callback.AddListener((data) => Base._Event._action_begin_drag((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_EndDrag.Count > 0) { 
            entry = new() { eventID = EventTriggerType.EndDrag }; 
            entry.callback.AddListener((data) => Base._Event._action_end_drag((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_Submit.Count > 0) { 
            entry = new() { eventID = EventTriggerType.Submit }; 
            entry.callback.AddListener((data) => Base._Event._action_submit((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
        if (Base._Event._event_Cancel.Count > 0) { 
            entry = new() { eventID = EventTriggerType.Cancel }; 
            entry.callback.AddListener((data) => Base._Event._action_cancel((PointerEventData)data)); 
            eventTrigger.triggers.Add(entry); 
        }
    }

}
