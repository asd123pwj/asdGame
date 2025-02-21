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




public class VisualizationSystem : BaseClass{
    // ---------- System Tool ----------
    // SystemManager _HierSearch;
    // GameConfigs _GCfg { get { return _HierSearch._GCfg; } }
    // InputSystem _InputSys { get { return _HierSearch._InputSys; } }
    // ---------- UI Tool ----------
    public TilemapVisualization _tMapVis;


    public VisualizationSystem(){
    }

    public override void _init(){
        _tMapVis = new();
    }
    

    
}
