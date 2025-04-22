using System.Collections.Generic;
using UnityEngine;

public struct KeyPos{
    public Vector2 mouse_pos_world;
    public Vector2 mouse_pos_screen;
    public Vector2 mouse_pos_world_change;
    public Vector2 mouse_pos_screen_change;
    public float x;
    public float y;
    public float mouse_hover_deltaTime;
    // public float x_dir;
    // public float y_dir;
}

public class MouseHoverTrigger{
    public float time;
    public bool isTrigger;
    public string messageID;
    public MouseHoverTrigger(float time, string messageID){
        this.time = time;
        this.isTrigger = false;
        this.messageID = messageID;
    }
}

public delegate bool _input_action(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus);

public class InputSystem : BaseClass{
    // ---------- Sub Script ----------
    InputSingle InputSingle;
    InputCombo InputCombo;
    InputStatus InputStatus;
    InputCommandRegister InputCmdReg;
    InputCommandHandler handler;
    // ---------- Status ----------
    public static KeyPos _keyPos = new();
    public static Dictionary<string, KeyInfo> _keyStatus => InputStatus._keyStatus;
    public static bool _onEdit = false;
    List<MouseHoverTrigger> _mouse_hover_trigger = new(){
        new(0.5f, "MOUSE_HOVER_0.5")
    };  
    // public Dictionary<string, KeyInfo> _keyStatus = new();

    public override void _update(){
        update_keyPos();
        InputStatus._update();
        InputSingle._update(_keyPos, InputStatus._keyStatus);
        InputCombo._update(_keyPos, InputStatus._keyStatus);

    }


    public override void _init(){
        priority = 0;
        InputSingle = new();
        InputCombo = new();
        InputStatus = new();
        InputCmdReg = new();
        handler = new();
        // _InputUI = new();
    }

    void update_keyPos(){
        _keyPos.mouse_pos_world_change = get_mouse_pos_2d() - _keyPos.mouse_pos_world;
        _keyPos.mouse_pos_screen_change = get_mouse_pos_2d(0) - _keyPos.mouse_pos_screen;
        _keyPos.mouse_pos_world = get_mouse_pos_2d();
        _keyPos.mouse_pos_screen = get_mouse_pos_2d(0);
        _keyPos.x = 0;
        _keyPos.y = 0;
        update_mouse_hover_time();
    }

    public void _register_action(string input_type, _input_action action, string trigger="isDown", bool isReplaceTrigger=false){ 
        InputSingle._register_action(input_type, action, trigger, isReplaceTrigger); 
    }
    public void _register_action(List<string> input_type, _input_action action){ 
        InputCombo._register_action(input_type, action); 
    }

    public Vector3 get_mouse_pos(int type=1){
        switch (type){
            case 0: 
                return Input.mousePosition;
            case 1:
                Vector3 pos_camera = get_mouse_pos(0);
                pos_camera.z = Camera.main.WorldToScreenPoint(_sys.transform.position).z;
                return Camera.main.ScreenToWorldPoint(pos_camera);
            default:
                Debug.Log("Error type.");
                return new Vector3();
        }
    }

    public Vector2 get_mouse_pos_2d(int type=1) {
        Vector3 pos_3d = get_mouse_pos(type);
        return new(pos_3d.x, pos_3d.y);
    }

    public void update_mouse_hover_time(){
        if (_keyPos.mouse_pos_world_change == Vector2.zero){
            _keyPos.mouse_hover_deltaTime += Time.deltaTime;
            foreach (MouseHoverTrigger trigger in _mouse_hover_trigger){
                if (_keyPos.mouse_hover_deltaTime >= trigger.time && !trigger.isTrigger){
                    trigger.isTrigger = true;
                    _sys._Msg._send(trigger.messageID, null);
                }
            }
        }
        else{
            _keyPos.mouse_hover_deltaTime = 0;
            foreach (MouseHoverTrigger trigger in _mouse_hover_trigger){
                trigger.isTrigger = false;
            }
        }
    }
}
