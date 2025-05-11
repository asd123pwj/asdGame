using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;

public class ObjectIdentity{
    // ---------- Action ----------
    // List<Action> _actions = new();
    // ---------- Config ----------
    ObjectBase _config;
    // ---------- Status ----------
    
    public ObjectIdentity(ObjectBase config){
        _config = config;
        init_action();
    }

    // public void _update(){
    //     foreach (var action in _actions){
    //         action();
    //     }
    // }

    void init_action(){
        // List<string> identity = _config._tags.identity;
        if (_config._cfg.tags == null) return;
        if (!_config._cfg.tags.TryGetValue("identity", out List<string> identity)) return;
        // ---------- Action Init ----------
        if (identity.Contains("player")) action_player();
        // ---------- Action Default ----------
    }

    void action_player(){
        // ControlSystem con = _config._sys._searchInit<ControlSystem>("System");
        // BaseClass._sys._CtrlSys._set_player(_config);
        BaseClass._sys._ObjSys._mon._set_player(_config);
    }
    
}
