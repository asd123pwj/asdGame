using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;


public class MaterialSystem: BaseClass{
    // GameConfigs _GCfg { get { return _sys._GCfg; } }
    // SystemManager _sys;
    public ObjectManager _obj;
    public UIPrefabManager _UIPfb;
    public UISpriteManager _UISpr;
    public TilemapManager _TMap;
    // ---------- Status ----------
    // bool _initDone = false;


    // public MaterialSystem(SystemManager sys){
    //     // this._sys = sys;
    //     // sys = GameObject.Find("System").GetComponent<SystemManager>();
    //     // sys._MatSys = this;
    //     sys._UpdateSys._add_updater(init, 0);
    // }

    // void Update(){
    //     init();
    // }

    public override void _init(){
        // if (initDone) return;
        _obj = new();
        _UIPfb = new();
        _UISpr = new();
        _TMap = new();
        // initDone = true;
    }
    
    public bool _check_info_initDone(){
        if (!_initDone) return false;
        if (!_obj._check_info_initDone()) return false;
        if (!_UIPfb._check_info_initDone()) return false;
        if (!_UISpr._check_info_initDone()) return false;
        if (!_TMap._check_info_initDone()) return false;
        return true;
    }


}
