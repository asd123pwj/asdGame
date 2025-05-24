using System;
using System.Collections.Generic;
using UnityEngine;


public class ObjectIdentity{
    // ---------- Status ----------
    ObjectBase _Base;
    static Dictionary<string, Type> _actionTypes = new ();
    public Dictionary<string, ObjectAsBase> _actions = new ();
    
    public ObjectIdentity(ObjectBase config){
        _Base = config;
        init_action();
    }

    ObjectAsBase _get_action(string action_name){
        if (!_actionTypes.TryGetValue(action_name, out Type type)){
            type = Type.GetType(action_name);
            _actionTypes.Add(action_name, type);
            if (type == null){
                return null;
            }
        }
        object[] args = new object[] { _Base};
        ObjectAsBase action = (ObjectAsBase)Activator.CreateInstance(type, args);
        return action;
    } 
    
    public void init_action(){
        clear_actions();
        if (_Base._cfg.tags == null) return;
        if (!_Base._cfg.tags.TryGetValue("identity", out List<string> identities)) return;
        foreach (var identity in identities){
            ObjectAsBase action = _get_action(identity);
            if (action == null) {
                Debug.Log("ObjectIdentity: No action found for identity: " + identity);
            }
            else{
                _actions.Add(identity, action);
                action._apply();
            }
        }
    }

    void clear_actions(){
        foreach (var action in _actions.Values){
            action._clear();
        }
        _actions.Clear();
    }
}
