using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using UnityEngine.EventSystems;
using System.Collections.Generic;
using System;
using Cysharp.Threading.Tasks;
using System.Linq;

public struct UIs{
    public Dictionary<string, UIBase> fg;
    public List<string> fg_Hier;
}

public class UIMonitor: BaseClass{
    // ---------- Status ----------
    UIs UIs;
    public UIBase rightMenu_currentOpen = null;
    public UIBase ui_currentPointerEnter = null;
    UIBase UI_selected;
    // public UIBase _UI_selected { get => UI_selected; set => try_toggle_rightMenu(value); }
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
        List<string> keys = UIs.fg.Keys.ToList();
        foreach (var key in keys){
            UIs.fg[key]._destroy();
        }
        // foreach (var UI in UIs.fg.Values){
        //     // UI._ui._destroy();
        //     UI._destroy();
        // }
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
        UIs.fg.Add(ui._info.name, ui);
    }
    public void _add_UI(UIBase ui){
        _runtimeID2base.Add(ui._runtimeID, ui);
        _UIObj2base.Add(ui._self, ui);
    }

    public bool _hide_UI_fg(UIBase ui){
        if (!UIs.fg.ContainsKey(ui._info.name)) return false;
        UIs.fg_Hier.Remove(ui._info.name);
        return true;
    }

    public bool _show_UI(UIBase ui){
        if (!UIs.fg.ContainsKey(ui._info.name)) return false;
        UIs.fg_Hier.Remove(ui._info.name);
        UIs.fg_Hier.Add(ui._info.name);
        return true;
    }

    public bool _remove_UI_fg(UIBase ui){
        if (!UIs.fg.ContainsKey(ui._info.name)) return false;
        UIs.fg_Hier.Remove(ui._info.name);
        UIs.fg.Remove(ui._info.name); 
        return true;
    }
    
    public bool _remove_UI(UIBase ui){
        _runtimeID2base.Remove(ui._runtimeID);
        _UIObj2base.Remove(ui._self);
        return true;
    }

    public async UniTaskVoid _set_UI_selected(UIBase ui){
        UI_selected = ui;
        if (rightMenu_currentOpen == UI_selected) return;
        if (rightMenu_currentOpen == null) return;
        while (UI_selected._rt_self == null) await UniTask.Delay(10);
        while (rightMenu_currentOpen._rt_self == null) await UniTask.Delay(10);
        if (!UI_selected._rt_self.IsChildOf(rightMenu_currentOpen._rt_self)){
            rightMenu_currentOpen._disable();
        }
    }

}
