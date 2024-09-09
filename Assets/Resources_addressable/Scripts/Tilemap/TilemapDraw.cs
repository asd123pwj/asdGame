using System.Collections.Generic;
using System.Collections;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;
using System.Linq;
using System.Threading;
using Unity.Profiling;


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
                    int tile_ID = block.map[x + g * block.size.x / group, y];
                    TileBase tile = _GCfg._MatSys._TMap._get_tile(tile_ID);
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



    public TilemapRegion4Draw _get_draw_region(Tilemap tilemap, TilemapBlock block){
        int group = 1;        
        // System.Diagnostics.Stopwatch stopwatch = new System.Diagnostics.Stopwatch();
        // stopwatch.Start();
        TilemapRegion4Draw region = new TilemapRegion4Draw(){
            tiles = new TileBase[block.size.x * block.size.y / group],
            positions = new Vector3Int[block.size.x * block.size.y / group]
        };
        // long[] times1 = new long[group];
        // long[] times2 = new long[group];
        // long[] times3 = new long[group];

        for (int g = 0; g < group; g++){ 
            System.Diagnostics.Stopwatch stopwatch = new System.Diagnostics.Stopwatch();
            stopwatch.Start();
            Vector3Int block_origin_pos = new Vector3Int(block.offsets.x * block.size.x + g * block.size.x / group, block.offsets.y * block.size.y);
            for (int x = 0; x < block.size.x / group; x++){
                for (int y = 0; y < block.size.y; y++){
                    int tile_ID = block.map[x + g * block.size.x / group, y];
                    TileBase tile = _GCfg._MatSys._TMap._get_tile(tile_ID);
                    // tiles[x + y * block.size.x / group] = tile;
                    region.tiles[x + y * block.size.x / group] = tile;
                    region.positions[x + y * block.size.x / group] = new Vector3Int(block_origin_pos.x + x, block_origin_pos.y + y, 0);
                    // tilemap.SetTile(region.positions[x + y * block.size.x / group], tile);
                }
            }
            // BoundsInt block_bounds = new (block_origin_pos, new (block.size.x/group, block.size.y, 1));
            // tilemap.SetTilesBlock(block_bounds, tiles);
            // stopwatch.Stop();
            // times1[g] = stopwatch.ElapsedMilliseconds;
            // Debug.Log("Time loop: " + stopwatch.ElapsedMilliseconds);

            // stopwatch.Start();
            // tilemap.SetTilesBlock(block_bounds, region.tiles);
            // stopwatch.Stop();
            // times2[g] = stopwatch.ElapsedMilliseconds;
            // string time2 = stopwatch.ElapsedMilliseconds.ToString();
            // Debug.Log("Time setTilesBlock: " + stopwatch.ElapsedMilliseconds);

            // stopwatch.Start();
            // tilemap.SetTiles(region.positions, region.tiles);
            // stopwatch.Stop();
            // times3[g] = stopwatch.ElapsedMilliseconds;
            // string time3 = stopwatch.ElapsedMilliseconds.ToString();
            // Debug.Log("Time setTiles: " + stopwatch.ElapsedMilliseconds);
        }
        return region;
    }

    // public void _draw_region(Tilemap tilemap, List<TilemapRegion4Draw> regions){
    // public async UniTaskVoid _draw_region(Tilemap tilemap, List<TilemapRegion4Draw> regions, CancellationToken cancel_token){
    public async UniTaskVoid _draw_region(Tilemap tilemap, List<TilemapRegion4Draw> regions){

        System.Diagnostics.Stopwatch stopwatch = new System.Diagnostics.Stopwatch();
        stopwatch.Start();
        // ProfilerMarker profiler_marker = new ProfilerMarker("TilemapDrawMarker");
        // profiler_marker.Begin();

        int draw_method = 1;
        
        // ---------- Method 1: Draw tiles BY SetTiles ----------
        if (draw_method == 1){
            List<Vector3Int> position_all = new();
            List<TileBase> tiles_all = new();
            foreach(TilemapRegion4Draw region in regions){
                position_all.AddRange(region.positions);
                tiles_all.AddRange(region.tiles);
            }

            // int tile_per_group = position_all.Count;
            // int tile_per_group = 32*32;
            int tile_per_group = _GCfg._sysCfg.TMap_tiles_per_loading;
            int group_count = position_all.Count / tile_per_group;
            for(int i = 0; i < group_count; i++){
                Vector3Int[] tmp_positions = position_all.GetRange(i * tile_per_group, tile_per_group).ToArray();
                TileBase[] tmp_tiles = tiles_all.GetRange(i * tile_per_group, tile_per_group).ToArray();
                tilemap.SetTiles(tmp_positions, tmp_tiles);
                // await UniTask.Yield();
                await UniTask.Delay(_GCfg._sysCfg.TMap_interval_per_loading);
            }
        }

        // ---------- Method 2: Draw tiles BY SetTiles ----------
        else if (draw_method == 2){
            foreach(TilemapRegion4Draw region in regions){
                tilemap.SetTiles(region.positions, region.tiles);
                // await UniTask.Yield();
                await UniTask.Delay(_GCfg._sysCfg.TMap_interval_per_loading);
            }
        }

        // ---------- Method 3: Draw tiles by SetTilesBlock ----------
        else if (draw_method == 3){
            foreach(TilemapRegion4Draw region in regions){
                Vector3Int origin = region.positions[0];
                Vector3Int size = region.positions[^1] - origin + Vector3Int.one;
                // Debug.Log(size);
                BoundsInt bounds = new(origin.x, origin.y, 0, size.x, size.y, 1);
                tilemap.SetTilesBlock(bounds, region.tiles);
                // await UniTask.Yield();
                await UniTask.Delay(_GCfg._sysCfg.TMap_interval_per_loading);
            }
        }

        stopwatch.Stop();
        Debug.Log("Time loop: " + stopwatch.ElapsedMilliseconds + ", regions: " + regions.Count);
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
