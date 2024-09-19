using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public class PlantMonitor: BaseClass{
    // ---------- Config ----------
    // ---------- unity ----------
    // Tilemap TMap { get => _TMapSys._tilemap_modify; }
    // ---------- status ----------
    // public Dictionary<int[,], TilemapBlock> _blocks;
    // ---------- Tilemap Container ----------
    public Dictionary<string, Transform> _TMapBD_containers;
    // public Dictionary<string, Dictionary<Vector3Int, TilemapBlockGameObject>> _TMap_obj;

    public PlantMonitor(){
    }

    public override void _init(){
        _TMapBD_containers = new();
        _TMapBD_containers.Add("BlockDecoration", new GameObject("BlockDecoration").transform);

        foreach(var obj in _TMapBD_containers.Values){
            obj.transform.SetParent(_sys._grid.transform);
        }

        _sys._InputSys._register_action("Number 1", tmp_draw, "isFirstDown");
    }

    public bool tmp_draw(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        new PlantBase(keyPos.mouse_pos_world, _TMapBD_containers["BlockDecoration"]);
        return true;
    }

    
}
