using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;
using System.Linq;
using Unity.Jobs;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using System.Threading;



public class ObjectSystem: BaseClass{
    // ---------- system tool ----------
    // SystemManager _sys;
    // InputSystem _input_base;
    // GameConfigs _GCfg { get { return _HierSearch._GCfg; } }
    // ----------
    // public ObjectList _object_list;
    // ---------- SubScript ---------- //
    public ObjectCommandHandler _handler;
    public ObjectSpawn _object_spawn;
    public ObjectMonitor _mon;
    // ---------- Status ---------- //
    public Dictionary<GameObject, ObjectBase> _obj2base = new();
    public Dictionary<int, ObjectBase> _runtimeID2base = new();
    // public ObjectConfig player;


    public override void _init(){
        _object_spawn = new(_GCfg);
        _handler = new();
        _mon = new();
    }
    
    public override void _update(){
        foreach (int runtimeID in _runtimeID2base.Keys){
            _runtimeID2base[runtimeID]._onUpdate();
        }
    }

    // public void _down_fire3(Vector2 mouse_pos){
    //     _object_spawn._instantiate("asd", mouse_pos);
    // }

    // public void _down_fire2(Vector2 mouse_pos){
    //     _object_spawn._instantiate("test ammo", mouse_pos);
    // }


    
}
