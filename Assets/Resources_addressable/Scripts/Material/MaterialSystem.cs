using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;


public class MaterialSystem{
    GameConfigs GCfg { get { return sys._GCfg; } }
    SystemManager sys;
    public ObjectManager _obj;
    public UIPrefabManager _UIPfb;
    public UISpriteManager _UISpr;
    public TilemapManager _TMap;
    // ---------- Status ----------
    bool initDone = false;


    public MaterialSystem(SystemManager sys){
        this.sys = sys;
        // sys = GameObject.Find("System").GetComponent<SystemManager>();
        // sys._MatSys = this;
        sys._UpdateSys._add_updater(init, 0);
    }

    // void Update(){
    //     init();
    // }

    void init(){
        if (initDone) return;
        _obj = new(GCfg);
        _UIPfb = new(GCfg);
        _UISpr = new(GCfg);
        _TMap = new(GCfg);
        initDone = true;
    }
    
    public bool _check_info_initDone(){
        if (!initDone) return false;
        if (!_obj._check_info_initDone()) return false;
        if (!_UIPfb._check_info_initDone()) return false;
        if (!_UISpr._check_info_initDone()) return false;
        if (!_TMap._check_info_initDone()) return false;
        return true;
    }


}
