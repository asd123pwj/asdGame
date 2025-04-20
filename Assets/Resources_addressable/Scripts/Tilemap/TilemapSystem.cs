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
    // public Tilemap _tilemap_modify;
    // ---------- sub script ----------
    // public TilemapBlockGenerator _TMapGen;
    public TilemapDraw _TMapDraw;
    public TilemapAxis _TMapAxis;
    public TilemapSaveLoad _TMapSL;
    public TilemapController _TMapCtrl;
    public TilemapMonitor _TMapMon;
    public PlantMonitor _PlantMon;
    public BuildGenerator _BuildGen;
    public TilemapBlockGameObjectGenerator _TMapObjGen;
    public TilemapZoneGenerator _TMapZoneGen;
    // public TileMonitor _P3DMon;
    public TilemapTerrainGenerator _TerrGen;
    public WaterGenerator _waterGen;
    public TilemapCommandHandler _handler;
    // ---------- status ----------

    public override void _init(){
        // _tilemap_modify = _sys._searchInit<Tilemap>("Tilemap", "Block_1x1");
        _TMapAxis = new();
        _TMapDraw = new();
        // _TMapGen = new();
        _TMapSL = new();
        _TMapCtrl = new();
        _TMapMon = new();
        _PlantMon = new();
        _BuildGen = new();
        _TMapObjGen = new();
        _TMapZoneGen = new();
        // _P3DMon = new();
        _TerrGen = new();
        _waterGen = new();
        _handler = new();
    }

    
}
