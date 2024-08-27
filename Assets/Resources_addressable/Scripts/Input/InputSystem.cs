using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;

public struct KeyPos{
    public Vector2 mouse_pos_world;
    public Vector2 mouse_pos_screen;
    public Vector2 mouse_pos_world_change;
    public Vector2 mouse_pos_screen_change;
    public float x;
    public float y;
    public float x_dir;
    public float y_dir;
}

public delegate bool _input_action(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus);

public class InputSystem : BaseClass{
    // ---------- System Tool ----------
    // SystemManager _sys;
    // ControlSystem _CtrlSys { get { return _sys._CtrlSys; } }
    // GameConfigs _GCfg { get { return _sys._GCfg; } }
    // ---------- Sub Script ----------
    InputSingle _InputSingle;
    InputCombo _InputCombo;
    // InputUI _InputUI;
    InputStatus _InputStatus;
    // ---------- Status ----------
    public KeyPos _keyPos = new();
    public Dictionary<string, KeyInfo> _keyStatus = new();

    // void Start(){
    //     _sys = GameObject.Find("System").GetComponent<SystemManager>();
    //     // _GCfg = _HierSearch._searchInit<GameConfigs>("System");
    //     _sys._InputSys = this;
    //     // _CtrlSys = _hierarchy_search._searchInit<ControlSystem>("System");

    // }

    public override void _update(){
        update_keyPos();
        _InputStatus._update();
        _InputSingle._update(_keyPos, _InputStatus._keyStatus);
        _InputCombo._update(_keyPos, _InputStatus._keyStatus);
        // _InputUI._update(_keyPos, _InputStatus._keyStatus);

        // if (_InputStatus._keyStatus["Fire1"].isFirstDown){
        //     Debug.Log("AAAAAAAAAAAA - " + Input.GetButtonDown("Fire1"));
        // }
        

        // if (_InputStatus._keyStatus["Fire2"].isFirstDown){
        //     _sys._ObjSys._down_fire2(_keyPos.mouse_pos_world);
        //     // _sys._searchInit<ObjectSystem>("Object")._down_fire2(_keyPos.mouse_pos_world);
        // }
        
        if (_InputStatus._keyStatus["Fire3"].isFirstDown){
            _sys._ObjSys._down_fire3(_keyPos.mouse_pos_world);
            // _sys._searchInit<ObjectSystem>("Object")._down_fire3(_keyPos.mouse_pos_world);
        }
    }

    // void FixedUpdate(){
    // }

    public override void _init(){
        _InputSingle = new();
        _InputCombo = new();
        _InputStatus = new();
        // _InputUI = new();
    }

    void update_keyPos(){
        _keyPos.mouse_pos_world_change = get_mouse_pos_2d() - _keyPos.mouse_pos_world;
        _keyPos.mouse_pos_screen_change = get_mouse_pos_2d(0) - _keyPos.mouse_pos_screen;
        _keyPos.mouse_pos_world = get_mouse_pos_2d();
        _keyPos.mouse_pos_screen = get_mouse_pos_2d(0);
        _keyPos.x = Input.GetAxis("Horizontal");
        _keyPos.y = Input.GetAxis("Vertical");
        _keyPos.x_dir = Input.GetAxisRaw("Horizontal");
        _keyPos.y_dir = Input.GetAxisRaw("Vertical");
    }

    public void _register_action(string input_type, _input_action action, string trigger="isDown"){ 
        _InputSingle._register_action(input_type, action, trigger); 
    }
    public void _register_action(List<string> input_type, _input_action action){ 
        _InputCombo._register_action(input_type, action); 
    }
    // public void _register_UI(string input_type, _input_action action, bool isNew=false){ _InputUI._register_UI(input_type, action, isNew); }


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

    
}
