using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UIOpenRightMenu: UIInteractBase{
    public UIOpenRightMenu(UIBase Base): base(Base){
        _set_trigger(1);
    }

    // public override void _register_interaction(){
    //     _Cfg._Event._event_PointerDown.Add(interaction_PointerDown);
    // }
    
    public override void _PointerDown(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        // if (eventData is PointerEventData)
        //     open_rightMenu((PointerEventData)eventData);
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
        UIInfo info = UIClass._UIInfos[_Base._rightMenu_name];
        info.anchoredPosition = _get_mousePosLocal(eventData);
        UIBase RMenu = UIDraw._draw_UI(_self, _Base._rightMenu_name, info);
        _Base._subUIs.Add(RMenu);
        // EventSystem.current.SetSelectedGameObject(RMenu._self);
        // if (_Base._RMenu == null) {
        //     // _Cfg._RMenu = new(_Cfg._self, _get_mousePosLocal(eventData));
        //     UIInfo info = UIClass.UIRightMenu;
        //     info.anchoredPosition = _get_mousePosLocal(eventData);
        //     _Base._RMenu = (UIRightMenu)UIDraw._draw_UI(_self, "UIRightMenuInteractionManager", info);
        // }
        // else
        //     _Base._RMenu._enable(_get_mousePosWorld(eventData)); 
    }



}
