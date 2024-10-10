using System.Collections.Generic;
using System.Collections;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;
using System.Linq;
using System.Threading;
using Unity.Profiling;
using System;


public class Region4DrawTilemapBlock{
    public Vector3Int[] positions => pos_tile_kvp.Keys.ToArray();
    public TileBase[] tiles => pos_tile_kvp.Values.ToArray();

    public Dictionary<Vector3Int, TileBase> pos_tile_kvp = new();

    public void _add(Vector3Int pos, TileBase tile){
        pos_tile_kvp.Add(pos, tile);
    }
    
}

public class TilemapDraw: BaseClass{
    // ---------- Status ---------- // 
    List<Vector3Int> done_block_offsets = new();


    public async UniTask _draw_block(TilemapBlock block){
        if (done_block_offsets.Contains(block.offsets)) return;
        done_block_offsets.Add(block.offsets);
        // if (block.offsets.x == 2 && block.offsets.y == -9) {
        //     int a = 1;
        // }
        Tilemap TMap = _TMapSys._TMapMon._get_blkObj(block.offsets, block.layer).TMap;
        Region4DrawTilemapBlock region_block = _get_draw_region(block);
        await _draw_region(TMap, region_block);
        
        Dictionary<Vector3Int, Region4DrawTilemapBlock> regions_placeholder = _get_draw_regions_placeholder(block);

        foreach (var kvp in regions_placeholder){
            Tilemap TMap_placeholder = _TMapSys._TMapMon._get_blkObj(kvp.Key, block.layer).TMap;
            await _draw_region(TMap_placeholder, kvp.Value, isPlaceholder:true);
        }
        // return true;
    }
    


    public Region4DrawTilemapBlock _get_draw_region(TilemapBlock block){
        Vector3Int block_origin_pos = block.offsets * block.size;
        // Dictionary<Vector3Int, TileBase> pos_tile_kvp = new();
        Region4DrawTilemapBlock region = new();
        // List<TileBase> __tiles = new();
        // List<Vector3Int> __positions = new();
        for (int x = 0; x < block.size.x; x++){
            for (int y = 0; y < block.size.y; y++){
                if (block.map._get(x, y) == _GCfg._empty_tile) continue;
                TileBase tile = _MatSys._tile._get_tile(block.map._get(x, y));
                region._add(block_origin_pos + new Vector3Int(x, y, 0), tile);
            }
        }
        return region;


    }

    public Dictionary<Vector3Int, Region4DrawTilemapBlock> _get_draw_regions_placeholder(TilemapBlock block){
        // This function aims draw placeholder tiles around the block,
        Vector3Int block_origin_pos = block.offsets * block.size; 
        Vector3Int block_offset;
        Region4DrawTilemapBlock region;
        Dictionary<Vector3Int, Region4DrawTilemapBlock> regions = new();
        Vector3Int neighbor = _GCfg._sysCfg.TMap_tileNeighborsCheck_max;

        // ----- lower left quarter
        block_offset = block.offsets + new Vector3Int(-1, -1, 0);
        region = new();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map._get(x, y) == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, y, 0));
                region._add(block_origin_pos + new Vector3Int(x, y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        // ----- upper left quarter
        block_offset = block.offsets + new Vector3Int(-1, 1, 0);
        region = new();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map._get(x, block.size.y - 1 - y) == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, block.size.y - 1 - y, 0));
                region._add(block_origin_pos + new Vector3Int(x, block.size.y - 1 - y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        // ----- lower right quarter
        block_offset = block.offsets + new Vector3Int(1, -1, 0);
        region = new();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map._get(block.size.x - 1 - x, y) == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(block.size.x - 1 - x, y, 0));
                region._add(block_origin_pos + new Vector3Int(block.size.x - 1 - x, y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        // ----- upper right quarter
        block_offset = block.offsets + new Vector3Int(1, 1, 0);
        region = new();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map._get(block.size.x - 1 - x, block.size.y - 1 - y) == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(block.size.x - 1 - x, block.size.y - 1 - y, 0));
                region._add(block_origin_pos + new Vector3Int(block.size.x - 1 - x, block.size.y - 1 - y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        // ----- left side
        block_offset = block.offsets + new Vector3Int(-1, 0, 0);
        region = new();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < block.size.y; y++){
                if (block.map._get(x, y) == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, y, 0));
                region._add(block_origin_pos + new Vector3Int(x, y, 0), tile);
            }
        }
        regions.Add(block_offset, region);
        // ----- right side
        region = new();
        block_offset = block.offsets + new Vector3Int(1, 0, 0);
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < block.size.y; y++){
                if (block.map._get(block.size.x - 1 - x, y) == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(block.size.x - 1 - x, y, 0));
                region._add(block_origin_pos + new Vector3Int(block.size.x - 1 - x, y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        
        // ----- bottom side
        block_offset = block.offsets + new Vector3Int(0, -1, 0);
        region = new();
        for (int x = 0; x < block.size.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map._get(x, y) == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, y, 0));
                region._add(block_origin_pos + new Vector3Int(x, y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        // ----- top side
        block_offset = block.offsets + new Vector3Int(0, 1, 0);
        region = new();
        for (int x = 0; x < block.size.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map._get(x, block.size.y - 1 - y) == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, block.size.y - 1 - y, 0));
                region._add(block_origin_pos + new Vector3Int(x, block.size.y - 1 - y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        return regions;
    }

    TileBase get_placeholder_tile(TilemapBlock block, Vector3Int position){
        string tile_ID = block.map._get(position.x, position.y);
        TileBase tile = _MatSys._tile._get_tile(tile_ID);
        return tile;
    }


    public async UniTask _draw_region(Tilemap tilemap, Region4DrawTilemapBlock region, bool isPlaceholder=false){
        // System.Diagnostics.Stopwatch stopwatch = new System.Diagnostics.Stopwatch();
        // stopwatch.Start();


        Color transparent = new(1, 1, 1, 0);
        int tile_per_group = Mathf.Min(_GCfg._sysCfg.TMap_tiles_per_loading, region.tiles.Count());
        Vector3Int[] positions = region.positions;
        TileBase[] tiles = region.tiles;
        for (int i = 0; i < region.tiles.Count(); i += tile_per_group) {
            if (i + tile_per_group > region.tiles.Count()) 
                tile_per_group = region.tiles.Count() - i;
            Vector3Int[] positions_segment = new ArraySegment<Vector3Int>(positions, i, tile_per_group).ToArray();
            TileBase[] tiles_segment = new ArraySegment<TileBase>(tiles, i, tile_per_group).ToArray();
            
            // ----- Draw tile ----- //
            tilemap.SetTiles(positions_segment, tiles_segment);

            // ----- Set Placeholder ----- //
            if (isPlaceholder){
                foreach (var tile_pos in positions_segment){
                    tilemap.SetColor(tile_pos, transparent);
                }
            }

            await UniTask.Delay(_GCfg._sysCfg.TMap_interval_per_loading);
        }

        // stopwatch.Stop();
        // Debug.Log("Time loop: " + stopwatch.ElapsedMilliseconds);
    }






}
