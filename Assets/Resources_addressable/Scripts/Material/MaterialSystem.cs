using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;


public class MaterialSystem: MonoBehaviour{
    GameConfigs GCfg { get { return HierSearch._GCfg; } }
    HierarchySearch HierSearch;
    public ObjectManager _obj;
    public UIPrefabManager _UIPfb;
    public UISpriteManager _UISpr;
    public TilemapManager _TMap;
    // ---------- Status ----------
    bool initDone = false;


    void Start(){
        HierSearch = GameObject.Find("System").GetComponent<HierarchySearch>();
        HierSearch._MatSys = this;
    }

    void Update(){
        init();
    }

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
