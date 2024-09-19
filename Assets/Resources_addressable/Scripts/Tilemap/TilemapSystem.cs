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



public class TilemapSystem : BaseClass{
    // ---------- system tool ----------
    // SystemManager sys;
    // ControlSystem _CtrlSys { get => sys._CtrlSys; }
    // InputSystem _input_base;
    // GameConfigs _GCfg { get => sys._GCfg; }
    // ---------- unity ----------
    public Tilemap _tilemap_modify;
    // ---------- sub script ----------
    public TilemapBlockGenerate _TMapGen;
    public TilemapDraw _TMapDraw;
    public TilemapConfig _TMapCfg;
    public TilemapSaveLoad _TMapSL;
    public TilemapController _TMapCtrl;
    public TilemapMonitor _TMapMon;
    public PlantMonitor _PlantMon;
    // ---------- status ----------

    public override void _init(){
        _tilemap_modify = _sys._searchInit<Tilemap>("Tilemap", "Block_1x1");
        _TMapCfg = new();
        _TMapDraw = new();
        _TMapGen = new();
        _TMapSL = new();
        _TMapCtrl = new();
        _TMapMon = new();
        _PlantMon = new();
    }

    
}
