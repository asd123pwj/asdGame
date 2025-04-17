using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;


class SingleAction{
    // ---------- Config ----------
    public string _single_key;
    public string _trigger;
    public _input_action _action;

    public SingleAction(string single_key, _input_action action, string trigger){
        _single_key = single_key;
        _trigger = trigger;
        _action = action;
    }

    public bool _act(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        if (InputSystem._onEdit && !InputStatus._input_key_availableOnEdit.Contains(_single_key)) return false;
        if (check_key(keyStatus)) return _action(keyPos, keyStatus);
        else return false;
    }

    bool check_key(Dictionary<string, KeyInfo> keyStatus){
        if (   ((_trigger == "isDown") && keyStatus[_single_key].isDown)
            || ((_trigger == "isUp") && keyStatus[_single_key].isUp)
            || ((_trigger == "isFirstDown") && keyStatus[_single_key].isFirstDown)
            || ((_trigger == "isFirstUp") && keyStatus[_single_key].isFirstUp))
            return true;
        else return false;
    }
}


public class InputSingle{
    // ---------- actions ----------
    Dictionary<string, SingleAction> singleActions = new();
    
    public InputSingle(){}

    public void _update(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        foreach (var action in singleActions.Values){
            action._act(keyPos, keyStatus);
        }
    }

    public void _register_action(string keyName, _input_action action, string trigger, bool isReplaceTrigger = false){
        if (!singleActions.ContainsKey(keyName)) 
            singleActions.Add(keyName, new(keyName, action, trigger));
        else {
            if (isReplaceTrigger) 
                singleActions[keyName]._trigger = trigger;
            else 
                singleActions[keyName] = new(keyName, action, trigger);
        }
    }
}
