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

    public UIBase _get_UI(string name){
        if (!UIs.fg.ContainsKey(name)) return null;
        return UIs.fg[name];
    }

    public string _get_UIHier(){
        if (UIs.fg_Hier.Count > 0){
            return UIs.fg_Hier[^1];
        }
        return null;
    }

    public void _add_UI(string name, UIBase ui){
        UIs.fg.Add(name, ui);
    }

    public bool _hide_UI(string name){
        if (!UIs.fg.ContainsKey(name)) return false;
        UIs.fg_Hier.Remove(name);
        return true;
    }

    public bool _show_UI(string name){
        if (!UIs.fg.ContainsKey(name)) return false;
        UIs.fg_Hier.Remove(name);
        UIs.fg_Hier.Add(name);
        return true;
    }

    public bool _remove_UI(string name){
        if (!UIs.fg.ContainsKey(name)) return false;
        UIs.fg_Hier.Remove(name);
        UIs.fg.Remove(name); 
        return true;
    }


}
