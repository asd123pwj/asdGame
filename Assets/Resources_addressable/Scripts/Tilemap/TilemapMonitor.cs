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



public class TilemapMonitor: BaseClass{
    // ---------- system tool ----------
    // HierarchySearch _HierSearch;
    // ControlSystem _CtrlSys { get => _GCfg._CtrlSys; }
    // InputSystem _input_base;
    // GameConfigs _GCfg;
    // TilemapSystem _TMapSys { get => _GCfg._TMapSys; }
    // ---------- unity ----------
    Tilemap TMap { get => _TMapSys._tilemap_modify; }
    // ---------- status ----------
    public Dictionary<int[,], TilemapBlock> _blocks;

    // Start is called before the first frame update
    public TilemapMonitor(){
        // _GCfg = game_configs;
    }


    
}
