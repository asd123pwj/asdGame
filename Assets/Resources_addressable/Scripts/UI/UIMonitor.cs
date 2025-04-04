using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using UnityEngine.EventSystems;
using System.Collections.Generic;
using System;

public struct UIs{
    public Dictionary<string, UIBase> fg;
    public List<string> fg_Hier;
}

public class UIMonitor: BaseClass{
    // ---------- UI Tool ----------
    GameConfigs GCfg;
    // ---------- Status ----------
    UIs UIs;
    public UIBase rightMenu_currentOpen;
    public Dictionary<GameObject, UIBase> _UIObj2base;
    Dictionary<int, UIBase> _runtimeID2base;

    // public UIMonitor(GameConfigs GCfg){
    //     this.GCfg = GCfg;
    //     init();
    // }

    public override void _init(){
        UIs = new(){
            fg = new(),
            fg_Hier = new(),
        };
        _UIObj2base = new();
        _runtimeID2base = new();
    }

    public UIs _get_UIs(){
        return UIs;
    }

    public void _clear_UIs(){
        foreach (var UI in UIs.fg.Values){
            // UI._ui._destroy();
            UI._destroy();
        }
        UIs.fg.Clear();
    }

    public UIBase _get_UI_fg(string name){
        if (!UIs.fg.ContainsKey(name)) return null;
        return UIs.fg[name];
    }
    public UIBase _get_UI(int runtimeID){
        if (!_runtimeID2base.ContainsKey(runtimeID)) return null;
        return _runtimeID2base[runtimeID];
    }

    public string _get_UIHier(){
        if (UIs.fg_Hier.Count > 0){
            return UIs.fg_Hier[^1];
        }
        return null;
    }

    public void _add_UI_fg(UIBase ui){
        UIs.fg.Add(ui._name, ui);
    }
    public void _add_UI(UIBase ui){
        _runtimeID2base.Add(ui._runtimeID, ui);
        _UIObj2base.Add(ui._self, ui);
    }

    public bool _hide_UI_fg(UIBase ui){
        if (!UIs.fg.ContainsKey(ui._name)) return false;
        UIs.fg_Hier.Remove(ui._name);
        return true;
    }

    public bool _show_UI(UIBase ui){
        if (!UIs.fg.ContainsKey(ui._name)) return false;
        UIs.fg_Hier.Remove(ui._name);
        UIs.fg_Hier.Add(ui._name);
        return true;
    }

    public bool _remove_UI_fg(UIBase ui){
        if (!UIs.fg.ContainsKey(ui._name)) return false;
        UIs.fg_Hier.Remove(ui._name);
        UIs.fg.Remove(ui._name); 
        return true;
    }


}
