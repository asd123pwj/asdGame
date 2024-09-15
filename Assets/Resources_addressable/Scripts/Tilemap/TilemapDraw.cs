using System.Collections.Generic;
using System.Collections;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;
using System.Linq;
using System.Threading;
using Unity.Profiling;
using System;


public struct TilemapRegion4Draw{
    public Vector3Int[] positions;
    public TileBase[] tiles;
}


public class TilemapDraw: BaseClass{
    // public TilemapConfig _tilemap_base;
    // GameConfigs _GCfg;

    // public TilemapDraw(TilemapConfig tilemap_base, GameConfigs game_configs){
    //     // _tilemap_base = tilemap_base;
    //     _GCfg = game_configs;
    // }


    public async UniTaskVoid _draw_block(Tilemap tilemap, TilemapBlock block){
        int group = 1;        
        // System.Diagnostics.Stopwatch stopwatch = new System.Diagnostics.Stopwatch();
        // stopwatch.Start();
        TileBase[] tiles = new TileBase[block.size.x * block.size.y / group];
        for (int g = 0; g < group; g++){
            Vector3Int block_origin_pos = new Vector3Int(block.offsets.x * block.size.x + g * block.size.x / group, block.offsets.y * block.size.y);
            for (int x = 0; x < block.size.x / group; x++){
                for (int y = 0; y < block.size.y; y++){
                    string tile_ID = block.map[x + g * block.size.x / group, y];
                    TileBase tile = _GCfg._MatSys._tile._get_tile(tile_ID);
                    tiles[x + y * block.size.x / group] = tile;
                }
            }
            BoundsInt block_bounds = new (block_origin_pos, new (block.size.x/group, block.size.y, 1));
            tilemap.SetTilesBlock(block_bounds, tiles);
        }
        // stopwatch.Stop();
        // Debug.Log("Time: " + stopwatch.ElapsedMilliseconds);
        await UniTask.Yield();
    }



    public TilemapRegion4Draw _get_draw_region(TilemapBlock block){
        Vector3Int block_origin_pos = block.offsets * block.size; 
        List<TileBase> __tiles = new();
        List<Vector3Int> __positions = new();
        for (int x = 0; x < block.size.x; x++){
            for (int y = 0; y < block.size.y; y++){
                if (block.map[x, y] == _GCfg._empty_tile) continue;
                TileBase tile = _MatSys._tile._get_tile(block.map[x, y]);
                __tiles.Add(tile);
                __positions.Add(block_origin_pos + new Vector3Int(x, y, 0));
            }
        }
        TilemapRegion4Draw region = new(){ tiles = __tiles.ToArray(), positions = __positions.ToArray() };
        return region;



        // TilemapRegion4Draw region = new TilemapRegion4Draw(){
        //     tiles = new TileBase[block.size.x * block.size.y],
        //     positions = new Vector3Int[block.size.x * block.size.y]
        // };
        // Vector3Int block_origin_pos = block.offsets * block.size; 
        // // Vector3Int block_origin_pos = new Vector3Int(block.offsets.x * block.size.x, block.offsets.y * block.size.y, block.offsets.z);
        // for (int x = 0; x < block.size.x ; x++){
        //     for (int y = 0; y < block.size.y; y++){
        //         string tile_ID = block.map[x, y];
        //         TileBase tile = _MatSys._tile._get_tile(tile_ID);
        //         region.tiles[x + y * block.size.x] = tile;
        //         region.positions[x + y * block.size.x] = new Vector3Int(block_origin_pos.x + x, block_origin_pos.y + y, 0);
        //     }
        // }
        // return region;
    }

    public Dictionary<Vector3Int, TilemapRegion4Draw> _get_draw_regions_placeholder(TilemapBlock block){
        // This function aims draw placeholder tiles around the block,
        Vector3Int block_origin_pos = block.offsets * block.size; 
        Vector3Int block_offset;
        TilemapRegion4Draw region;
        Dictionary<Vector3Int, TilemapRegion4Draw> regions = new();
        List<TileBase> __tiles = new();
        List<Vector3Int> __positions = new();

        Vector3Int neighbor = _GCfg._sysCfg.TMap_tileNeighborsCheck_max;
        // ----- lower left quarter

        block_offset = block.offsets + new Vector3Int(-1, -1, 0);
        __tiles.Clear();
        __positions.Clear();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map[x, y] == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, y, 0));
                __tiles.Add(tile);
                __positions.Add(block_origin_pos + new Vector3Int(x, y, 0));
            }
        }
        region = new(){ tiles = __tiles.ToArray(), positions = __positions.ToArray() };
        regions.Add(block_offset, region);

        // ----- upper left quarter
        block_offset = block.offsets + new Vector3Int(-1, 1, 0);
        __tiles.Clear();
        __positions.Clear();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map[x, block.size.y - 1 - y] == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, block.size.y - 1 - y, 0));
                __tiles.Add(tile);
                __positions.Add(block_origin_pos + new Vector3Int(x, block.size.y - 1 - y, 0));
            }
        }
        region = new(){ tiles = __tiles.ToArray(), positions = __positions.ToArray() };
        regions.Add(block_offset, region);

        // ----- lower right quarter
        block_offset = block.offsets + new Vector3Int(1, -1, 0);
        __tiles.Clear();
        __positions.Clear();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map[block.size.x - 1 - x, y] == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(block.size.x - 1 - x, y, 0));
                __tiles.Add(tile);
                __positions.Add(block_origin_pos + new Vector3Int(block.size.x - 1 - x, y, 0));
            }
        }
        region = new(){ tiles = __tiles.ToArray(), positions = __positions.ToArray() };
        regions.Add(block_offset, region);

        // ----- upper right quarter
        block_offset = block.offsets + new Vector3Int(1, 1, 0);
        __tiles.Clear();
        __positions.Clear();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map[block.size.x - 1 - x, block.size.y - 1 - y] == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(block.size.x - 1 - x, block.size.y - 1 - y, 0));
                __tiles.Add(tile);
                __positions.Add(block_origin_pos + new Vector3Int(block.size.x - 1 - x, block.size.y - 1 - y, 0));
            }
        }
        region = new(){ tiles = __tiles.ToArray(), positions = __positions.ToArray() };
        regions.Add(block_offset, region);

        // ----- left side
        block_offset = block.offsets + new Vector3Int(-1, 0, 0);
        __tiles.Clear();
        __positions.Clear();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < block.size.y; y++){
                if (block.map[x, y] == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, y, 0));
                __tiles.Add(tile);
                __positions.Add(block_origin_pos + new Vector3Int(x, y, 0));
            }
        }
        region = new(){ tiles = __tiles.ToArray(), positions = __positions.ToArray() };
        regions.Add(block_offset, region);
        // ----- right side
        __tiles.Clear();
        __positions.Clear();
        block_offset = block.offsets + new Vector3Int(1, 0, 0);
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < block.size.y; y++){
                if (block.map[block.size.x - 1 - x, y] == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(block.size.x - 1 - x, y, 0));
                __tiles.Add(tile);
                __positions.Add(block_origin_pos + new Vector3Int(block.size.x - 1 - x, y, 0));
            }
        }
        region = new(){ tiles = __tiles.ToArray(), positions = __positions.ToArray() };
        regions.Add(block_offset, region);

        
        // ----- bottom side
        block_offset = block.offsets + new Vector3Int(0, -1, 0);
        __tiles.Clear();
        __positions.Clear();
        for (int x = 0; x < block.size.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map[x, y] == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, y, 0));
                __tiles.Add(tile);
                __positions.Add(block_origin_pos + new Vector3Int(x, y, 0));
            }
        }
        region = new(){ tiles = __tiles.ToArray(), positions = __positions.ToArray() };
        regions.Add(block_offset, region);

        // ----- top side
        block_offset = block.offsets + new Vector3Int(0, 1, 0);
        __tiles.Clear();
        __positions.Clear();
        for (int x = 0; x < block.size.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map[x, block.size.y - 1 - y] == _GCfg._empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, block.size.y - 1 - y, 0));
                __tiles.Add(tile);
                __positions.Add(block_origin_pos + new Vector3Int(x, block.size.y - 1 - y, 0));
            }
        }
        region = new(){ tiles = __tiles.ToArray(), positions = __positions.ToArray() };
        regions.Add(block_offset, region);

        return regions;
    }

    TileBase get_placeholder_tile(TilemapBlock block, Vector3Int position){
        string tile_ID = block.map[position.x, position.y];
        TileBase tile = _MatSys._tile._get_tile(tile_ID);
        if (tile is Pseudo3DRuleTile P3DTile){
            TileBase placeholder = P3DTile.isTransparent ? _MatSys._tile._get_tile("p2") : _MatSys._tile._get_tile("p1");
            return placeholder;
        }
        return null;
    }

    public async UniTaskVoid _draw_regions(Tilemap tilemap, List<TilemapRegion4Draw> regions){
        Debug.LogError("DISCARD FUNCTION: _draw_regions");
        // System.Diagnostics.Stopwatch stopwatch = new System.Diagnostics.Stopwatch();
        // stopwatch.Start();

        // int draw_method = 1;
        
        // // ---------- Method 1: Draw tiles BY SetTiles ----------
        // if (draw_method == 1){
        //     List<Vector3Int> position_all = new();
        //     List<TileBase> tiles_all = new();
        //     foreach(TilemapRegion4Draw region in regions){
        //         position_all.AddRange(region.positions);
        //         tiles_all.AddRange(region.tiles);
        //     }
        //     Debug.Log(position_all.Count);
        //     int tile_per_group = _GCfg._sysCfg.TMap_tiles_per_loading;
        //     int group_count = Mathf.Max(position_all.Count / tile_per_group, 1);
        //     for(int i = 0; i < group_count; i++){
        //         Vector3Int[] tmp_positions = position_all.GetRange(i * tile_per_group, tile_per_group).ToArray();
        //         TileBase[] tmp_tiles = tiles_all.GetRange(i * tile_per_group, tile_per_group).ToArray();
        //         tilemap.SetTiles(tmp_positions, tmp_tiles);
        //         await UniTask.Delay(_GCfg._sysCfg.TMap_interval_per_loading);
        //     }
        // }

        // // ---------- Method 2: Draw tiles BY SetTiles ----------
        // else if (draw_method == 2){
        //     foreach(TilemapRegion4Draw region in regions){
        //         tilemap.SetTiles(region.positions, region.tiles);
        //         await UniTask.Delay(_GCfg._sysCfg.TMap_interval_per_loading);
        //     }
        // }

        // // ---------- Method 3: Draw tiles by SetTilesBlock ----------
        // else if (draw_method == 3){
        //     foreach(TilemapRegion4Draw region in regions){
        //         Vector3Int origin = region.positions[0];
        //         Vector3Int size = region.positions[^1] - origin + Vector3Int.one;
        //         BoundsInt bounds = new(origin.x, origin.y, 0, size.x, size.y, 1);
        //         tilemap.SetTilesBlock(bounds, region.tiles);
        //         await UniTask.Delay(_GCfg._sysCfg.TMap_interval_per_loading);
        //     }
        // }

        // stopwatch.Stop();
        // Debug.Log("Time loop: " + stopwatch.ElapsedMilliseconds + ", regions: " + regions.Count);
    }



    // public void _draw_region(Tilemap tilemap, List<TilemapRegion4Draw> regions){
    // public async UniTaskVoid _draw_region(Tilemap tilemap, List<TilemapRegion4Draw> regions, CancellationToken cancel_token){
    public async UniTaskVoid _draw_region(Tilemap tilemap, TilemapRegion4Draw region){
        // System.Diagnostics.Stopwatch stopwatch = new System.Diagnostics.Stopwatch();
        // stopwatch.Start();
        // ProfilerMarker profiler_marker = new ProfilerMarker("TilemapDrawMarker");
        // profiler_marker.Begin();

        int draw_method = 1;
        
        // ---------- Method 1: Draw tiles BY SetTiles ----------
        if (draw_method == 1){
            List<Vector3Int> position_all = new();
            List<TileBase> tiles_all = new();
            position_all.AddRange(region.positions);
            tiles_all.AddRange(region.tiles);
        
            int tile_per_group = Mathf.Min(_GCfg._sysCfg.TMap_tiles_per_loading, region.tiles.Count());
            for (int i = 0; i < region.tiles.Count(); i += tile_per_group) {
                // ArraySegment<Vector3Int> positions_segment = new(region.positions, i, tile_per_group);
                Vector3Int[] positions_segment = new ArraySegment<Vector3Int>(region.positions, i, tile_per_group).ToArray();
                TileBase[] tiles_segment = new ArraySegment<TileBase>(region.tiles, i, tile_per_group).ToArray();
                tilemap.SetTiles(positions_segment, tiles_segment);
                await UniTask.Delay(_GCfg._sysCfg.TMap_interval_per_loading);

            }

            // int tile_per_group = position_all.Count;
            // int tile_per_group = 32*32;
            // int tile_per_group = _GCfg._sysCfg.TMap_tiles_per_loading;
            // int group_count = Mathf.Max(position_all.Count / tile_per_group, 1);
            // for(int i = 0; i < group_count; i++){
            //     Vector3Int[] tmp_positions = position_all.GetRange(i * tile_per_group, tile_per_group).ToArray();
            //     TileBase[] tmp_tiles = tiles_all.GetRange(i * tile_per_group, tile_per_group).ToArray();
            //     tilemap.SetTiles(tmp_positions, tmp_tiles);
            //     // await UniTask.Yield();
            //     await UniTask.Delay(_GCfg._sysCfg.TMap_interval_per_loading);
            // }
        }

        // ---------- Method 2: Draw tiles BY SetTiles ----------
        else if (draw_method == 2){
            tilemap.SetTiles(region.positions, region.tiles);
            // await UniTask.Yield();
            // await UniTask.Delay(_GCfg._sysCfg.TMap_interval_per_loading);
        }

        // ---------- Method 3: Draw tiles by SetTilesBlock ----------
        else if (draw_method == 3){
            // foreach(TilemapRegion4Draw region in regions){
            Vector3Int origin = region.positions[0];
            Vector3Int size = region.positions[^1] - origin + Vector3Int.one;
            // Debug.Log(size);
            BoundsInt bounds = new(origin.x, origin.y, 0, size.x, size.y, 1);
            tilemap.SetTilesBlock(bounds, region.tiles);
            // await UniTask.Yield();
            // await UniTask.Delay(_GCfg._sysCfg.TMap_interval_per_loading);
            // }
        }
        // tilemap.GetComponent<ShadowGenerator>()._generate_shadow();

        // stopwatch.Stop();
        // Debug.Log("Time loop: " + stopwatch.ElapsedMilliseconds);
        // profiler_marker.End();
    }






    // // ---------- draw tilemap ----------

    // public void _draw_block(Tilemap tilemap, TilemapBlock block){
    //     // Get actual position of block origin
    //     Vector3Int block_origin_pos = new Vector3Int(block.offsets.x * block.size.x, block.offsets.y * block.size.y);
    //     TileBase[] tiles = new TileBase[block.size.x * block.size.y];
    //     // Loop for drawing
    //     for (int x = 0; x < block.size.x; x++){
    //         for (int y = 0; y < block.size.y; y++){
    //             // Get actual position of tile
    //             // Vector3Int tile_pos = new Vector3Int(block_origin_pos.x + x, block_origin_pos.y + y);
    //             int tile_ID = block.map[x, y];
    //             // Load tile 
    //             TileBase tile = tilemap_base._map_ID_to_tile(tile_ID);
    //             // tilemap.SetTile(tile_pos, tile);
    //             tiles[x + y * block.size.x] = tile;
    //         }
    //     }
    //     BoundsInt block_bounds = new (block_origin_pos, block.size);
    //     // System.Diagnostics.Stopwatch stopwatch = new System.Diagnostics.Stopwatch();
    //     // stopwatch.Start();
    //     // stopwatch.Stop();
    //     // Debug.Log("Time: " + stopwatch.ElapsedMilliseconds);
    //     // tilemap.SetTilesBlock(block_bounds, tiles);
    //     // StartCoroutine(draw_block(tilemap, block_bounds, tiles));
    // }
    
    // IEnumerator draw_block(Tilemap tilemap, BoundsInt block_bounds, TileBase[] tiles){
    //     tilemap.SetTilesBlock(block_bounds, tiles);
    //     yield return null;
    // }


    // public void _draw_tilemap_by_tile(Tilemap tilemap, Vector3Int tile_pos, int[,] map_info){
    //     Vector3Int block_offsets = tilemap_base._mapping_mapXY_to_blockXY(tile_pos);
    //     _draw_tilemap(tilemap, block_offsets, game_configs.__block_size__, map_info);
    // }

    // public void _draw_tilemap(Tilemap tilemap, Vector3Int block_offsets, int[,] map_info){
    //     _draw_tilemap(tilemap, block_offsets, game_configs.__block_size__, map_info);
    // }

    // public void _draw_tilemap(Tilemap tilemap, Vector3Int block_offsets, Vector3Int block_size, int[,] map_info){
    //     // Get actual position of block origin
    //     Vector3Int block_origin_pos = new Vector3Int(block_offsets.x * block_size.x, block_offsets.y * block_size.y);
    //     // Loop for drawing
    //     for (int x = 0; x < block_size.x; x++){
    //         for (int y = 0; y < block_size.y; y++){
    //             // Get actual position of tile
    //             Vector3Int tile_pos = new Vector3Int(block_origin_pos.x + x, block_origin_pos.y + y);
    //             int tile_ID = map_info[x, y];
    //             // Load tile 
    //             TileBase tile = tilemap_base._map_ID_to_tile(tile_ID);
    //             tilemap.SetTile(tile_pos, tile);
    //         }
    //     }
    // }
}
