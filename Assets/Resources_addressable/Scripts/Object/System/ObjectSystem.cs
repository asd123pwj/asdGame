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



public class ObjectSystem : MonoBehaviour{
    // ---------- system tool ----------
    SystemManager _HierSearch;
    // InputSystem _input_base;
    GameConfigs _GCfg { get { return _HierSearch._GCfg; } }
    // ----------
    // public ObjectList _object_list;
    // ---------- Spawn
    public ObjectSpawn _object_spawn;
    // ---------- Status ----------
    bool isInit = true;



    // Start is called before the first frame update
    void Start(){
        _HierSearch = GameObject.Find("System").GetComponent<SystemManager>();
        // _GCfg = _HierSearch._searchInit<GameConfigs>("System");
        _HierSearch._ObjSys = this;
        // _input_base = _hierarchy_search._searchInit<InputSystem>("Input");

    }

    // Update is called once per frame
    void Update(){
        init();

    }

    void init(){
        if (!isInit) return;
        isInit = false;
        // _object_list = new(_GCfg);
        _object_spawn = new(_GCfg);
    }
    
    public void _down_fire3(Vector2 mouse_pos){
        _object_spawn._instantiate("yang", mouse_pos);
    }

    public void _down_fire2(Vector2 mouse_pos){
        _object_spawn._instantiate("test ammo", mouse_pos);
    }


    
}
