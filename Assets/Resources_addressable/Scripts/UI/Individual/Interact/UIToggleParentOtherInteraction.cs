using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UIToggleParentOtherInteraction: UIInteractBase{
    public UIToggleParentOtherInteraction(GameObject self): base(self){
        _set_trigger(0);
        disable_my_other_interaction();
        disable_my_subUI();
    }

    public override void _PointerDown(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        disable_my_other_interaction();
        disable_my_subUI();
        toggle_parent_other_interaction();
        toggle_parent_other_subUI();
    }
    
    void toggle_parent_other_interaction() {
        foreach (var interaction in _Base._parent.GetComponent<UIIndividual>()._Base._info.interactions){
            if (interaction != GetType().Name){
                _Base._parent.GetComponent<UIIndividual>()._Base._InteractMgr._toggle_interaction(interaction);
            }
        }
    }

    void toggle_parent_other_subUI() {
        foreach (var subUI in _Base._parent.GetComponent<UIIndividual>()._Base._subUIs){
            if (subUI._name != _Base._name){
                subUI._toggle();
            }
        }
    }

    void disable_my_other_interaction(){
        foreach (var interaction in _Base._info.interactions){
            if (interaction != GetType().Name){
                _Base._InteractMgr._disable_interaction(interaction);
            }
        }
    }
    
    void disable_my_subUI(){
        foreach (var subUI in _Base._subUIs){
            subUI._disable();
        }
    }
}
