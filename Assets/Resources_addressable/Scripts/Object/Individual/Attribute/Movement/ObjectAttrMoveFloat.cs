using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;
using Unity.VisualScripting;
using TMPro;

public enum FloatStatus{
    ground,   // 在地面
    under_water,  // 跳跃
    space    // 飞行
}

public class ObjectAttrMoveFloat{
    // ---------- Config ----------
    public ObjectBase _Config;
    // ---------- Init ----------
    public string _name;
    float _gravity = 1;
    public FloatStatus _status;
    public bool _floating = true;

    // ---------- Action ----------
    public ObjectAttrMoveFloat(ObjectBase config){
        _Config = config;
    }

    public void _onUpdate(){
    }

    public void _act_float(bool status){
        _floating = status;
        _Config._rb.gravityScale = _floating ? 0 : _gravity;
    }
}
