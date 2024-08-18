using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;
using UnityEngine.UIElements;
using System;

public class UIDraw{
    // ---------- UI Tool ----------
    GameConfigs _GCfg;
    UISystem _UISys { get { return _GCfg._UISys; } }
    

    public UIDraw(GameConfigs GCfg){
        _GCfg = GCfg;
        // draw_backpack();
        // draw_container();
    }

    public bool _open_or_close(string type, string name=""){
        UIInfo info = UIClass._set_default(type, name);
        if (_open(type, info.name)) return true;
        // else return _close(type, name);
        else return _close(info.name);
    }

    public bool _open(string type, string name=""){
        UIInfo info = UIClass._set_default(type, name);
        if (_draw(type, info)) return true;
        else if (_UISys._UIMonitor._get_UI(info.name)._isAvailable) return false;
        else{
            _UISys._UIMonitor._get_UI(info.name)._enable();
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

    public bool _draw(string type, UIInfo info=null) {
        UIInfo info_ = UIClass._set_default(type, info);
        if (_UISys._UIMonitor._get_UI(info_.name) != null){
            return false;
        }
        else{
            UIBase ui = _draw_UI(_UISys._foreground, type, info);
            // _UISys._UIMonitor._UIs[info_.name] = ui;
            // _UISys._UIMonitor._add_UI(info_.name, ui);
            return true;
        }
    }

}
