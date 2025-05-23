using System;
using System.Collections.Generic;
using UnityEngine;


public class ObjectMovement{
    // ---------- Status ----------
    ObjectBase _Base;
    static Dictionary<string, Type> _actionTypes = new ();
    public Dictionary<string, ObjectMoveBase> _actions = new ();
    KeyPos input;
    
    public ObjectMovement(ObjectBase config){
        _Base = config;
        init_action();
    }

    public void _onUpdate(){
        if (input != null){
            move();
            input = null;
        }
    }

    ObjectMoveBase _get_action(string action_name){
        if (!_actionTypes.TryGetValue(action_name, out Type type)){
            type = Type.GetType(action_name);
            _actionTypes.Add(action_name, type);
            if (type == null){
                return null;
            }
        }
        object[] args = new object[] { _Base};
        ObjectMoveBase action = (ObjectMoveBase)Activator.CreateInstance(type, args);
        return action;
    } 
    
    public void init_action(){
        if (_Base._cfg.tags == null) return;
        if (!_Base._cfg.tags.TryGetValue("movement", out List<string> movements)) return;
        foreach (var movement in movements){
            ObjectMoveBase action = _get_action(movement);
            if (action == null) {
                Debug.Log("ObjectMovement: \"" + movement + "\" is not found");
            }
            else{
                _actions.Add(movement, action);
            }
        }
    }

    public void _prepare_to_move(KeyPos input){
        this.input = input;
    }

    public void move(){
        foreach (var action in _actions.Values){
            action._act(input);
        }
    }
}
