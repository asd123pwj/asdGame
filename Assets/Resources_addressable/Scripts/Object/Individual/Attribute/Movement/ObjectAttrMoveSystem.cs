using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;
using Unity.VisualScripting;


public class ObjectAttrMoveSystem{
    // ---------- Config ----------
    public ObjectBase _Config;
    // ---------- Init ----------
    public string _name;

    // ---------- Action ----------
    public ObjectAttrMoveSystem(ObjectBase config){
        _Config = config;
    }

}
