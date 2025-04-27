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




public class UISystem : BaseClass{
    // ---------- System Tool ----------
    // SystemManager _HierSearch;
    // GameConfigs _GCfg { get { return _HierSearch._GCfg; } }
    // InputSystem _InputSys { get { return _HierSearch._InputSys; } }
    // ---------- UI Tool ----------
    // public UISpriteList _UISpriteList;
    // public UIPrefabList _UIPrefabList;
    public UIDraw _UIDraw;
    public UIMonitor _UIMonitor;
    public UIControl _UICtrl;
    public UISaveLoad _UISL;
    UIClass _UICls;
    UICommandHandler _handler;
    // ---------- Status ----------
    public GameObject _foreground;
    public GameObject _background;
    // ObjectSpawn _object_spawn;


    public UISystem(){
        // _HierSearch = GameObject.Find("System").GetComponent<SystemManager>();
        // _HierSearch._UISys = this;
        // _GCfg = _HierSearch._searchInit<GameConfigs>("System");
        // _input_base = _HierSearch._searchInit<InputSystem>("Input");
        _foreground = _sys._UI;
        // _object_spawn = new(_game_configs, _object_list);
    }

    // void Update(){
    //     init();
    // }

    public override void _init(){
        _UIDraw = new();
        _UIMonitor = new();
        _UICtrl = new();
        _UISL = new();
        _UICls = new();
        _handler = new();
        _Msg._add_receiver("MOUSE_HOVER_0.5", open_floatPanel);
    }

    public async UniTask open_floatPanel(DynamicValue _, CancellationToken? ct){
        _Msg._send2COMMAND("UIToggle --useMousePos --type UIFloatPanel --open").Forget();
    }
    

    
}
