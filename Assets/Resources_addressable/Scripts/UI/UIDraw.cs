using UnityEngine;
using Cysharp.Threading.Tasks;
using System;
using System.Collections.Generic;

public class UIDraw: BaseClass{
    static Dictionary<string, Type> UIClasses = new Dictionary<string, Type>();

    public bool _toggle(string type, string name="", Vector2? pos=null, UIBase parent=null){
        UIInfo info = UIClass._set_default(type, name);
        if (_open(type, info.name, pos, parent)) return true;
        // else return _close(type, name);
        else return _close(info.name);
    }

    public bool _open(string type, string name="", Vector2? pos=null, UIBase parent=null, bool isForceOpen=false){
        UIInfo info = UIClass._set_default(type, name);
        // if (pos != null) info.anchoredPosition = pos.Value;
        UIBase ui = _draw(type, info, parent);
        if (ui != null) {
            if (pos!=null) ui._set_pos(pos.Value).Forget();
            // if (parent!=null) ui._set_parent(parent._self);
            return true;
        }
        else if (!isForceOpen && _UISys._UIMonitor._get_UI_fg(info.name)._isAvailable) {
            return false;
        }
        else{
            ui = _UISys._UIMonitor._get_UI_fg(info.name);
            ui._enable();
            if (pos!=null) ui._set_pos(pos.Value).Forget();
            // if (parent!=null) ui._set_parent(parent._self);
            return true;
        }
    }

    public bool _close(string name=""){
        // UIInfo info = UIClass._set_default(type, name);
        // Debug.Log("close " + name);
        if (!_UISys._UIMonitor._get_UI_fg(name)._isAvailable) return false;
        else{
            _UISys._UIMonitor._get_UI_fg(name)._disable();
            return true;
        }
    }
    
    public static UIBase _draw_UI(GameObject parent, string ui_type, UIInfo info=null){
        UIInfo info_ = UIClass._set_default(ui_type, info);
        if (!UIClasses.TryGetValue(ui_type, out Type type)){
            type = Type.GetType(info_.base_type);
            if (type == null) Debug.LogError($"type is null: {ui_type}");
            UIClasses.Add(ui_type, type);
        }
        object[] args = new object[] { parent, info_};
        UIBase cfg = (UIBase)Activator.CreateInstance(type, args);
        return cfg;
    } 

    public static UIInteractBase _draw_UIInteract(GameObject self, string interaction_name){
        Type interaction_class = Type.GetType(interaction_name);
        object[] args = new object[] { self, };
        UIInteractBase interaction = (UIInteractBase)Activator.CreateInstance(interaction_class, args);
        return interaction;
    }

    public UIBase _draw(string type, UIInfo info=null, UIBase parent_base=null) {
        UIInfo info_ = UIClass._set_default(type, info);
        if (_UISys._UIMonitor._get_UI_fg(info_.name) != null){
            return null;
        }
        GameObject parent = (parent_base == null) ? _UISys._foreground : parent_base._self;
        UIBase ui = _draw_UI(parent, info_.base_type, info_);
        return ui;

        // if (parent == null) parent = _UISys._foreground;
        // else{
        //     UIBase ui = _draw_UI(_UISys._foreground, type, info);
        //     // _UISys._UIMonitor._UIs[info_.name] = ui;
        //     // _UISys._UIMonitor._add_UI(info_.name, ui);
        //     return ui;
        // }
    }

}
