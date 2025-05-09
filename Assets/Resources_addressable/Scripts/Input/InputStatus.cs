using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;

public struct KeyInfo{
    public bool isDown;
    public bool isUp;
    public bool isFirstDown;
    public bool isFirstUp;
}

public class InputStatus{
    // ---------- Status ----------
    public static Dictionary<string, KeyInfo> _keyStatus = new();
    // ---------- Config ----------
    List<string> _input_key = new() { 
        "Fire1", "Fire2", "Fire3", "Jump", "Shift",
        "Up", "Down", "Left", "Right", "Horizontal", "Vertical",
        "Save", "Load",
        "Menu 1", "Menu 2", "Menu 3", "Menu 4", "Menu Wheel",
        "Zoom In", "Zoom Out",
        "Number 0", "Number 1", "Number 2", "Number 3", "Number 4", "Number 5", "Number 6", "Number 7", "Number 8", "Number 9",
        "Numpad 0", "Numpad 1", "Numpad 2", "Numpad 3", "Numpad 4", "Numpad 5", "Numpad 6", "Numpad 7", "Numpad 8", "Numpad 9",
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "`", "-", "=", "backspace", "[", "]", "\\", ";", "'", "enter", ",", ".", "/", "space",
        "Numpad /", "Numpad *", "Numpad -", "Numpad +", 
        "left shift", "right shift", "left ctrl", "right ctrl", "left alt", "right alt",
        "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
        "escape", "tab", "caps lock", "print screen", "scroll lock", "pause", "insert", "delete", "home", "end", "page up", "page down", "menu",
        "up", "down", "left", "right",
    };
    
    public static List<string> _input_key_availableOnEdit = new() { 
        "Save", "Load",
        "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
        "escape"
    };

    public InputStatus(){
        init_keyStatus();
    }

    public void _update(){
        update_keyStatus();
    }

    void init_keyStatus(){
        _keyStatus.Clear();
        foreach (string key in _input_key) _keyStatus.Add(key, new());
    }

    void set_keyStatus(string key, bool isDown){
        var keyStatus = _keyStatus[key];
        if (isDown){
            keyStatus.isFirstDown = !keyStatus.isDown;
            keyStatus.isFirstUp = false;
            keyStatus.isDown = true;
            keyStatus.isUp = false;
        }
        else{
            keyStatus.isFirstDown = false;
            keyStatus.isFirstUp = !keyStatus.isUp;
            keyStatus.isDown = false;
            keyStatus.isUp = true;
        }
        _keyStatus[key] = keyStatus;
    }

    void update_keyStatus(){
        foreach (string key in _input_key){
            if (key == "Up") set_keyStatus(key, Input.GetAxisRaw("Vertical") > 0); 
            else if (key == "Down") set_keyStatus(key, Input.GetAxisRaw("Vertical") < 0); 
            else if (key == "Left") set_keyStatus(key, Input.GetAxisRaw("Horizontal") < 0); 
            else if (key == "Right") set_keyStatus(key, Input.GetAxisRaw("Horizontal") > 0); 
            else set_keyStatus(key, Input.GetButton(key));
        }
    }
}
