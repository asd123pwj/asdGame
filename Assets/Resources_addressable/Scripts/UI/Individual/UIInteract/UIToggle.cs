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

    public UIToggle(UIBase Base): base(Base){
        _set_trigger(0);
        find_target();
    }

    public override void _PointerDown(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        toggle_interaction();
        toggle_subUI();
    }
    
    void toggle_subUI() {
        if (target_type != 0) return;
        // foreach (var subUI in target_obj.GetComponent<UIIndividual>()._Base._subUIs){
        foreach (var subUI in _Base._UISys._UIMonitor._UIObj2base[target_obj]._subUIs){
            if (subUI._info.name == target){
                subUI._toggle();
            }
        }
    }

    void toggle_interaction() {
        if (target_type != 1) return;
        // target_obj.GetComponent<UIIndividual>()._Base._InteractMgr._toggle_interaction(target);
        _Base._UISys._UIMonitor._UIObj2base[target_obj]._InteractMgr._toggle_interaction(target);
    }

    void find_target(){
        // ----- Find target object
        target_obj = _Base._self;
        // Target object is the parent of the rightMenu.
        while (_Base._UISys._UIMonitor._UIObj2base.ContainsKey(target_obj) || _Base._UISys._UIMonitor._UIObj2base[target_obj].GetType() != typeof(UIRightMenu)){
            target_obj = target_obj.transform.parent.gameObject;
        }
        target_obj = target_obj.transform.parent.gameObject;

        // ----- Find target interaction or subUI
        if (_Base._info.name.StartsWith("UIToggleSubUI-")){
            target = _Base._info.name[14..];
            target_type = 0;
        }
        else if (_Base._info.name.StartsWith("UIToggleInteraction-")){
            target = _Base._info.name[20..];
            target_type = 1;
        }
        else{
            Debug.LogError("Can't parse of targetType of UIName: " + _Base._info.name);
        }
    }
}
