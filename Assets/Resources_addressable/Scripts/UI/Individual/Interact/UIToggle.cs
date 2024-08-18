using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UIToggle: UIInteractBase{
    public GameObject target_obj;
    int target_type;
    string target;

    public UIToggle(GameObject self): base(self){
        _set_trigger(0);
        find_target();
    }

    public override void _PointerDown(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        toggle_interaction();
        toggle_subUI();
    }
    
    void toggle_subUI() {
        if (target_type != 0) return;
        foreach (var subUI in target_obj.GetComponent<UIIndividual>()._Base._subUIs){
            if (subUI._name == target){
                subUI._toggle();
            }
        }
    }

    void toggle_interaction() {
        if (target_type != 1) return;
        target_obj.GetComponent<UIIndividual>()._Base._InteractMgr._toggle_interaction(target);
    }

    void find_target(){
        // ----- Find target object
        target_obj = _Base._self;
        // Target object is the parent of the rightMenu.
        while (target_obj.GetComponent<UIIndividual>() == null || target_obj.GetComponent<UIIndividual>()._Base.GetType() != typeof(UIRightMenu)){
            target_obj = target_obj.transform.parent.gameObject;
        }
        target_obj = target_obj.transform.parent.gameObject;

        // ----- Find target interaction or subUI
        if (_Base._name.StartsWith("UIToggleSubUI-")){
            target = _Base._name[14..];
            target_type = 0;
        }
        else if (_Base._name.StartsWith("UIToggleInteraction-")){
            target = _Base._name[20..];
            target_type = 1;
        }
        else{
            Debug.LogError("Can't parse of targetType of UIName: " + _Base._name);
        }
    }
}
