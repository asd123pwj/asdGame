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




public class UISystem : MonoBehaviour{
    // ---------- System Tool ----------
    SystemManager _HierSearch;
    GameConfigs _GCfg { get { return _HierSearch._GCfg; } }
    // InputSystem _InputSys { get { return _HierSearch._InputSys; } }
    // ---------- UI Tool ----------
    // public UISpriteList _UISpriteList;
    // public UIPrefabList _UIPrefabList;
    public UIDraw _UIDraw;
    public UIMonitor _UIMonitor;
    public UIControl _UICtrl;
    public UISaveLoad _UISL;
    // ---------- Status ----------
    bool isInit = true;
    public GameObject _foreground;
    public GameObject _background;
    // ObjectSpawn _object_spawn;


    void Start(){
        _HierSearch = GameObject.Find("System").GetComponent<SystemManager>();
        _HierSearch._UISys = this;
        // _GCfg = _HierSearch._searchInit<GameConfigs>("System");
        // _input_base = _HierSearch._searchInit<InputSystem>("Input");
        _foreground = gameObject;
        // _object_spawn = new(_game_configs, _object_list);
    }

    void Update(){
        init();
    }

    void init(){
        if (!isInit) return;
        isInit = false;
        // _UISpriteList = new(_GCfg);
        // _UIPrefabList = new(_GCfg);
        _UIDraw = new(_GCfg);
        _UIMonitor = new(_GCfg);
        _UICtrl = new(_GCfg);
        _UISL = new(_GCfg);
        
    }
    

    
}
