using UnityEngine;
using Cysharp.Threading.Tasks;
using System;

public class UIDraw: BaseClass{

    public bool _toggle(string type, string name="", Vector2? pos=null){
        UIInfo info = UIClass._set_default(type, name);
        if (_open(type, info.name, pos)) return true;
        // else return _close(type, name);
        else return _close(info.name);
    }

    public bool _open(string type, string name="", Vector2? pos=null){
        UIInfo info = UIClass._set_default(type, name);
        // if (pos != null) info.anchoredPosition = pos.Value;
        UIBase ui = _draw(type, info);
        if (ui != null) {
            if (pos!=null) ui._set_pos(pos.Value).Forget();
            return true;
        }
        else if (_UISys._UIMonitor._get_UI(info.name)._isAvailable) {
            return false;
        }
        else{
            ui = _UISys._UIMonitor._get_UI(info.name);
            ui._enable();
            if (pos!=null) ui._set_pos(pos.Value).Forget();
            return true;
        }
    }

    public bool _close(string name=""){
        // UIInfo info = UIClass._set_default(type, name);
        // Debug.Log("close " + name);
        if (!_UISys._UIMonitor._get_UI(name)._isAvailable) return false;
        else{
            _UISys._UIMonitor._get_UI(name)._disable();
            return true;
        }
    }
    
    public static UIBase _draw_UI(GameObject parent, string ui_type, UIInfo info=null){
        UIInfo info_ = UIClass._set_default(ui_type, info);
        Type type = Type.GetType(info_.base_type);
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

    public UIBase _draw(string type, UIInfo info=null) {
        UIInfo info_ = UIClass._set_default(type, info);
        if (_UISys._UIMonitor._get_UI(info_.name) != null){
            return null;
        }
        else{
            UIBase ui = _draw_UI(_UISys._foreground, type, info);
            // _UISys._UIMonitor._UIs[info_.name] = ui;
            // _UISys._UIMonitor._add_UI(info_.name, ui);
            return ui;
        }
    }

}
