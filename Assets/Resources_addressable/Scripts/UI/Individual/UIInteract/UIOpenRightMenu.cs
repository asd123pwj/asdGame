using UnityEngine.EventSystems;


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
                if (subUI._info.name == _Base._info.rightMenu_name){
                    subUI._enable(_get_mousePosWorld(eventData));
                    return;
                }
            }
        }
        else{
            _Base._subUIs = new();
        }
        // UIInfo info = UIClass._UIInfos[_Base._info.rightMenu_name].Copy();
        UIInfo info = UIClass._set_default(_Base._info.rightMenu_name);
        info.anchoredPosition = _get_mousePosLocal(eventData);
        
        info.attributes ??= new();
        // if (info.attributes.ContainsKey("OWNER")) 
        info.attributes["OWNER"] = _Base._runtimeID;
        // else info.attributes.Add("OWNER", _Base._runtimeID);
        // Debug.Log(info.attributes["OWNER"]);
        UIBase RMenu = UIDraw._draw_UI(_self, _Base._info.rightMenu_name, info);
        _Base._subUIs.Add(RMenu);
    }



}
