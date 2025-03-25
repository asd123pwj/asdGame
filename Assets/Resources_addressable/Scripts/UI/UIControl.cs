using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using UnityEngine.EventSystems;

public class UIControl: BaseClass{
    // ---------- UI Tool ----------
    // GameConfigs _GCfg;
    // UISystem _UISys { get { return _GCfg._UISys; } }
    // ---------- Sub Tools ----------
    // ---------- Status ----------

    // public UIControl(GameConfigs GCfg){
    //     // _GCfg = GCfg;
    // }

    public override bool _check_allow_init(){
        if (!_sys._initDone) return false;
        return true;
    }

    public override void _init(){
        _GCfg._InputSys._register_action("Menu 1", _open_menu1, "isFirstDown");
        // _GCfg._InputSys._register_action("Menu 2", _open_menu2, "isFirstDown");
        _GCfg._InputSys._register_action("Menu 3", _open_menu3, "isFirstDown");
        _GCfg._InputSys._register_action("Menu Wheel", _close_menu, "isFirstDown");
        _GCfg._InputSys._register_action("Save", _save_UI, "isFirstDown");
        _GCfg._InputSys._register_action("Load", _load_UI, "isFirstDown");
        
    }

    // public void _update(){

    // }

    public bool _open_menu1(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        return _UISys._UIDraw._open_or_close("UIBackpack", "back");
    }
    
    public bool _open_menu2(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        return _UISys._UIDraw._open_or_close("UIContainer", "UIContainer");
    }
    
    public bool _open_menu3(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        // UIInfo2 a = new();
        // Debug.Log(a.name);
        // a.name = "1";
        // Debug.Log(a.name);

        // return _UISys._UIDraw._open_or_close("UIScrollView");
        return _UISys._UIDraw._open_or_close("UICommandWindow");
        // return _UISys._UIDraw._open_or_close("UIInputField");
    }

    public bool _close_menu(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        string UI_top = _UISys._UIMonitor._get_UIHier();
        if (UI_top != null){
            return _UISys._UIDraw._close(UI_top);
        }
        return false;
    }

    public bool _save_UI(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        return _UISys._UISL._save_UI();
    }

    public bool _load_UI(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        return _UISys._UISL._load_UIs();
    }
}
