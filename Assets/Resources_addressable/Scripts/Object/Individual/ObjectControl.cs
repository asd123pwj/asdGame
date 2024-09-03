using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;

public class ObjectControl{
    // ---------- Action ----------
    // ---------- Config ----------
    ObjectConfig _Cfg;
    // ---------- Status ----------


    public ObjectControl(ObjectConfig config){
        _Cfg = config;
        if (_Cfg._tags.identity.Contains("player")) register_input_action();
    }

    void register_input_action(){
        // ----- single skill
        _Cfg._InputSys._register_action("Horizontal", _horizontal);
        _Cfg._InputSys._register_action("Vertical", _vertical);
        _Cfg._InputSys._register_action("Shift", _shift);
        // ----- combo skill
        _Cfg._InputSys._register_action(new List<string>() {"Right", "Right"}, _right_right);
        _Cfg._InputSys._register_action(new List<string>() {"Left", "Left"}, _left_left);
        _Cfg._InputSys._register_action(new List<string>() {"Up", "Up"}, _up_up);
    }

    public bool _horizontal(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        if (_Cfg._Move._walk(keyPos)) return true;
        // if (_Cfg._Move._fly(keyPos)) return true;
        return false;
    }

    public bool _vertical(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        if (_Cfg._Move._jump(keyPos)) return true;
        if (_Cfg._Move._jump_wall(keyPos)) return true;
        // if (_Cfg._Move._fly(keyPos)) return true;
        return false;
    }

    public bool _shift(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        if (_Cfg._Move._rush(keyPos)) return true;
        return false;
    }

    public bool _right_right(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        if (_Cfg._Move._rush(keyPos)) return true;
        return false;
    }
    public bool _left_left(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        if (_Cfg._Move._rush(keyPos)) return true;
        return false;
    }
    public bool _up_up(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        if (_Cfg._Move._rush(keyPos)) return true;
        return false;
    }
    
}
