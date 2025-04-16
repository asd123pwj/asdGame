using System;
using System.Collections.Generic;
using UnityEngine;

public class InputCommandRegister : BaseClass{
    public static Dictionary<string, string> keyName2Command = new();

    public override bool _check_allow_init(){
        return _GCfg._InputSys != null;
    }

    public override void _init(){
        init_key2Command();
        init_keyAction();
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
        keyName2Command.Add("Number 1", "");
        keyName2Command.Add("Number 2", "");
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

        keyName2Command.Add("a", "");
        keyName2Command.Add("b", "");
        keyName2Command.Add("c", "");
        keyName2Command.Add("d", "");
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
        keyName2Command.Add("s", "");
        keyName2Command.Add("t", "");
        keyName2Command.Add("u", "");
        keyName2Command.Add("v", "");
        keyName2Command.Add("w", "");
        keyName2Command.Add("x", "UIToggle --type UIKeyboardShortcut");
        keyName2Command.Add("y", "");
        keyName2Command.Add("z", "spawn --useMousePos --type asd");

        keyName2Command.Add("`", "UIToggle --type UICommandWindow");
        keyName2Command.Add("-", "");
        keyName2Command.Add("=", "");
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
        keyName2Command.Add("tab", "");
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





    }
    void init_keyAction(){
        foreach(string keyName in keyName2Command.Keys){
            _GCfg._InputSys._register_action(keyName, create_delegate(keyName), "isFirstDown");
        }
    }

    public _input_action create_delegate(string key){
        return new _input_action((keyPos, keyStatus) => {
            _Msg._send(GameConfigs._sysCfg.Msg_command, keyName2Command[key]);
            return true;
        });
    }
}
