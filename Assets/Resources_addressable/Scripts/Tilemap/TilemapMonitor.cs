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
using System;



public class TilemapMonitor{
    // ---------- system tool ----------
    // HierarchySearch _HierSearch;
    ControlSystem _CtrlSys { get => _GCfg._CtrlSys; }
    // InputSystem _input_base;
    GameConfigs _GCfg;
    TilemapSystem TMapSys { get => _GCfg._TMapSys; }
    // ---------- unity ----------
    Tilemap TMap { get => TMapSys._tilemap_modify; }
    // ---------- status ----------
    public Dictionary<int[,], TilemapBlock> _blocks;

    // Start is called before the first frame update
    public TilemapMonitor(GameConfigs game_configs){
        _GCfg = game_configs;
    }

    // Update is called once per frame
    public void _update(){
        if (TMapSys._isInit) return;
        // if (_isInit){
        // StartCoroutine(query_trigger(0.1f));
        // _generate_spawn_block(new(0, 0));
        // query_trigger(0.1f).Forget();
        // _isInit = false;
        // }
        
    }

    
}
