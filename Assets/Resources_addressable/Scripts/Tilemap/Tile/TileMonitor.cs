using System;
using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;





public class TileMonitor: BaseClass{
    // ---------- Plant Container ----------
    public Dictionary<string, Transform> _containers;
    public Dictionary<string, Dictionary<Vector3Int, TilemapTile>> _tiles;
    public Dictionary<string, Dictionary<Vector3Int, TileP3D>> _P3Ds;
    public Dictionary<string, Dictionary<Vector3Int, DecorationBase>> _decorations;
    // public Dictionary<Pseudo3DRuleTile, TileP3D> _P3Dsssss;
    public int update_num = 100;

    public TileMonitor(){
        // update_interval = 0.5f;
    }

    public override void _init(){
        _containers = new();
        _containers.Add("TileP3D", new GameObject("TileP3D").transform);
        _containers.Add("Decoration", new GameObject("Decoration").transform);
        foreach(var obj in _containers.Values){
            obj.transform.SetParent(_sys._grid.transform);
        }

        _P3Ds = new() { 
            {new LayerType(0).ToString(), new() },
            {new LayerType(1).ToString(), new() },
            {new LayerType(2).ToString(), new() },
            {new LayerType(3).ToString(), new() },
            {new LayerType(4).ToString(), new() },
            {new LayerType(5).ToString(), new() },
        };
        
        _decorations = new() { 
            {new LayerType(0).ToString(), new() },
            {new LayerType(1).ToString(), new() },
            {new LayerType(2).ToString(), new() },
            {new LayerType(3).ToString(), new() },
            {new LayerType(4).ToString(), new() },
            {new LayerType(5).ToString(), new() },
        };

        _sys._InputSys._register_action("Number 4", tmp_draw, "isFirstDown");
    }

    // public void _update_tile(Vector3Int map_pos, LayerType layer, string status){
    //     if (_tiles[layer.ToString()].ContainsKey(map_pos)){
    //         if
    //     }
    // }

    public void _update_P3D(Vector3Int map_pos, LayerType layer){
        if (_P3Ds[layer.ToString()].ContainsKey(map_pos)){
                _P3Ds[layer.ToString()][map_pos]._update_sprite().Forget();
        }
        else {
            TileP3D P3D = new TileP3D(map_pos, layer);
            _P3Ds[layer.ToString()].Add(map_pos, P3D);
        }
    }

    
    public void _update_decoration(Vector3Int map_pos, LayerType layer){
        if (_decorations[layer.ToString()].ContainsKey(map_pos)){
                _decorations[layer.ToString()][map_pos]._update_sprite().Forget();
        }
        else {
            DecorationBase decoration = new (map_pos, layer);
            _decorations[layer.ToString()].Add(map_pos, decoration);
        }
    }

    public bool tmp_draw(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        Vector3Int block_offsets = _TMapSys._TMapAxis._mapping_worldPos_to_blockOffsets(keyPos.mouse_pos_world, new LayerType());
        TilemapBlock block = _TMapSys._TMapMon._get_block(block_offsets, new LayerType());
        block.status._update_status_typeMap("TileP3D");
        Tilemap TMap = _TMapSys._TMapMon._get_blkObj(block_offsets, new LayerType()).TMap;
        foreach (var pos in block.status.positions["TileP3D"]){
            // Vector2 world_pos = _TMapSys._TMapAxis._mapping_inBlockPos_to_worldPos(pos, block_offsets, new LayerTTT());
            Vector3Int map_pos = _TMapSys._TMapAxis._mapping_inBlockPos_to_mapPos(pos, block_offsets);
            // string tile_subID = TMap.GetSprite(map_pos).name;
            // new TileP3D(world_pos, _TMapBD_containers["TileP3D"], block.map._get(pos), tile_subID);
            new TileP3D(map_pos, new LayerType());
        }
        return true;
    }

    
}
