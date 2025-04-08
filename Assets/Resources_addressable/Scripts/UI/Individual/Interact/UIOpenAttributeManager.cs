using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UIOpenAttributeManager: UIInteractBase{
    public UIOpenAttributeManager(UIBase Base): base(Base){
        _set_trigger(0);
    }
    
    public override void _PointerDown(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        open_AttributeManager((PointerEventData)eventData);
    }
    
    void open_AttributeManager(PointerEventData eventData) {
        if (_Base._subUIs != null) {
            foreach (var subUI in _Base._subUIs){
                if (subUI._info.name == "UIAttributeManager"){
                    subUI._enable(_get_mousePosWorld(eventData));
                    return;
                }
            }
        }
        else{
            _Base._subUIs = new();
        }
        UIInfo info = UIClass._UIInfos["UIAttributeManager"];
        info.anchoredPosition = _get_mousePosLocal(eventData);

        // ----- Mark item of right menu ----- //
        if (_Base._info.attributes !=null && _Base._info.attributes.ContainsKey("MENU_OWNER")) {
            info.attributes ??= new();
            info.attributes["MENU_OWNER"] = _Base._info.attributes["MENU_OWNER"];
        }
        UIBase attributeManager = UIDraw._draw_UI(_Base._UISys._foreground, "UIAttributeManager", info);
        _Base._subUIs.Add(attributeManager);
    }



}
