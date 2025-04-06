using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;
using Unity.VisualScripting;
// using Force.DeepCloner;
using System;


public class UIOpenRightMenu: UIInteractBase{
    public UIOpenRightMenu(UIBase Base): base(Base){
        _set_trigger(1);
    }
    
    public override void _PointerDown(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        open_rightMenu((PointerEventData)eventData);
    }
    
    void open_rightMenu(PointerEventData eventData) {
        if (_Base._subUIs != null) {
            foreach (var subUI in _Base._subUIs){
                if (subUI._name == _Base._rightMenu_name){
                    subUI._enable(_get_mousePosWorld(eventData));
                    return;
                }
            }
        }
        else{
            _Base._subUIs = new();
        }
        UIInfo info = UIClass._UIInfos[_Base._rightMenu_name].Copy();
        info.anchoredPosition = _get_mousePosLocal(eventData);
        
        info.attributes ??= new();
        // if (info.attributes.ContainsKey("RIGHT_MENU_OWNER")) 
        info.attributes["RIGHT_MENU_OWNER"] = _Base._runtimeID;
        // else info.attributes.Add("RIGHT_MENU_OWNER", _Base._runtimeID);
        Debug.Log(info.attributes["RIGHT_MENU_OWNER"]);
        UIBase RMenu = UIDraw._draw_UI(_self, _Base._rightMenu_name, info);
        _Base._subUIs.Add(RMenu);
    }



}
