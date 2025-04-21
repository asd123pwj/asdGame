using System;
using System.Collections.Generic;
using UnityEngine;

public class InputCommandRegister : BaseClass{
    public static Dictionary<string, string> keyName2Command = new();
    public static Dictionary<List<string>, string> comboKey2Command = new();

    public override bool _check_allow_init(){
        return _GCfg._InputSys != null;
    }

    public override void _init(){
        init_key2Command();
        init_comboKey2Command();
        init_keyAction();
    }

    void init_comboKey2Command(){
        comboKey2Command.Add(new List<string>() {"w", "w" }, "rush --up");
        comboKey2Command.Add(new List<string>() {"d", "d" }, "rush --right");
        comboKey2Command.Add(new List<string>() {"a", "a" }, "rush --left");
        comboKey2Command.Add(new List<string>() {"left shift", "w" }, "rush --up");
        comboKey2Command.Add(new List<string>() {"left shift", "a" }, "rush --left");
        comboKey2Command.Add(new List<string>() {"left shift", "d" }, "rush --right");
    }

    void init_key2Command(){
        keyName2Command.Add("f1", "");
        keyName2Command.Add("f2", "");
        keyName2Command.Add("f3", "");
        keyName2Command.Add("f4", "");
        keyName2Command.Add("f5", "UISave");
        keyName2Command.Add("f6", "");
        keyName2Command.Add("f7", "");
        keyName2Command.Add("f8", "");
        keyName2Command.Add("f9", "UILoad");
        keyName2Command.Add("f10", "");
        keyName2Command.Add("f11", "");
        keyName2Command.Add("f12", "");

        keyName2Command.Add("Number 0", "");
        keyName2Command.Add("Number 1", "TMapGen --useMousePos");
        keyName2Command.Add("Number 2", "print_mouse_hover_time");
        keyName2Command.Add("Number 3", "");
        keyName2Command.Add("Number 4", "");
        keyName2Command.Add("Number 5", "");
        keyName2Command.Add("Number 6", "");
        keyName2Command.Add("Number 7", "");
        keyName2Command.Add("Number 8", "");
        keyName2Command.Add("Number 9", "");

        keyName2Command.Add("Numpad 0", "");
        keyName2Command.Add("Numpad 1", "");
        keyName2Command.Add("Numpad 2", "");
        keyName2Command.Add("Numpad 3", "");
        keyName2Command.Add("Numpad 4", "");
        keyName2Command.Add("Numpad 5", "");
        keyName2Command.Add("Numpad 6", "");
        keyName2Command.Add("Numpad 7", "");
        keyName2Command.Add("Numpad 8", "");
        keyName2Command.Add("Numpad 9", "");

        keyName2Command.Add("a", "move --left");
        keyName2Command.Add("b", "");
        keyName2Command.Add("c", "");
        keyName2Command.Add("d", "move --right");
        keyName2Command.Add("e", "");
        keyName2Command.Add("f", "");
        keyName2Command.Add("g", "");
        keyName2Command.Add("h", "");
        keyName2Command.Add("i", "");
        keyName2Command.Add("j", "");
        keyName2Command.Add("k", "");
        keyName2Command.Add("l", "");
        keyName2Command.Add("m", "");
        keyName2Command.Add("n", "");
        keyName2Command.Add("o", "UIToggle --type UIKeyboardShortcut");
        keyName2Command.Add("p", "");
        keyName2Command.Add("q", "");
        keyName2Command.Add("r", "");
        keyName2Command.Add("s", "move --down");
        keyName2Command.Add("t", "");
        keyName2Command.Add("u", "");
        keyName2Command.Add("v", "");
        keyName2Command.Add("w", "move --up");
        keyName2Command.Add("x", "UIToggle --type UIKeyboardShortcut");
        keyName2Command.Add("y", "");
        keyName2Command.Add("z", "spawn --useMousePos --type asd");

        keyName2Command.Add("`", "UIToggle --type UICommandWindow");
        keyName2Command.Add("-", "CamZoom --in");
        keyName2Command.Add("=", "CamZoom --out");
        keyName2Command.Add("backspace", "");
        keyName2Command.Add("[", "");
        keyName2Command.Add("]", "");
        keyName2Command.Add("\\", "");
        keyName2Command.Add(";", "");
        keyName2Command.Add("'", "");
        keyName2Command.Add("enter", "");
        keyName2Command.Add(",", "");
        keyName2Command.Add(".", "");
        keyName2Command.Add("/", "");
        keyName2Command.Add("space", "");
        keyName2Command.Add("Numpad /", "");
        keyName2Command.Add("Numpad *", "");
        keyName2Command.Add("Numpad -", "");
        keyName2Command.Add("Numpad +", "");

        keyName2Command.Add("left shift", "");
        keyName2Command.Add("right shift", "");
        keyName2Command.Add("left ctrl", "");
        keyName2Command.Add("right ctrl", "");
        keyName2Command.Add("left alt", "");
        keyName2Command.Add("right alt", "");

        keyName2Command.Add("escape", "");
        keyName2Command.Add("tab", "UIClose");
        keyName2Command.Add("caps lock", "");
        keyName2Command.Add("print screen", "");
        keyName2Command.Add("scroll lock", "");
        keyName2Command.Add("pause", "");
        keyName2Command.Add("insert", "");
        keyName2Command.Add("delete", "");
        keyName2Command.Add("home", "");
        keyName2Command.Add("end", "");
        keyName2Command.Add("page up", "");
        keyName2Command.Add("page down", "");
        // keyName2Command.Add("windows", "");
        keyName2Command.Add("menu", "");
        
        keyName2Command.Add("up", "");
        keyName2Command.Add("down", "");
        keyName2Command.Add("left", "");
        keyName2Command.Add("right", "");





    }
    void init_keyAction(){
        List<string> tmp_key_isDown = new(){
            "a", "d", "w", "s", "-", "=", "Number 1", "Number 2", "Number 3"
        };
        foreach(string keyName in keyName2Command.Keys){
            if(tmp_key_isDown.Contains(keyName)){
                _GCfg._InputSys._register_action(keyName, create_delegate(keyName), "isDown");
            }
            else{
                _GCfg._InputSys._register_action(keyName, create_delegate(keyName), "isFirstDown");
            }
        }
        foreach(List<string> comboKey in comboKey2Command.Keys){
            _GCfg._InputSys._register_action(comboKey, create_delegate(comboKey));
        }
    }

    public _input_action create_delegate(string key){
        return new _input_action((keyPos, keyStatus) => {
            _Msg._send2COMMAND(keyName2Command[key]);
            return true;
        });
    }
    
    public _input_action create_delegate(List<string> key){
        return new _input_action((keyPos, keyStatus) => {
            _Msg._send2COMMAND(comboKey2Command[key]);
            return true;
        });
    }
}
